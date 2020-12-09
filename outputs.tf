output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}
output "jenkins_worker_public_ip" {
  value = {
    for instance in aws_instance.jenkins_worker :
    instance.id => instance.public_ip
  }
}
output "jenkins_alb_dns" {
  value = aws_lb.application_lb.dns_name
}
output "url" {
  value = aws_route53_record.jenkins.fqdn
}
