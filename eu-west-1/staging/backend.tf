terraform {
  backend "s3" {
    bucket         = "spookyd-infra"      # <-- replace with your S3 bucket name
    key            = "eu-west-1/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "spookyd-infra-lock-table"        # <-- replace with your DynamoDB table name
  }
}