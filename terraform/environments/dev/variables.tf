variable "aws_region" {
  description = "AWS region where the infrastructure will be created"
  type        = string
}

variable "project_name" {
  description = "Name used for tagging and naming resources"
  type        = string
}

variable "key_name" {
  description = "Existing AWS key pair name used for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR format, for example 86.120.10.20/32"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
}

variable "k8s_instance_type" {
  description = "EC2 instance type for Kubernetes nodes"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB for each EC2 instance"
  type        = number
}
variable "github_token" {
  description = "GitHub personal access token used by Terraform to create the webhook"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub username or organization that owns the repository"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name without the owner"
  type        = string
}

variable "github_webhook_secret" {
  description = "Secret used to secure the GitHub webhook"
  type        = string
  sensitive   = true
  default     = ""
}