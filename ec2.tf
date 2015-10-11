/* */
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region"     { default = "ap-southeast-1" }
variable "vpc_subnet_zone_white" { default = "b" }
variable "cluster_name" { default = "dev-nomad-cluster" }
variable "cidr_home" {}

provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region     = "${var.aws_region}"
}

module "vpc" {
    source = "github.com/tmtk75/terraform-modules/aws/vpc"
    region = "${var.aws_region}"
    subnet_zone_white = "${var.vpc_subnet_zone_white}"
    vpc_name = "${var.cluster_name}"
}

module "ami-centos" {
    source = "github.com/tmtk75/terraform-modules/aws/ami"
    distribution        = "centos"
    version             = "7"
    region              = "${var.aws_region}"
    virtualization_type = "hvm"
}

resource "aws_key_pair" "ec2-key" {
    key_name   = "${var.cluster_name}"
    public_key = "${file("id_rsa.pub")}"
}

resource "aws_security_group" "node" {
    name        = "${var.cluster_name}-node"
    description = "${var.cluster_name}-node"
    vpc_id      = "${module.vpc.vpc_id}"
    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        self      = true
    }
    egress {
         from_port   = 0
         to_port     = 0
         protocol    = "-1"
         cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    ingress {
        from_port = 4646
        to_port   = 4648
        protocol  = "tcp"
        cidr_blocks = ["${var.cidr_home}"]
    }
    tags = {
        Name = "${var.cluster_name}"
    }
}

resource "aws_iam_role" "node" {
    name = "${var.cluster_name}-node"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "node" {
    name = "${var.cluster_name}-node"
    role = "${aws_iam_role.node.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*",
        "s3:Delete*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "node" {
    name = "${var.cluster_name}-node"
    roles = ["${aws_iam_role.node.name}"]
}

resource "aws_instance" "node" {
    ami                         = "${module.ami-centos.ami_id}"
    instance_type               = "t2.micro"
    key_name                    = "${aws_key_pair.ec2-key.key_name}"
    security_groups             = ["${aws_security_group.node.id}"]
    subnet_id                   = "${module.vpc.subnet_id_black}"
    iam_instance_profile        = "${aws_iam_instance_profile.node.id}"
    associate_public_ip_address = true
    disable_api_termination     = false
    count                       = 5

    root_block_device {
        volume_size = 20
    }
    ephemeral_block_device {
        device_name = "/dev/sdb"
        virtual_name = "ephemeral0"
    }
    tags {
        Name         = "${var.cluster_name}.${count.index}"
        cluster_name = "${var.cluster_name}"
    }
}

output aws_region        { value = "${var.aws_region}" }
output node0             { value = "${aws_instance.node.0.public_dns}" }
output node1             { value = "${aws_instance.node.1.public_dns}" }
output node2             { value = "${aws_instance.node.2.public_dns}" }
output node3             { value = "${aws_instance.node.3.public_dns}" }
output node4             { value = "${aws_instance.node.4.public_dns}" }
output node0.private_dns { value = "${aws_instance.node.0.private_dns}" }
output node1.private_dns { value = "${aws_instance.node.1.private_dns}" }
output node2.private_dns { value = "${aws_instance.node.2.private_dns}" }
output node3.private_dns { value = "${aws_instance.node.3.private_dns}" }
output node4.private_dns { value = "${aws_instance.node.4.private_dns}" }
output node0.private_ip  { value = "${aws_instance.node.0.private_ip}" }
output node1.private_ip  { value = "${aws_instance.node.1.private_ip}" }
output node2.private_ip  { value = "${aws_instance.node.2.private_ip}" }
output node3.private_ip  { value = "${aws_instance.node.3.private_ip}" }
output node4.private_ip  { value = "${aws_instance.node.4.private_ip}" }
output node0.instance_id  { value = "${aws_instance.node.0.id}" }
output node1.instance_id  { value = "${aws_instance.node.1.id}" }
output node2.instance_id  { value = "${aws_instance.node.2.id}" }
output node3.instance_id  { value = "${aws_instance.node.3.id}" }
output node4.instance_id  { value = "${aws_instance.node.4.id}" }
