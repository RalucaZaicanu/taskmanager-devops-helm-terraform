data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
}

module "security_groups" {
  source = "../../modules/security-groups"

  project_name     = var.project_name
  vpc_id           = module.networking.vpc_id
  vpc_cidr         = var.vpc_cidr
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "jenkins_server" {
  source = "../../modules/jenkins-server"

  project_name      = var.project_name
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.jenkins_instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.security_groups.jenkins_sg_id
  key_name          = var.key_name
  root_volume_size  = var.root_volume_size
}

module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"

  project_name      = var.project_name
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.k8s_instance_type
  subnet_id         = module.networking.public_subnet_id
  security_group_id = module.security_groups.k8s_sg_id
  key_name          = var.key_name
  k3s_token         = random_password.k3s_token.result
  root_volume_size  = var.root_volume_size
}
resource "github_repository_webhook" "jenkins_webhook" {
  repository = var.github_repository

  configuration {
    url          = "http://${module.jenkins_server.public_ip}:8080/github-webhook/"
    content_type = "json"
    insecure_ssl = false
    secret       = var.github_webhook_secret
  }

  active = true

  events = ["push"]

  depends_on = [
    module.jenkins_server
  ]
}