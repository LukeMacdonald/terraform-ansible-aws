#!/bin/bash

# Set the directories for the backend and main Terraform configurations
TERRAFORM_BACKEND_DIR="terraform/state-bucket"
TERRAFORM_MAIN_DIR=".."

# Define a function to apply Terraform
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

# Check if the state bucket already exists
if terraform state show aws_s3_bucket.state_bucket &> /dev/null; then
  echo "State Bucket already exists. Skipping apply."
else
   apply_terraform
fi

# Apply main configuration
cd "$TERRAFORM_MAIN_DIR" || exit
apply_terraform
terraform output -json > ../config/output/data.json