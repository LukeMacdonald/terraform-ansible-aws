#!/bin/bash

# Set the directories for the backend and main Terraform configurations
TERRAFORM_BACKEND_DIR="terraform/state-bucket"
TERRAFORM_MAIN_DIR=".."
ANSIBLE_DIR="../ansible"
INVENTORY_FILE="../ansible/inventory.yml"

# Define a function to apply Terraform
apply_terraform() {
  terraform init
  terraform fmt
  terraform plan -out=tfplan -detailed-exitcode
  PLAN_EXIT_CODE=$?
  if [ $PLAN_EXIT_CODE -eq 0 ]; then
    echo "No changes detected, skipping apply."
    exit
  elif [ $PLAN_EXIT_CODE -eq 1 ]; then
    echo "Error executing plan, please review logs."
  else
    echo "Changes detected, applying plan..."
    terraform apply "tfplan"
    rm tfplan
  fi
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

# Generate Ansible inventory file
db_ip=$(terraform output -raw db_ip)
app_instance1_ip=$(terraform output -raw app_instance1_ip)
app_instance2_ip=$(terraform output -raw app_instance2_ip)

cat << EOF > "$INVENTORY_FILE"
db_servers:
  hosts:
    db1:
      ansible_host: $db_ip
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
app_servers:
  hosts:
    app1:
      ansible_host: $app_instance1_ip
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    app2:
      ansible_host: $app_instance2_ip
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF

cd "$ANSIBLE_DIR" || exit
ansible-playbook db-playbook.yml -i inventory.yml --private-key ~/.ssh/github_sdo_key
ansible-playbook app-playbook.yml -i inventory.yml --private-key ~/.ssh/github_sdo_key
