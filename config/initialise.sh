#!/bin/bash

TERRAFORM_BACKEND_DIR="infra/backend"
TERRAFORM_MAIN_DIR=".."

apply_terraform() {
    terraform init
    terraform plan
    terraform apply -auto-approve
}

# Check that Terraform is installed
if ! command -v terraform &> /dev/null
then
    echo "Error: Terraform not found"
    exit 1
fi

# Apply backend configuration
cd "$TERRAFORM_BACKEND_DIR" || exit

if terraform state show aws_s3_bucket.state_bucket &> /dev/null; then
  echo "State Bucket already exists. Skipping apply."
else
   apply_terraform
fi

# Apply main configuration
cd "$TERRAFORM_MAIN_DIR" || exit
apply_terraform
