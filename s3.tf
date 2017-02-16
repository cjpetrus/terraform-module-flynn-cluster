resource "aws_s3_bucket" "datastore" {
  bucket = "datastore.${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  acl = "private"

  tags {
    Name = "datastore.${var.app_conf["name"]}.${var.aws_conf["domain"]}"
    Stack = "${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  }
}

data "template_file" "datastore" {
  template = "${file("policies/s3-template.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore.id}"
  }
}

data "template_file" "s3_policy" {
  template = "${file("policies/s3-bucket-template.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore.id}"
    role_arn = "${var.vpc_conf["role_arn"]}"
  }
}

resource "aws_iam_role_policy" "datastore" {
  name = "datastore.${var.app_conf["name"]}.${var.aws_conf["domain"]}"
  role = "${var.vpc_conf["role"]}"
  policy = "${data.template_file.datastore.rendered}"
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = "${aws_s3_bucket.datastore.bucket}"
  policy = "${data.template_file.s3_policy.rendered}"
}
