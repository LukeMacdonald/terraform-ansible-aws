#!/bin/bash
cd infra || exit
terraform init
terraform plan
terraform apply -auto-approve
