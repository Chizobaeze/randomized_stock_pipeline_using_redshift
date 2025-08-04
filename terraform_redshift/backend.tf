terraform {
  backend "s3" {
    bucket = "random-redshift-data"
    key    = "infrastructure/chiz-redshift.tfstate"
    region = "us-east-1"
  }
}