data "template_file" "route53_policy" {
  template = "${file("policies/route53-policy.json")}"

  vars {
    zone_id = "${var.vpc_conf["zone_id"]}"
  }
}

resource "aws_iam_role_policy" "route53" {
  name = "${var.aws_conf["domain"]}-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${var.vpc_conf["role"]}"
}
