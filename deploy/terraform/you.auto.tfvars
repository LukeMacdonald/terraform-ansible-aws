# Value of Region that Resources are created in
region   = "us-east-1"

# Values Relating to VPC and its Subnets
vpc_cidr = "10.1.0.0/16"
subnets = {
  subnet1 = {
    "name" : "s3888490-us-east-1a"
    "cidr" : "10.1.1.0/24"
    "az" : "us-east-1a"
  },
  subnet2 = {
    "name" : "s3888490-us-east-1b"
    "cidr" : "10.1.2.0/24"
    "az" : "us-east-1b"
  }
}

# Values Relating to EC2 Instances
instance_names = ["app1-s3888490", "app2-s3888490", "db-s3888490"]

# Values Relating to S3 Bucket
bucket_details = {
  name = "s3888490-a2-backend"
  key  = "config/public_key.txt"
}

# Values Relating to Security Groups
sg_names      = ["ec2-sg-s3888490", "alb-sg-s3888490"]
sg_rule_types = ["egress", "ingress"]
sg_rules = {
  "protocol" : "tcp"
  "all-cidr" : "0.0.0.0/0"
}

# All Port Number Values Used
http     = 80
https    = 443
postgres = 5432
ssh      = 22


