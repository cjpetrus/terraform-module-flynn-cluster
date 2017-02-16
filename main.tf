variable "aws_conf" { type = "map" }
variable "vpc_conf" { type = "map" }
variable "app_conf" { type = "map" }

data "template_file" "node-cloudinit" {
  template = "${file("${path.module}/cloudinit.yml")}"

  vars {
    flynn_domain = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
    discovery_token = "${var.app_conf["discovery_token"]}"
    flynn_nodes = "${var.app_conf["cluster_nodes"]}"
    dns_zone_id = "${var.vpc_conf["zone_id"]}"
  }
}

resource "random_shuffle" "master_az" {
  input = ["${split(",", var.vpc_conf["subnets_public"])}"]
  result_count = 1
  keepers = {
    ami = "${var.vpc_conf["ami"]}"
  }
}

resource "aws_launch_configuration" "node" {
  name_prefix = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-node-"
  image_id = "${var.vpc_conf["ami"]}"
  instance_type = "${var.aws_conf["instance_type"]}"
  key_name = "${var.aws_conf["key_name"]}"
  iam_instance_profile = "${var.vpc_conf["profile"]}"
  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.node.id}"
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 80
    delete_on_termination = true
  }
  user_data = "${data.template_file.node-cloudinit.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node" {
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  launch_configuration = "${aws_launch_configuration.node.name}"
  vpc_zone_identifier = ["${split(",", var.vpc_conf["subnets_public"])}"]
  min_size = 3
  max_size = "${var.app_conf["cluster_nodes"] * 3}"
  desired_capacity = "${var.app_conf["cluster_nodes"]}"
  wait_for_capacity_timeout = 0
  load_balancers = ["${aws_elb.service.id}"]

  tag {
    key = "Name"
    value = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-node"
    propagate_at_launch = true
  }
  tag {
    key = "Stack"
    value = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "node" {
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-node"
  autoscaling_group_name = "${aws_autoscaling_group.node.name}"
  adjustment_type = "ChangeInCapacity"
  metric_aggregation_type = "Maximum"
  policy_type = "StepScaling"
  step_adjustment {
    metric_interval_lower_bound = 3.0
    scaling_adjustment = 2
  }
  step_adjustment {
    metric_interval_lower_bound = 2.0
    metric_interval_upper_bound = 3.0
    scaling_adjustment = 2
  }
  step_adjustment {
    metric_interval_lower_bound = 1.0
    metric_interval_upper_bound = 2.0
    scaling_adjustment = -1
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-node"
  vpc_id = "${var.vpc_conf["id"]}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.elb-sg.id}"]
  }

  tags {
    Name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}-node"
    Stack = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
