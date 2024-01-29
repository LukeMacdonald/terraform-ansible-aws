<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url] [![MIT License][license-shield]][license-url] [![LinkedIn][linkedin-shield]][linkedin-url] <!-- PROJECT LOGO --> <br /> <div align="center"> <a href="https://github.com/LukeMacdonald/terraform-ansible-aws"> <img src="logo.png" alt="Logo" width="180" height="80"> </a> <h3 align="center">Deploying AWS Infrastructure with Terraform and Ansible</h3> <p align="center"> <br />
<a href="https://github.com/LukeMacdonald/terraform-ansible-aws"><strong>Explore the docs »</strong></a>
<br />
<br />

  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#built-with">Built With</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#cd-pipeline-diagram">CD Pipeline Diagram</a></li>
    <li><a href="#deploying-infrastructure-(terraform)">Deploying Infrastructure (Terraform)</a></li>
    <li><a href="#configuring-infrastructure-(ansible)">Configuring Infrastructure (Ansible)</a></li>
    <li><a href="#shell-script">Shell Script</a></li>
    <li><a href="#github-actions-pipeline">GitHub Actions Pipeline</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

### Built With

<div style="column-count: 2; -webkit-column-count: 2 -moz-column-count: 2;">

- [![AWS][AWS-badge]][AWS-url]
- [![Terraform][Terraform-badge]][Terraform-url]
- [![Ansible][Ansible-badge]][Ansible-url]
- [![Docker][Docker-badge]][Docker-url]
- [![GitHubActions][GitHubActions-badge]][GitHubActions-url]

</div>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## CD Pipeline Diagram

```mermaid
flowchart TB
    A --> B
    A[Deploy Infrastructure Using Terraform]
    B[Configure Infrastructure Using Ansible]

```

## Deploying Infrastructure (Terraform)

<img src="aws-infrastructure.png" alt="AWS Infrastructure Diagram">

### Backend S3 Bucket

The state file for the AWS resources created by terraform is stored in a S3 bucket. Before any terraform commands are run.

- The pipeline script (only the shell script) will first check that the bucket that the state is stored in exists
  and if it does not already exist then a terraform apply is used to deploy the S3 bucket used to store the state file.
- An S3 bucket is used to store the state file of the resources as permissions to access the bucket can be restricted,
  thereby increasing the security of the infrastructure as no unauthorised modifications/access can be made

### Virtual Private Cloud:

The VPC deployed by terraform is created in the us-east-1 region.

- An internet gateway is deployed along with the VPC to allow public subnets access to the internet.

### Application Load Balancer

An application load balancer (ALB) is used to balance the network traffic (listens on port 80) for an application across
multiple instances.

- This ALB maps the application traffic two either one of two of the available application instances both of which are
  created on separate subnets which have separate CIDR blocks in different availability zones.
- Having the two application instances running in different subnets on different availability zone increases the fault
  tolerance of the application. For example if one availability zone is down, then traffic can be redirected to the
  other application instance running in a different availability zone.

### Security Groups:

<img src="instance.png">

There are three different security groups deployed by terraform.

- The first security group is attached to all the ec2 instances running and this security groups have an inbound rule for
  SSH (port 22), HTTP (port 80) and Postgres (port 5432) and outbound rules for HTTP, HTTPS (port 443) and Postgres.
- The ingress rules for postgres only allow the public IP addresses of the ec2 instances created as its source, and
  for egress rules only allows these IPs as the destination. As traffic only needs to be transferred between the
  application instances and database instances, this allows requests to be made to the database instance and data to
  be received from the database instance aswell as allowing the database instance to accept the request and send the
  data to the application instances.
- The second security group is attached to the application load balancer. Because the ALB does not need to allow
  traffic for the postgres port, the inbound rules for this security group includes for SSH and HTTP and the outbound
  rules are for HTTP and HTTPS

Both the application and database instances needed to allow port 80 for its inbound rule to allow ansible to install
all dependencies needed on the ec2 instance. Without it ansible would fail.<br><br>
To allow Security Groups to contain rules that apply to just the public IP addresses of instances also deployed by
Terraform, a Security Group Rule resource is used to allow this, as this will wait for the specified instance to be
created and then apply the rule to the security group.

### EC2 Instances

A total of three EC2 instances are deployed using terraform.

- Two instances are for running the application docker container (these are named, app1-s3888490 and app2-s3888490)
- The other instance is for running the database (postgres) container (this instance is named db-s3888490)

The keypair used for all these instances is deployed using a public key that is stored in an S3 bucket.

- The public key is stored in an S3 bucket to ensure that no unauthorised modifications can be made to the public key.

## Configuring Infrastructure (Ansible)

### Inventory file:

An issue faced when trying to create the ansible playbooks was how to dynamically store the public IP addresses used by
the EC2 instances deployed by Terraform.

