terraform {
    backend "s3" {
        bucket         = "devsecops-security-ops-tfstate-bucket"
        key            = "dev/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "terraform-lock"
        encrypt        = true
    }
}