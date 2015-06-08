# Configure the AWS Provider
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.region}"
}

resource "aws_launch_configuration" "consul" {
    name = "consul-${var.release}-${var.build}"
    image_id = "${var.ami}"
    instance_type = "m3.medium"
    key_name = "${var.key_name}"
    security_groups = [
      "${aws_security_group.consul.id}",
      "${var.internet_security_group_id}",
      "${var.shared_services_security_group_id}",
    ]

    user_data = "NUBIS_PROJECT=${var.project}\nNUBIS_ENVIRONMENT=${var.environment}\nNUBIS_DOMAIN=${var.nubis_domain}\nCONSUL_SECRET=${var.consul_secret}\nCONSUL_BOOTSTRAP_EXPECT=$(( 1 +${var.servers} ))\nCONSUL_KEY=\"${file("${var.ssl_key}")}\"\nCONSUL_CERT=\"${file("${var.ssl_cert}")}\""
}

resource "aws_autoscaling_group" "consul" {
  vpc_zone_identifier = []
  availability_zones  = []

  name = "consul-${var.release}-${var.build}"
  max_size = "${var.servers}"
  min_size = "${var.servers}"
  health_check_grace_period = 10
  health_check_type = "EC2"
  desired_capacity = "${var.servers}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.consul.name}"
  load_balancers = [
    "${aws_elb.consul.name}"
  ]

  tag {
    key = "Name"
    value = "Consul member node (v/${var.release}.${var.build})"
    propagate_at_launch = true
  }
}

# Single node necessary for bootstrap and self-discovery
# XXX: Problematic if it fails
resource "aws_instance" "bootstrap" {
  ami = "${var.ami}"
  
  instance_type = "m3.medium"
  key_name = "${var.key_name}"
  security_groups = [
    "${aws_security_group.consul.id}",
    "${var.internet_security_group_id}",
    "${var.shared_services_security_group_id}",
  ]
  
  tags {
        Name = "Consul boostrap node (v/${var.release}.${var.build})"
        Release = "${var.release}"
  }

  user_data = "NUBIS_PROJECT=${var.project}\nNUBIS_ENVIRONMENT=${var.environment}\nNUBIS_DOMAIN=${var.nubis_domain}\nCONSUL_SECRET=${var.consul_secret}\nCONSUL_BOOTSTRAP_EXPECT=$(( 1 + ${var.servers} ))\nCONSUL_KEY=\"${file("${var.ssl_key}")}\"\nCONSUL_CERT=\"${file("${var.ssl_cert}")}\""
}

resource "aws_security_group" "consul" {
  name = "consul-${var.release}-${var.build}"
  description = "Consul internal traffic + maintenance."
  
  vpc_id = "${var.vpc_id}"
  
  // These are for internal traffic
  ingress {
    from_port = 8300
    to_port = 8303
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  // This is for the gossip traffic
  ingress {
    from_port = 8300
    to_port = 8303
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // These are for maintenance
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 8500
    to_port = 8500
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Put back Amazon Default egress all rule
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a new load balancer
resource "aws_elb" "consul" {
  name = "elb-${var.project}-${var.release}-${var.build}"
  subnets = [ ]
  
  instances = [
    "${aws_instance.bootstrap.id}"
  ]

  listener {
    instance_port = 8500
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 5
    timeout = 5
    target = "HTTP:8500/v1/status/peers"
    interval = 30
  }

  cross_zone_load_balancing = true

  security_groups = [
    "${aws_security_group.elb.id}"
  ]
}

resource "aws_security_group" "elb" {
  name = "elb-${var.project}-${var.release}-${var.build}"
  description = "Allow inbound traffic for consul"

  vpc_id = "${var.vpc_id}"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # Put back Amazon Default egress all rule
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_route53_record" "discovery" {
   zone_id = "${var.zone_id}"
   name = "${var.region}.${var.domain}"
   type = "A"
   ttl = "30"
   records = ["${aws_instance.bootstrap.private_ip}"]
}

resource "aws_route53_record" "ui" {
   zone_id = "${var.zone_id}"
   name = "ui.${var.region}.${var.domain}"
   type = "CNAME"
   ttl = "30"
   records = ["dualstack.${aws_elb.consul.dns_name}"]
}
