#!/bin/bash

# Get the first argument
arg1=$1

TERRAFORM_BACKEND_DIR="backend"
TERRAFORM_MAIN_DIR="infra"

clear_backend(){
  echo "Destroying All Backend Resources and Files"
  terraform destroy -auto-approve
  rm -rf .terraform
  rm -f .terraform.lock.hcl
  rm -f terraform.tfstate
  rm -f terraform.tfstate.backup
}

cd "$TERRAFORM_MAIN_DIR" || exit
echo "Destroying All Application Resources"
terraform destroy -auto-approve
if [ "$arg1" = "-all" ]; then
  cd "$TERRAFORM_BACKEND_DIR" || exit
  clear_backend
fi