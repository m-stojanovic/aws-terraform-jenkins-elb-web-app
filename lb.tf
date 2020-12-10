resource "aws_lb" "application_lb" {
  provider           = aws.region-master
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  tags = {
    Name = "jenkins_lb"
  }
}

resource "aws_lb_target_group" "app_lb_tg" {
  provider    = aws.region-master
  name        = "app-lb-tg"
  target_type = "instance"
  port        = var.webserver_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_master.id
  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = var.webserver_port
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "jenkins_target_group"
  }
}

#Create listener on tcp/80 HTTP
resource "aws_lb_listener" "jenkins_listener_http" {
  provider          = aws.region-master
  load_balancer_arn = aws_lb.application_lb.arn
  port              = var.webserver_port
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#Create new listener on tcp/443 HTTPS
#resource "aws_lb_listener" "jenkins-listener" {
#  provider          = aws.region-master
#  load_balancer_arn = aws_lb.application_lb.arn
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
#  port              = "443"
#  protocol          = "HTTPS"
#  certificate_arn   = aws_acm_certificate.jenkins-lb-https.arn
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.app_lb_tg.arn
#  }
#}

resource "aws_lb_target_group_attachment" "master_node_attachment" {
  provider         = aws.region-master
  target_id        = aws_instance.jenkins_master.id
  target_group_arn = aws_lb_target_group.app_lb_tg.arn
  port             = var.webserver_port
}
