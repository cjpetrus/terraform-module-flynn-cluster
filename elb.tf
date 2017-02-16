resource "aws_elb" "service" {
  name  = "${var.app_conf["name"]}-${replace(var.aws_conf["domain"], ".", "-")}-elb"
  subnets = ["${split(",", var.vpc_conf["subnets_public"])}"]

  security_groups = [
    "${aws_security_group.elb-sg.id}",
    "${var.vpc_conf["security_group"]}"
  ]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = 80
    instance_protocol = "http"
  }

  listener {
    lb_port = 443
    lb_protocol = "https"
    ssl_certificate_id = "${var.app_conf["ssl_arn"]}"
    instance_port = 443
    instance_protocol = "https"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    target              = "TCP:80"
    interval            = 60
  }

  connection_draining = false
  cross_zone_load_balancing = true
  internal = false

  tags {
    Name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-elb"
    Stack = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb-sg" {
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-elb"
  description = "ELB Incoming traffic"

  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-elb"
    Stack = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}
