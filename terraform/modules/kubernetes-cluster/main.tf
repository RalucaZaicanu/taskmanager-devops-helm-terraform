resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update -y
    apt-get install -y curl

    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    curl -sfL https://get.k3s.io | K3S_TOKEN="${var.k3s_token}" sh -s - server --write-kubeconfig-mode 644
  EOF

  tags = {
    Name = "${var.project_name}-k8s-control-plane"
    Role = "k8s-control-plane"
  }
}

resource "aws_instance" "worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    apt-get update -y
    apt-get install -y curl netcat-openbsd

    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab

    until nc -z ${aws_instance.control_plane.private_ip} 6443; do
      echo "Waiting for k3s control plane..."
      sleep 10
    done

    curl -sfL https://get.k3s.io | K3S_URL="https://${aws_instance.control_plane.private_ip}:6443" K3S_TOKEN="${var.k3s_token}" sh -
  EOF

  depends_on = [aws_instance.control_plane]

  tags = {
    Name = "${var.project_name}-k8s-worker"
    Role = "k8s-worker"
  }
}