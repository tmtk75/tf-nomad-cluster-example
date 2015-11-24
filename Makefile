##
## Tasks
##
tf-plan: id_rsa.pub
	terraform plan

tf-apply: id_rsa.pub
	terraform apply

tf-refresh:
	terraform refresh

tf-destroy:
	terraform destroy

ping: hosts.ini
	ansible -i hosts.ini -m ping all

yum: hosts.ini roles/nomad
	ansible-playbook -i hosts.ini playbook.yml -t yum

nomad: hosts.ini roles/nomad host_vars
	ansible-playbook -i hosts.ini playbook.yml -t nomad,service

join:
	ssh -F ssh-config `terraform output node1` /usr/local/sbin/nomad server-join `terraform output node0.private_dns`
	ssh -F ssh-config `terraform output node2` /usr/local/sbin/nomad server-join `terraform output node0.private_dns`

nomad-stop:
	ansible -i hosts.ini all -m shell -a "sudo systemctl stop nomad"

nomad-rm-data:
	ansible -i hosts.ini all -m shell -a "sudo rm -rf /var/lib/nomad/*"

nomad-start:
	ansible -i hosts.ini all -m shell -a "sudo systemctl start nomad"


##
##
##
start-instances:
	aws ec2 --region ap-southeast-1 start-instances --instance-ids `terraform output node0.instance_id`
	aws ec2 --region ap-southeast-1 start-instances --instance-ids `terraform output node1.instance_id`
	aws ec2 --region ap-southeast-1 start-instances --instance-ids `terraform output node2.instance_id`
	aws ec2 --region ap-southeast-1 start-instances --instance-ids `terraform output node3.instance_id`
	aws ec2 --region ap-southeast-1 start-instances --instance-ids `terraform output node4.instance_id`

stop-instances:
	aws ec2 --region ap-southeast-1 stop-instances --instance-ids `terraform output node0.instance_id`
	aws ec2 --region ap-southeast-1 stop-instances --instance-ids `terraform output node1.instance_id`
	aws ec2 --region ap-southeast-1 stop-instances --instance-ids `terraform output node2.instance_id`
	aws ec2 --region ap-southeast-1 stop-instances --instance-ids `terraform output node3.instance_id`
	aws ec2 --region ap-southeast-1 stop-instances --instance-ids `terraform output node4.instance_id`

cleanall:
	rm -rf bin .e host_vars

##
## Generate files & dependencies
##
id_rsa id_rsa.pub:
	ssh-keygen -t rsa  -f id_rsa -N ""

hosts.ini: terraform.tfstate
	@echo "node0 ansible_ssh_host=`terraform output node0`"  > hosts.ini
	@echo "node1 ansible_ssh_host=`terraform output node1`" >> hosts.ini
	@echo "node2 ansible_ssh_host=`terraform output node2`" >> hosts.ini
	@echo "node3 ansible_ssh_host=`terraform output node3`" >> hosts.ini
	@echo "node4 ansible_ssh_host=`terraform output node4`" >> hosts.ini

host_vars: terraform.tfstate
	mkdir -p host_vars
	echo "localname: node0\nserver_enabled: true"  > host_vars/node0.yml
	echo "localname: node1\nserver_enabled: true"  > host_vars/node1.yml
	echo "localname: node2\nserver_enabled: true"  > host_vars/node2.yml
	./gen_vars.sh node3                           > host_vars/node3.yml
	./gen_vars.sh node4                           > host_vars/node4.yml

ssh: hosts.ini id_rsa
	ssh -F ssh-config `cat hosts.ini | peco | sed 's/^.*=//'`

roles/nomad:
	ansible-galaxy install -r requirements.yml --force

##
##
##
setup: jq peco ansible awscli
bin:
	mkdir -p bin

## jq
jq: bin/jq
bin/jq: bin 
	curl -o bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-osx-amd64
	chmod +x bin/jq

## peco
peco: bin/peco
bin/peco: bin
	(cd bin; \
	  curl -OL https://github.com/peco/peco/releases/download/v0.3.3/peco_darwin_amd64.zip; \
	  unzip -o peco_darwin_amd64.zip)
	ln -sf `pwd`/bin/peco_darwin_amd64/peco bin/peco

## ansible
ansible: .e/bin/ansible
.e/bin/ansible: .e/bin/pip2.7
	.e/bin/pip2.7 install ansible
.e/bin/pip2.7:
	virtualenv .e

## aws
awscli: .e/bin/aws
.e/bin/aws: .e/bin/pip2.7
	.e/bin/pip install awscli

