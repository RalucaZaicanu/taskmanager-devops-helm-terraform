resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-jenkins-sg"
  }
}

resource "aws_security_group_rule" "jenkins_ssh" {
  type              = "ingress"
  description       = "Allow SSH to Jenkins only from my IP"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  security_group_id = aws_security_group.jenkins.id
}

resource "aws_security_group_rule" "jenkins_ui" {
  type              = "ingress"
  description       = "Allow Jenkins UI and GitHub webhook"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins.id
}

resource "aws_security_group_rule" "jenkins_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic from Jenkins"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins.id
}

resource "aws_security_group" "k8s" {
  name        = "${var.project_name}-k8s-sg"
  description = "Security group for Kubernetes nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-k8s-sg"
  }
}

resource "aws_security_group_rule" "k8s_ssh" {
  type              = "ingress"
  description       = "Allow SSH to Kubernetes nodes only from my IP"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  security_group_id = aws_security_group.k8s.id
}

resource "aws_security_group_rule" "k8s_http" {
  type              = "ingress"
  description       = "Allow HTTP access to application"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s.id
}

resource "aws_security_group_rule" "k8s_https" {
  type              = "ingress"
  description       = "Allow HTTPS access to application"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s.id
}

resource "aws_security_group_rule" "k8s_api_from_my_ip" {
  type              = "ingress"
  description       = "Allow Kubernetes API from my IP"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_cidr]
  security_group_id = aws_security_group.k8s.id
}

resource "aws_security_group_rule" "k8s_api_from_jenkins" {
  type                     = "ingress"
  description              = "Allow Jenkins to access Kubernetes API"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins.id
  security_group_id        = aws_security_group.k8s.id
}

resource "aws_security_group_rule" "k8s_internal" {
  type              = "ingress"
  description       = "Allow all internal traffic between Kubernetes nodes"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.k8s.id
}

resource "aws_security_group_rule" "k8s_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic from Kubernetes nodes"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s.id
}