- The solution to this issue involved creating a dynamic inventory file, where either GitHub actions or a shell
  script is used to create a new inventory file each time terraform apply is run. Stored within the inventory file
  are the public IP addresses of all the EC2 instances which were outputs for the terraform apply command.

The inventory file creates two groups.

1. db_servers (contains a single host which is the db EC2 instance deployed by terraform)
2. app_servers (containers two hosts which are the app EC2 instances deployed by terraform)

Each host in the inventory file contains '-o StrictHostKeyChecking=no' for the ‘ansible_ssh_common_args’ variable.

- This is used to allow hosts to automatically be added to the VM the playbook is running on without the need for
  user input.

### DB Playbook:

```mermaid
flowchart TB
        A --> B
        B --> C
        C --> D
        D --> E
        E -- Doesnt Exist --> F
        E -- Exists --> G
        F --> G
        G --> H

    A[Install Require Packages/Dependencies]
    B[Add Docker GPG apt Key]
    C[Add Docker Repository]
    D[Add user to docker group]
    E[Checks Temp Directory Exists]
    F[Create Temp Directory]
    G[Copy Postgres Initialization Script]
    H[Create & run database container]

```

The host for this playbook is found from the db_servers in the inventory file created.

- The first thing is playbook will do is install all dependencies/packages that are required for this database instance to be configured correctly.
  - This includes packages and other configurations that allow docker to run on the host machine.
- An issue faced when trying to diagnose why docker was not running the container correctly was that the ansible user did not have permissions to access docker. Therefore after installing all the dependences into the host machine, the ansible user was added to a docker group to give permissions to run docker commands (for example docker ps)
- Next the playbook checks that the directory that the database init script is going to be stored in exists.
  - If it does not exist than the directory is created.
- After ensuring that the directory exists than the Postgres init script is copied from the host machine to the db machine.
- After copying the init script for the database, the docker container for postgres is than created and run on the db machine on port 5342.
  - The container's port 5342 is being published on the host machine's IP address 0.0.0.0 (which means all available network interfaces) on port 5432 therefore any traffic directed to port 5342 on the host machine will be forwarded to port 5342 of the container.
  - The init script stored on the db machine is also transferred to the container, which will initialise all the data onto the database.

### App Playbook

```mermaid
flowchart TB
        A --> B
        B --> C
        C --> D
        D --> E
        E --> F


    A[Install Require Packages/Dependencies]
    B[Add Docker GPG apt Key]
    C[Add Docker Repository]
    D[update apt and install docker-ces]
    E[Add user to docker group]
    F[Create & run database container]

```

This playbook is run after the db-playbook and is run on all the app_servers hosts found in the inventory file.

- Exactly like the db-playbook the first thing is playbook will do is install all dependencies/packages that are required for this application instances to be configured correctly.
- The ansible user is also added to the docker group for the same reasons as stated for the db-playbook.
- The docker container for the application to be run is then created and configured to be run on port 3001
- The container's port 3001 is being published on the host machine's IP address 0.0.0.0 on port 80 therefore any traffic directed to port 80 on the host machine will be forwarded to port 3001 of the container.

## Shell Script

```mermaid
flowchart TB
    subgraph deploy["Deploy"]

        A -- Yes --> B
        A -- No --> C
        C --> B
        B --> D
        D --> E
        E -- Changes Made --> G
    end
    subgraph configure["Configure"]
        G --> H
        E -- No Changes Made --> F
        H --> F
        F --> I
    end
    A[Checks S3 backend exists]
    B[Run Terraform init]
    C[Creates S3 bucket terraform backend]
    D[Run Terraform fmt]
    E[Run Terraform plan]
    F[Run Ansible Db Playbook]
    G[Run Terraform apply]
    H[Create Ansible Inventory]
    I[Run Ansible App Playbook]
    style deploy color:#f66

```

1. Checks Backend S3 Bucket Exists (if not then the S3 Backend Bucket is Deployed using Terraform)
2. Runs Terraform init
3. Runs Terraform fmt (Corrects the formatting of Terraform code)
4. Runs Terraform plan (Check for any changes made to infrastructure)
   - If exit code is 0, then terraform apply is skipped, if exit code is 1 then an error occured, otherwise terraform apply is run
5. If terraform plan determines that changes were made to infrastructure, terraform apply is run and the public IPs for the app1, app2 and db instances are outputted.
6. The outputed IPs addresses are then used to create the inventory file used by ansible.
7. The db-playbook is executed (See above for details of db playbook)
8. The app-playbook is executed (See above for details of app playbook)

## GitHub Actions Pipeline

