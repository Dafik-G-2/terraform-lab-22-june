provider "aws" {
  region = "ap-south-1"
}
resource "aws_security_group" "my-sg-trfm" {
  name        = "my-sg-trfm"
  description = "Allow SSH, HTTP and HTTPS"
  # vpc_id = aws_vpc.my-vpc-trfm.id
  dynamic "ingress" {
    for_each = var.security_group_rules
    content {
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = [ingress.value["cidr_blocks"]]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "my-sg-trfm-new"
  }
}
data "template_file" "setup-1" {
  template = file("./scripts/setup_1.sh")
}
data "template_file" "setup-2" {
  template = file("./scripts/setup_2.sh")
}
resource "aws_instance" "my-lab-trfm" {
  # for_each        = toset(var.inst-names)
  count           = var.instance_count
  ami             = var.ami-id
  instance_type   = var.instance-type
  security_groups = [aws_security_group.my-sg-trfm.id]
  subnet_id       = element(local.subnet_ids, count.index)
  user_data = element(
    [data.template_file.setup-1.rendered,
      data.template_file.setup-2.rendered
    ], count.index
  )
  key_name = "terraform"
  tags = {
    # Name = "my - ${each.value}"
    Name = "My-inst-${count.index + 1}"
  }
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.key-path)
  }
  provisioner "file" {
    source      = "./scripts/setup_1.sh"
    destination = "/tmp/setup_1.sh"
  }
  provisioner "file" {
    source      = "./scripts/setup_2.sh"
    destination = "/tmp/setup_2.sh"
  }
  # provisioner "remote-exec" {
  #   inline = [ 
  #           "chmod +x /tmp/setup_1.sh",
  #           "chmod +x /tmp/setup_2.sh",
  #           "/tmp/setup_${count.index + 1}.sh" 
  #         ]
  # }
}
resource "aws_vpc" "my-vpc-trfm" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.my-vpc-trfm.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.my-vpc-trfm.id
  availability_zone = "ap-south-1b"
  cidr_block        = "10.0.2.0/24"
  map_public_ip_on_launch = true
}
locals {
  subnet_ids = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
}
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc-trfm.id
}
resource "aws_route_table" "my-rt-1" {
  vpc_id = aws_vpc.my-vpc-trfm.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
}
resource "aws_route_table_association" "rt-association" {
  count = length(local.subnet_ids)
  route_table_id = aws_route_table.my-rt-1.id
  subnet_id       = element(local.subnet_ids, count.index)
}
resource "aws_route" "my-route" {
  route_table_id         = aws_route_table.my-rt-1.id
  gateway_id             = aws_internet_gateway.my-igw.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_lb" "web-lb" {
  load_balancer_type = "application"
    dynamic "subnet_mapping" {
    for_each = local.subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }
  # vpc_id             = aws_vpc.my-vpc-trfm.id
  security_groups    = [aws_security_group.my-sg-trfm.id]
  tags = {
    Name = "web-lb-trfm"
  }
  # depends_on = [aws_vpc.my-vpc-trfm, aws_lb_target_group.my-target-group]
}
resource "aws_lb_target_group" "my-target-group" {
  vpc_id     = aws_vpc.my-vpc-trfm.id
  # depends_on = [aws_vpc.my-vpc-trfm]
  protocol   = "HTTP"
  port       = 80
  tags = {
    Name = "my-target-group-trfm"
  }
}
resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.web-lb.arn
  protocol          = "HTTP"
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-target-group.arn
  }
}
resource "aws_lb_target_group_attachment" "lb-target-attachment" {
  count = var.instance_count
  target_group_arn = aws_lb_target_group.my-target-group.arn
  target_id = aws_instance.my-lab-trfm[count.index].id
  port = 80
}
# resource "null_resource" "my-null-trfm" {
#   count = var.instance_count
#   triggers = {
#     my-null-trfm-instance-ids = aws_instance.my-lab-trfm[count.index].id
#   }
#   connection {
#     type        = "ssh"
#     private_key = file(var.key-path)
#     host        = aws_instance.my-lab-trfm[count.index].public_ip
#     user        = "ec2-user"
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "echo '${data.template_file.setup-1.rendered}' > /tmp/setup_1.sh",
#       "echo '${data.template_file.setup-2.rendered}' > /tmp/setup_1.sh",
#       "chmod +x /tmp/setup_${count.index + 1}.sh",
#       "/tmp/setup_${count.index + 1}.sh"
#     ]
#   }
# }