# README

Example for terraform & ansible code to easily launch a nomad cluster.
I tested this with nomad-0.1.2.

## Summary
- AWS region is ap-southeast-1
- Build a VPC
- CentOS-7 (systemd)
- t2.micro x 5

## Quick start
Major required tools will be installed in `./bin` here.
```
$ make setup
$ source .env
$ terraform get
```

Configure `terraform.tfvars` including AWS access keys for terraform somehow.

Let's try next targets. You can see a page of elasticsearch-head if all successfully finishes.
```
$ make tf-plan tf-apply
$ make ping    # Wait for all hosts are ready
$ make yum nomad
```
