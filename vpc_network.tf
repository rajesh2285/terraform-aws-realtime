resource "aws_vpc" "my-vpc" {
    cidr_block  = "${var.vpc_cidr_block}"
    instance_tenancy  = "${var.vpc_tenancy}"
    tags {
      Name = "Rajesh_VPC"
    }
}

resource "aws_subnet" "subnets" {
    count = "${length(data.aws_availability_zones.azs.names)}"
    vpc_id = "${aws_vpc.my-vpc.id}"
    cidr_block = "${element(var.aws_subnet,count.index)}"
    map_public_ip_on_launch = true
    availability_zone = "${element(data.aws_availability_zones.azs.names,count.index)}"
    tags {
      Name = "Subnet-${count.index+1}"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id =  "${aws_vpc.my-vpc.id}"
    tags {
      Name = "My-IGW"
    }
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
    }
}

resource "aws_route_table_association" "rtas" {
    count = "3"
    subnet_id = "${element(aws_subnet.subnets.*.id,count.index)}"
    route_table_id  = "${aws_route_table.public.id}"
}

resource "aws_key_pair" "ssh-key" {
    key_name = "EC2_NEW"
    public_key = "${file("ec2.pub")}"
}
resource "aws_instance" "servers" {

  count = "${length(data.aws_availability_zones.azs.names)}"
  ami = "ami-0cd3dfa4e37921605"
  instance_type = "t2.micro"
  subnet_id = "${element(aws_subnet.subnets.*.id,count.index)}"
  user_data = "${file("httpd.sh")}"
  key_name  = "${aws_key_pair.ssh-key.key_name}"
  security_groups  = ["${aws_security_group.allow.id}"]
  tags {
    Name = "Server-${count.index+1}"
  }
}

resource "aws_security_group" "allow" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    ingress {
      from_port = 0
      to_port = 0
      protocol  = -1
      cidr_blocks  = ["0.0.0.0/0"]
    }
    egress {
      from_port = 0
      to_port = 0
      protocol  = -1
      cidr_blocks  = ["0.0.0.0/0"]
    }
}

resource "aws_elb" "alb" {
    name  = "Rajesh-ALB"
    subnets = ["${aws_subnet.subnets.*.id}"]
    security_groups  = ["${aws_security_group.allow.id}"]
    listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/index.html"
    interval            = 30
  }
  instances                   = ["${aws_instance.servers.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 200

}

output "elb-dns" {
    value = "${aws_elb.alb.dns_name}"
}
