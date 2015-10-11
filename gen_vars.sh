#!/usr/bin/env bash
cat<<EOF
localname: $1
servers:
- `terraform output node0.private_ip`:4647
- `terraform output node1.private_ip`:4647
- `terraform output node2.private_ip`:4647
EOF
