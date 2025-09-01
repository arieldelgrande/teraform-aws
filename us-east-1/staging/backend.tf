terraform {
  backend "s3" {
    bucket         = "spookyd-infra"      
    key            = "us-east-1/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "spookyd-infra-lock-table"        
  }
}