```mermaid
flowchart TB
    subgraph deploy["Deploy"]
        B --> D
        D --Format Correct--> E

        E -- Changes Made --> G
    end
    subgraph configure["Configure"]
        G --Succeeded --> H
        H --Succeeded --> F
        F --Succeeded -->I
    end
    B -- Failed --> A
    D --Format Incorrect--> A
    E -- No Changes Made --> C
    G --Failed-->A
    H -- Failed-->A
    F -- Failed --> A
    I -- Failed --> A
    I --Succeeded --> C

    B[Run Terraform init]
    A[Exit With Failure]
    C[Exit With Success]
    D[Run Terraform fmt]
    E[Run Terraform plan]
    F[Run Ansible Db Playbook]
    G[Run Terraform apply]
    H[Create Ansible Inventory]
    I[Run Ansible App Playbook]
    style deploy color:#f66

```

1. Runs Terraform init
2. Runs Terraform fmt (Workflow fails if Terraform formatting is incorrect)
3. Runs Terraform plan (Check for any changes made to infrastructure)
   - If exit code is 0, then the remainder of the workflow is skipped, if exit code is 1 then an error occured.
4. If terraform plan determines that changes were made to infrastructure, terraform apply is run and the public IPs for
   the app1, app2 and db instances are outputted and stored in environment variables.
5. The outputed IPs addresses are then used to create the inventory file used by ansible.
6. The private key used to execute ansible playbooks is created from secret repostority environemtn variable
   (i.e. secrets.PRIVATE_KEY)
7. The db-playbook is executed (See above for details of db playbook)
8. The app-playbook is executed (See above for details of app playbook)

### How is the workflow triggered?

The are two main ways that the workflow can be triggered:

1. A push or post request is made on the main branch of the GitHub Repository. This is the main way that a workflow can
   be triggered and it will only be triggered on the main branch and no other branch.
2. A REST API request. A REST API request can be used to trigger the workflow, however the API Request must
   include an authorisation token (i.e. A GitHub Personal Access Token) inorder for the workflow to be triggered. Using a PAT for authentication ensures that only authorised users can trigger workflows.

#### Command To Trigger Workflow using REST API

curl -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: Bearer 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" -d '{"ref":"main"}' https://api.github.com/repos/LukeMacdonald/terraform-ansible-aws/actions/workflows/pipeline.yml/dispatches

### Updating AWS Credentials for GitHub Actions Workflow

The AWS Credentials needed for AWS is stored in the GitHub as repository secrets. This ensures that only authoirsed users
can edit credentials and that no the credentials are not stored in a place that any unauthorised user could see.<br><br>
Steps to Update AWS Credentials

1. Navigate to the page in the repository that allows editing repository secrets. (Select Settings for Repository -> Select Secrets & Variables -> Select Actions)
2. Update each secret variable with the new values (The variables that need to be updated are, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN)

### What if the Workflow is triggered but no changes to infrastructure are made?

If no changes are made to the infrastructure then this will be detected when terraform plan is run, if no changes are made
then the terraform plan will have the exit code 0.

- It is this value that is used to determine whether all the other steps and jobs are run. This is because if no changes
  were detected by terraform plan, than there is no use in running terraform apply, or execute the ansible playbooks as
  there will be no impact.

The use of terraform plan means that the workflow can be triggered as many times as possible, but if no changes were actually
made to the infrastructure when the workflow was triggered then no changes will be applied by the workflow.

## Contact

Luke Macdonald - lukemacdonald21@gmail.com.com

Project Link: [https://github.com/LukeMacdonald/terraform-ansible-aws ](https://github.com/LukeMacdonald/terraform-ansible-aws)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/LukeMacdonald/terraform-ansible-aws.svg?style=for-the-badge
[contributors-url]: https://github.com/LukeMacdonald/terraform-ansible-aws/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/LukeMacdonald/terraform-ansible-aws.svg?style=for-the-badge
[forks-url]: https://github.com/LukeMacdonald/terraform-ansible-aws/network/members
[stars-shield]: https://img.shields.io/github/stars/LukeMacdonald/terraform-ansible-aws.svg?style=for-the-badge
[stars-url]: https://github.com/LukeMacdonald/terraform-ansible-aws/stargazers
[issues-shield]: https://img.shields.io/github/issues/LukeMacdonald/terraform-ansible-aws.svg?style=for-the-badge
[issues-url]: https://github.com/LukeMacdonald/terraform-ansible-aws/issues
[license-shield]: https://img.shields.io/github/license/LukeMacdonald/terraform-ansible-aws.svg?style=for-the-badge
[license-url]: https://github.com/LukeMacdonald/terraform-ansible-aws/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/luke-macdonald-292a4a208
[product-screenshot]: images/screenshot.png
[GitHubActions-badge]: https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white
[GithubActions-url]: https://github.com/features/actions
[AWS-badge]: https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white
[AWS-url]: https://aws.amazon.com/
[Ansible-badge]: https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white
[Ansible-url]: https://www.ansible.com/
[Docker-badge]: https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white
[Docker-url]: https://www.docker.com/
[Terraform-badge]: https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white
[Terraform-url]: https://www.terraform.io/
