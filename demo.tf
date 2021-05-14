
provider "aws" {
region = "us-east-1"
access_key = "AKIASZJWJNDAX2FA4RBD"
secret_key = "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"
}
#VPC-Create
resource "aws_vpc" "pawanraaz" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "pawanraaz"
  }
}

#Public_Subnet-Create
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.pawanraaz.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-subnet"
  }
}

#Private_Subnet-Create
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.pawanraaz.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-subnet"
  }
}

#Security_group_create
resource "aws_security_group" "my-sg" {
  name        = "pawanraazsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.pawanraaz.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pawanraaz"
  }
}
#IGW_Create
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.pawanraaz.id

  tags = {
    Name = "my-igw"
  }
}
#Route_table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.pawanraaz.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }

  tags = {
    Name = "public-rt"
  }
}
#route_table_association
resource "aws_route_table_association" "public-asso" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}
#Keypair_create
resource "aws_key_pair" "pawanraazkey" {
  key_name   = "pawanraazkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMS7fHCFTsp9rbNITYzRHWLf51/RUB0vTJLj8zSQ51dKDL1TYht2UOnxaTMTKFKfCmvX+DrkJFgdcCBD9quZgXmkBni+UjI0KLEsOr1laXPYrAO6tUtF5kehcItqBMrzVrbKt5/leTHdpDB2cyKVnwZUXPTA531Ue1JdzFuyZp+CbMF7qb8e0h9pFWd1263JQP1H2Me008B3kqrc1J1hh9yRD+KvbAeGuI6dtzUSYWkUY9R+dMAFs007Y2qATZF1p3f41kRyCELtjEJSKWHXSszrIwxRV5Z8ZV2ILhdp0A7kU1ehnKHxO30GU5G6YqH4iat1wjDyRHGyQPSbJb8RONgS4vgPFmBwx3sSFYFlQnbsGiDdXxLNUX7TbXXQjokMkjR/fnCtH5pE3BPU0S986+seMHDCeY0kdbSh5a+BQYQ2EZlJaCoOaRaEkfLqiNJ/1rKpSR1m1OvB+TgWBhxsJ/YqzUNmr3LVZ2NCsk083W4kjnUo0loPLIyhdR69O0QMs= root@terraform-vm"
}
#ec2_create
resource "aws_instance" "dev-server" {
  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  key_name               = "pawanraazkey"
  tags = {
    Name = "dev-server"
  }
}
#db-vm-setup
resource "aws_instance" "db-server" {
  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.my-sg.id]
  key_name               = "pawanraazkey"
  tags = {
    Name = "db-server"
  }
}

#Public-ip-add
resource "aws_eip" "my-ip" {
  instance = aws_instance.dev-server.id
  vpc      = true
}
#Public-ip-create_nat-gateway
resource "aws_eip" "my-nat-ip" {
  vpc      = true
}

#Nat-gateway_create
resource "aws_nat_gateway" "my-nat" {
  allocation_id = aws_eip.my-nat-ip.id
  subnet_id     = aws_subnet.public-subnet.id
}

#Route_table_private_subnet
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.pawanraaz.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

#Route_table_asso_nat-gateway
resource "aws_route_table_association" "private-asso" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}



