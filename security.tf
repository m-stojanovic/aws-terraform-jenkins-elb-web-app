#Create SG for LB, only TCP/80,TCP/443 and outbound access
resource "aws_security_group" "lb_sg" {
  provider    = aws.region-master
  vpc_id      = aws_vpc.vpc_master.id
  name        = "lb-sg"
  description = "Allow 443 & 80 traffic to Jenkins"
  ingress {
    description = "Allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create SG for allowing TCP/8080 from * and TCP/22 from your IP in us-east-1
resource "aws_security_group" "jmaster_sg" {
  provider    = aws.region-master
  vpc_id      = aws_vpc.vpc_master.id
  description = "Allow TCP/8080 & TCP/22"
  name        = "jmaster-sg"
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "Allow anyone on port 8080"
    from_port       = var.webserver_port
    to_port         = var.webserver_port
    protocol        = "TCP"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    description = "Allow traffic from us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create SG for allowing TCP/22 from your IP in us-west-2
resource "aws_security_group" "jworker_sg" {
  provider    = aws.region-worker
  vpc_id      = aws_vpc.vpc_worker.id
  description = "Allow TCP/8080 & TCP/22"
  name        = "jworker-sg"
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from us-east-1"
    from_port   = 0
    to_port     = 0
    protocol    = "TCP"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
