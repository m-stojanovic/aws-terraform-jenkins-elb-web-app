#Get Linux AMI ID using SSM Parameter endpoint in us-east-1
#data "aws_ssm_parameter" "linuxAmiMaster" {
#  provider = aws.region-master
#  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
#}

#Get Linux AMI ID using SSM Parameter endpoint in us-west-2
#data "aws_ssm_parameter" "linuxAmiWorker" {
#  provider = aws.region-worker
#  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
#}

#resource "aws_iam_service_linked_role" "elasticloadbalancing" {
#  provider         = aws.region-master
#  aws_service_name = "elasticloadbalancing.amazonaws.com"
#
#}

data "aws_ami" "linuxAmiMaster" {
  provider    = aws.region-master
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
data "aws_ami" "linuxAmiWorker" {
  provider    = aws.region-worker
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "master_key" {
  provider   = aws.region-master
  key_name   = "master_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5IkRNJQtrROT8pjKJeoA8lF7wQ6wfIcj4xxE/nRc19xTebwOMlYfpfTRfSk65FjFkf0xLuDTpa8r/dA+tmkMkj3oCFR+UKCyTFyhxWbRvVzaRckk+ph8BcENNMHd8uAAukBnHlJiPwI1+BCaSNR1LhUGTRBiiTJMK8dxfBHnfGfSm3s7j8yVQbYcGk8GC8cYk5m6ZfF3UBeD0/P6mdx0eIKCGkfk2yWFHOK+BAJgwC0GNPChxHY07ywBk7+X7fIj3+ldyXIH+vtBkx6nWXJ1nw9zz1mFCa9QziybsglcOS//zKxmQ4lAVOcul4xpiY6fODHtXKS2RB1dm0ADKuDUb Octopus key"

}

#Create key-pair for logging into EC2 in us-west-2
resource "aws_key_pair" "worker_key" {
  provider   = aws.region-worker
  key_name   = "worker_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5IkRNJQtrROT8pjKJeoA8lF7wQ6wfIcj4xxE/nRc19xTebwOMlYfpfTRfSk65FjFkf0xLuDTpa8r/dA+tmkMkj3oCFR+UKCyTFyhxWbRvVzaRckk+ph8BcENNMHd8uAAukBnHlJiPwI1+BCaSNR1LhUGTRBiiTJMK8dxfBHnfGfSm3s7j8yVQbYcGk8GC8cYk5m6ZfF3UBeD0/P6mdx0eIKCGkfk2yWFHOK+BAJgwC0GNPChxHY07ywBk7+X7fIj3+ldyXIH+vtBkx6nWXJ1nw9zz1mFCa9QziybsglcOS//zKxmQ4lAVOcul4xpiY6fODHtXKS2RB1dm0ADKuDUb Octopus key"

}

#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "jenkins_master" {
  provider                    = aws.region-master
  ami                         = data.aws_ami.linuxAmiMaster.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.master_key.key_name
  subnet_id                   = aws_subnet.subnet_1.id
  vpc_security_group_ids      = [aws_security_group.jmaster_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "jenkins_master_tf"
  }
  depends_on = [aws_main_route_table_association.set_master_default_rt_assoc]

  provisioner "remote-exec" {
    inline = ["sleep 80"]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("./key/carnegie1.pem")
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' -u ec2-user -i '${self.public_ip}', --private-key ./key/master_key.pem ./ansible_templates/jenkins_master.yml"
    #  command = <<EOF
    #    aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-master} --instance-ids ${self.id}
    #    ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins_master.yml
    #    EOF
  }
}
#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "jenkins_worker" {
  provider                    = aws.region-worker
  count                       = var.workers_count
  ami                         = data.aws_ami.linuxAmiWorker.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.worker_key.key_name
  subnet_id                   = aws_subnet.subnet_1_worker.id
  vpc_security_group_ids      = [aws_security_group.jworker_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = join("_", ["jenkins_worker_tf", count.index + 1])
  }
  depends_on = [aws_main_route_table_association.set_worker_default_rt_assoc, aws_instance.jenkins_master]

  provisioner "remote-exec" {
    inline = ["sleep 80"]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      private_key = file("./key/carnegie1.pem")
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook --ssh-common-args='-o StrictHostKeyChecking=no' -u ec2-user -i '${self.public_ip}', --private-key ./key/worker_key.pem ./ansible_templates/jenkins_worker.yml"
    #command = <<EOF
    #  aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-worker} --instance-ids ${self.id}
    #  ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins_worker.yml
    #  EOF
  }
}
