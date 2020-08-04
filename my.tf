#Using AWS provider
provider "aws"{
	region = "ap-south-1"
	profile = "myprofile"
}

#Creating VPC
resource "aws_vpc" "ModiVPC" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "ModiVPC"
  }
}

#Creating Public Subnet
resource "aws_subnet" "ModiPublicSubnet" {
depends_on = [
    aws_vpc.ModiVPC,
]
  vpc_id     = aws_vpc.ModiVPC.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "ModiPublicSubnet"
  }
}

    #Creating Private Subnet
    resource "aws_subnet" "ModiPrivateSubnet" {
    depends_on = [
        aws_vpc.ModiVPC,
    ]
    vpc_id     = aws_vpc.ModiVPC.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "ModiPrivateSubnet"
    }
    }

#Creating Internet Gateway
resource "aws_internet_gateway" "ModiInternetGateway" {
depends_on = [
    aws_vpc.ModiVPC,
]

  vpc_id = aws_vpc.ModiVPC.id

  tags = {
    Name = "ModiInternetGateway"
  }
}

#Creating Routing Table 
resource "aws_route_table" "ModiRoutingTable" {
depends_on = [
    aws_vpc.ModiVPC,
]
  vpc_id = aws_vpc.ModiVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ModiInternetGateway.id
  }

  tags = {
    Name = "ModiRoutingTable"
  }
}

#Assigning Routing Table to Public Subnet
resource "aws_route_table_association" "ModiSubnetAssociation" {
depends_on = [
    aws_subnet.ModiPublicSubnet,
]
  subnet_id      = aws_subnet.ModiPublicSubnet.id
  route_table_id = aws_route_table.ModiRoutingTable.id

}

#Creating Security Group for WordPress Site
resource "aws_security_group" "ModiWPSG" {
depends_on = [
    aws_vpc.ModiVPC
]
  name        = "ModiWPSG"
  description = "allow icmp+ssh+httpd"
  vpc_id      = aws_vpc.ModiVPC.id

  ingress {
    description = "allow ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow httpd"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ModiWPSG"
  }
}

#Creating Security Group for MySQL Site
resource "aws_security_group" "ModiSQLSG" {
depends_on = [
    aws_security_group.ModiWPSG,
]
  name        = "ModiSQLSG"
  description = "MYSQL security group"
  vpc_id      = aws_vpc.ModiVPC.id

  ingress {
    description = "allowing wordpress"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ModiWPSG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ModiSQLSG"
  }
}

#Launching WordPress Instance
resource "aws_instance" "WordPress" {
depends_on = [
	aws_security_group.ModiWPSG,
]
	ami = "ami-000cbce3e1b899ebd"
	instance_type = "t2.micro"
	key_name = "mykey"
    vpc_security_group_ids = [aws_security_group.ModiWPSG.id]
	subnet_id = aws_subnet.ModiPublicSubnet.id

    tags = {
        Name = "WordPress"
    }
}

#Launching MySQL Instance
resource "aws_instance" "MySQL" {
depends_on = [
	aws_security_group.ModiSQLSG,
]
	ami = "ami-08706cb5f68222d09"
	instance_type = "t2.micro"
	key_name = "mykey"
    vpc_security_group_ids = [aws_security_group.ModiSQLSG.id]
	subnet_id = aws_subnet.ModiPrivateSubnet.id

    tags = {
        Name = "MySQL"
    }
}

#Printing Output in terminal
output "WordpressIP" {
    value = aws_instance.WordPress.public_ip
}

output "WordpressID" {
    value = aws_instance.WordPress.id
}
