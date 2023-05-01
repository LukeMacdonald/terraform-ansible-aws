terraform {
  backend "local" {}
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = "s3888490-a2-backend"
  acl    = "private"
}
resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket= aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "state_bucket_lock" {
  name           = "s3888490-a2-backend-db"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
