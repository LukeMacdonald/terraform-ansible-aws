

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

data "aws_s3_object" "public-key" {
  bucket = var.bucket_details["name"]
  key    = var.bucket_details["key"]
}

# Define a data source for finding the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create a Resource for creating a VPC
resource "aws_vpc" "vpc" {
  # Use the VPC CIDR block defined in the input variables
  cidr_block = var.vpc_cidr
  # Use default tenancy for instances launched in the VPC
  instance_tenancy = "default"
  tags = {
    # Set a name tag for the VPC
    Name = "vpc-s3888490"
  }
}


# Create Subnets for the VPC
resource "aws_subnet" "vpc-subnets" {
  # Create a subnet for each subnet defined in the input variables
  for_each = var.subnets
  # Use the ID of the VPC created above
  vpc_id = aws_vpc.vpc.id
  # Use the CIDR block defined for each subnet
  cidr_block = each.value.cidr
  tags = {
    # Set a name tag for each subnet
    Name = each.value.name
  }
  # Use the availability zone defined for each subnet
  availability_zone = each.value.az
  # Map a public IP address to instances launched in the subnet
  map_public_ip_on_launch = true
}

# Create a Resource for an Internet Gateway attached to the VPC
resource "aws_internet_gateway" "vpc-ig" {
  # Use the ID of the VPC created above
  vpc_id = aws_vpc.vpc.id
  tags = {
    # Set a name tag for the internet gateway
    Name = "vpc-ig-s3888490"
  }
}

# Create a Resource for applying a route between the VPC's main route table and the Internet Gateway
resource "aws_route" "vpc1-ig-route" {
  # Use the ID of the main route table in the VPC
  route_table_id = aws_vpc.vpc.main_route_table_id
  # Use the ID of the internet gateway created above
  gateway_id = aws_internet_gateway.vpc-ig.id
  # Route all traffic to the internet gateway
  destination_cidr_block = var.sg_rules["all-cidr"]
}



# Create a Resource for creating an SSH key pair
resource "aws_key_pair" "admin" {
  # Use "admin-key" as the name of the key pair
  key_name = "admin-key"
  # Use the path to the public key file defined in the input variables
  public_key = data.aws_s3_object.public-key.body
  #  public_key = file(var.path_to_ssh_public_key)
}

# Create a Resource for creating a security group for VMs
resource "aws_security_group" "sg" {
  count  = length(var.sg_names)
  name   = var.sg_names[count.index]
  vpc_id = aws_vpc.vpc.id

  # Allow inbound SSH traffic
  ingress {
    from_port   = var.ssh
    to_port     = var.ssh
    protocol    = var.sg_rules["protocol"]
    cidr_blocks = [var.sg_rules["all-cidr"]]
  }

  # Allow inbound HTTP traffic
  ingress {
    from_port   = var.http
    to_port     = var.http
    protocol    = var.sg_rules["protocol"]
    cidr_blocks = [var.sg_rules["all-cidr"]]
  }

  egress {
    from_port   = var.http
    to_port     = var.http
    protocol    = var.sg_rules["protocol"]
    cidr_blocks = [var.sg_rules["all-cidr"]]
  }

  # Allow outbound HTTPS traffic
  egress {
    from_port   = var.https
    to_port     = var.https
    protocol    = var.sg_rules["protocol"]
    cidr_blocks = [var.sg_rules["all-cidr"]]
  }
}

resource "aws_security_group_rule" "postgres_egress" {
  for_each          = var.sg_rule_types
  type              = each.value
  from_port         = var.postgres
  to_port           = var.postgres
  protocol          = var.sg_rules["protocol"]
  cidr_blocks       = ["${aws_instance.a2-db.public_ip}/32", "${aws_instance.a2-application[0].public_ip}/32", "${aws_instance.a2-application[1].public_ip}/32"]
  security_group_id = aws_security_group.sg[0].id
}

# Create EC2 instances for the A2 application
resource "aws_instance" "a2-application" {

  # Use the latest Ubuntu AMI
  ami = data.aws_ami.ubuntu.id
  # Use the t2.micro instance type
  instance_type = "t2.micro"

  count = length(var.instance_names) - 1

  # Use the "subnet1" subnet for the instance
  subnet_id = aws_subnet.vpc-subnets["subnet${count.index + 1}"].id
  # Use the "admin" key pair for SSH access
  key_name = aws_key_pair.admin.key_name
  # Use the "vms" security group
  vpc_security_group_ids = [aws_security_group.sg[0].id]

  tags = {
    # Set a name tag for the instance
    Name = var.instance_names[count.index]
  }

}

# Create EC2 instances for the A2 application
resource "aws_instance" "a2-db" {

  # Use the latest Ubuntu AMI
  ami = data.aws_ami.ubuntu.id
  # Use the t2.micro instance type
  instance_type = "t2.micro"

  # Use the "subnet1" subnet for the instance
  subnet_id = aws_subnet.vpc-subnets["subnet1"].id
  # Use the "admin" key pair for SSH access
  key_name = aws_key_pair.admin.key_name
  # Use the "vms" security group
  vpc_security_group_ids = [aws_security_group.sg[0].id]

  tags = {
    # Set a name tag for the instance
    Name = var.instance_names[2]
  }

}



# Create an Application Load Balancer for the A2 application
resource "aws_lb" "application_lb" {
  # Set a name for the ALB
  name = "alb-s3888490"
  # Use the application load balancer type
  load_balancer_type = "application"
  # Use all subnets in the VPC
  subnets = [for subnet in aws_subnet.vpc-subnets : subnet.id]
  # Use the "vms" security group
  security_groups = [aws_security_group.sg[1].id]

  # Disable deletion protection for the ALB
  enable_deletion_protection = false
}


# Create a target group for the ALB
resource "aws_lb_target_group" "alb_target" {
  # Set a name for the target group
  name = "alb-tg-s3888490"
  # Use port 80
  port = var.http
  # Use HTTP protocol
  protocol = "HTTP"
  # Use the VPC ID
  vpc_id = aws_vpc.vpc.id
}

# Attach EC2 instances to the target group
resource "aws_lb_target_group_attachment" "alb_tg_attachment" {
  # Attach two instances to the target group
  count            = length(var.instance_names) - 1
  target_group_arn = aws_lb_target_group.alb_target.arn
  # Attach the "app" instance to the target group
  target_id = aws_instance.a2-application.*.id[count.index]
  # Use port 80
  port = var.http

}

# Create a listener for the ALB
resource "aws_lb_listener" "front_end" {
  # Use the ARN of the ALB
  load_balancer_arn = aws_lb.application_lb.arn
  # Use port 80
  port = var.http
  # Use HTTP protocol
  protocol = "HTTP"
  default_action {
    # Use the target group ARN for forwarding
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}