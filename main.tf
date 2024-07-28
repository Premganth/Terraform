
resource "aws_vpc" "vpc_1" {
  cidr_block="192.168.0.0/16"
  tags = {
    Name="vpc-1" 
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id     = aws_vpc.vpc_1.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id     = aws_vpc.vpc_1.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "subnet-2"
  }
}

resource "aws_internet_gateway" "igw_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "igw-1"
  }
}

resource "aws_route_table" "route_public" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_1.id
  }
  tags = {
    Name = "rta-1"
  }
}
resource "aws_route_table_association" "route_public_associate" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_public.id
}

resource "aws_security_group" "terraform_sg" {
  name        = "terraform_sg"
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terraform_security_group"
  }
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBcNSJr+2Vt2ZIXm83iXydy3x9k7axhZGw0D+yeFXhhEu1vznANYUZsW/0rZxNDxTm5BKoNhiNry5OjfXhOjRrn5HItbb395J36Pwf6ly5S5Ri5zmylf+v9ElZ4UzyEQ4khDKDpKkczf54aYS9Y0Q2ERnai3QZNBBFXtfgBLBJ7RVBNkk08LfKAc9nPyHhUGQGNGX7dv905mkk1WrfL2/Ka/UgHJ5JSr76N8E/X2XApWR4TIvgauoxOm8H5wAdyL4U9EB5r9sU0y8XhWOr7qhQKEMvhfVJGV7pGxTphPk/KWxPPp0M+W0Jws2C6nCBWU6dTBv/NUYcWB0PpMvGow4l pavithra@ASUS-VIvoBOOK-15"

}

data "aws_ami" "aws_image" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.4.20240429.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "public-ec2" {
  ami           = data.aws_ami.aws_image.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet_1.id
  key_name = "terraform-key"
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]

  availability_zone = "ap-south-1a"

  associate_public_ip_address = true

  tags = {
    Name = "public-ec2"
  }
}
resource "aws_instance" "private-ec2" {
  ami           = data.aws_ami.aws_image.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet_2.id
  key_name = "terraform-key"
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]

  availability_zone = "ap-south-1b"

  associate_public_ip_address = false

  tags = {
    Name = "private-ec2"
  }
}