# nubis-consul release 10

variable "ami" {
}

variable "aws_access_key" {
}

variable "aws_secret_key" {
}

variable "aws_account_id" {
}

variable "key_name" {
  description = "SSH key name in your AWS account for AWS instances."
}

variable "region" {
  default     = "us-east-1"
  description = "The region of AWS, for AMI lookups."
}

variable "consul_secret" {
  description = "Security shared secret for consul membership (consul keygen)"
}

variable "servers" {
  default     = "3"
  description = "The number of Consul servers to launch"
}

variable "release" {
  default     = "0"
  description = "Release number of this architecture"
}

variable "build" {
  default     = "35"
  description = "Build number of this architecture"
}

variable "project" {
  default = "consul"
}

variable "environment" {
  default = "sandbox"
}

variable "zone_id" {
  description = "Route53 Zone ID"
}

variable "domain" {
  description = "Top-level nubis domain for this environment"
  default     = "nubis.allizom.org"
}

variable "service_name" {
  description = "Service this is deployed for (i.e. dpaste)"
}

variable "vpc_id" {
  description = "ID of the VPC to launch into"
}

variable "ssl_cert" {
  description = "SSL Certificate file"
}

variable "ssl_key" {
  description = "SSL Key file"
}

variable "internet_security_group_id" {
  description = "ID of that SG"
}

variable "shared_services_security_group_id" {
  description = "ID of that SG"
}

variable "master_acl_token" {
  description = "Master ACL Token (use uuidgen)"
}

variable "acl_down_policy" {
  description = "Policy for when ACL master is down"
  default     = "extend-cache"
}

variable "acl_default_policy" {
  description = "Default ACL action for anonymous users"
  default     = "allow"
}

variable "public_subnets" {
  description = "Public Subnets IDs, comma-separated"
}

variable "private_subnets" {
  description = "Private Subnets IDs, comma-separated"
}

variable "allowed_public_cidrs" {
  description = "Comma separated list of CIDRs with public access"
  default     = "127.0.0.1/32"
}

variable "credstash_key" {
  description = "KMS Key ID used for Credstash (aaaabbbb-cccc-dddd-1111-222233334444)"
}
