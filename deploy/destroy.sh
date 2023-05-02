#!/bin/bash

# Get the first argument
arg1=$1

# Set the directories for the backend and main Terraform configurations
TERRAFORM_BACKEND_DIR="state-bucket"
TERRAFORM_MAIN_DIR="terraform"

# Define a function to clear the backend resources
clear_backend(){
  echo "Destroying All Backend Resources and Files"
  terraform destroy -auto-approve
  rm -rf .terraform
  rm -f .terraform.lock.hcl
  rm -f terraform.tfstate
  rm -f terraform.tfstate.backup
}

# Change to the main directory and destroy all application resources
cd "$TERRAFORM_MAIN_DIR" || exit
echo "Destroying All Application Resources"
terraform init
terraform destroy -auto-approve

# If the "-all" flag is passed as an argument, also clear the backend resources
if [ "$arg1" = "-all" ]; then
  cd "$TERRAFORM_BACKEND_DIR" || exit
  clear_backend
fi