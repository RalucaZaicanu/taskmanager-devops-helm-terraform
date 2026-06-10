output "jenkins_public_ip" {
  value = module.jenkins_server.public_ip
}

output "jenkins_url" {
  value = "http://${module.jenkins_server.public_ip}:8080"
}

output "jenkins_initial_password_command" {
  value = "ssh -i <your-key>.pem ubuntu@${module.jenkins_server.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

output "k8s_control_plane_public_ip" {
  value = module.kubernetes_cluster.control_plane_public_ip
}

output "k8s_control_plane_private_ip" {
  value = module.kubernetes_cluster.control_plane_private_ip
}

output "k8s_worker_public_ip" {
  value = module.kubernetes_cluster.worker_public_ip
}

output "ssh_jenkins_command" {
  value = "ssh -i <your-key>.pem ubuntu@${module.jenkins_server.public_ip}"
}

output "ssh_k8s_control_plane_command" {
  value = "ssh -i <your-key>.pem ubuntu@${module.kubernetes_cluster.control_plane_public_ip}"
}

output "copy_kubeconfig_command" {
  value = "ssh -i <your-key>.pem ubuntu@${module.kubernetes_cluster.control_plane_public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig.yaml"
}