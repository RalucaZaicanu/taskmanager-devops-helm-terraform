output "jenkins_sg_id" {
  value = aws_security_group.jenkins.id
}

output "k8s_sg_id" {
  value = aws_security_group.k8s.id
}