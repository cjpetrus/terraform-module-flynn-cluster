/*resource "aws_route53_zone" "app_zone" {
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}."
  tags {
    Name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
    Stack = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  }
}

resource "aws_route53_record" "zone_dns" {
  zone_id = "${var.vpc_conf["zone_id"]}"
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  type = "NS"
  ttl = "30"
  records = [
    "${aws_route53_zone.app_zone.name_servers.0}",
    "${aws_route53_zone.app_zone.name_servers.1}",
    "${aws_route53_zone.app_zone.name_servers.2}",
    "${aws_route53_zone.app_zone.name_servers.3}"
  ]
}

resource "aws_route53_record" "dashboard" {
  zone_id = "${aws_route53_zone.app_zone.zone_id}"
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  type = "A"

  alias {
    name = "${aws_elb.service.dns_name}"
    zone_id = "${aws_elb.service.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_zone" {
  zone_id = "${aws_route53_zone.app_zone.zone_id}"
  name = "*"
  type = "CNAME"
  ttl = "30"
  records = ["${var.app_conf["name"]}.${var.aws_conf["domain"]}"]
}*/

resource "aws_route53_record" "dashboard" {
  zone_id = "${var.vpc_conf["zone_id"]}"
  name = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  type = "A"

  alias {
    name = "${aws_elb.service.dns_name}"
    zone_id = "${aws_elb.service.zone_id}"
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = ["*"]
  }
}

resource "aws_route53_record" "app_zone" {
  zone_id = "${var.vpc_conf["zone_id"]}"
  name = "*.${var.app_conf["name"]}"
  type = "CNAME"
  ttl = "30"
  records = ["${var.app_conf["name"]}.${var.aws_conf["domain"]}"]
}
