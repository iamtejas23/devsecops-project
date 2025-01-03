provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main_vpc"
  }
}

# Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "main_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "main_igw"
  }
}

# Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# Route Table Association
resource "aws_route_table_association" "main_subnet_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# Security Group
resource "aws_security_group" "main_security_group" {
  name        = "main_security_group"
  description = "Allow SSH and HTTP/HTTPS"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "main_security_group"
  }
}

# Jenkins and DevSecOps Server
resource "aws_instance" "jenkins_server" {
  ami                         = "ami-0ca9fb66e076a6e32" # Amazon Linux 2 AMI
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.main_subnet.id
  vpc_security_group_ids      = [aws_security_group.main_security_group.id]
  associate_public_ip_address = true
  key_name                    = "MasterKey" # Replace with your actual key pair name

  tags = {
    Name = "Jenkins DevSecOps Server"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update and install required packages
              yum update -y
              amazon-linux-extras enable java-openjdk11
              sudo yum install java-17-amazon-corretto -y
              yum install git docker wget tar -y

              # Start and enable Docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Jenkins
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

              #STEP-3: DOWNLOAD JAVA11 AND JENKINS
              sudo yum install java-17-amazon-corretto -y
              yum install jenkins -y
              systemctl start jenkins
              systemctl enable jenkins

              # Install Trivy for container image vulnerability scanning
              curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh

              # Install OWASP ZAP for application security testing
              wget https://github.com/zaproxy/zaproxy/releases/download/v2.13.0/ZAP_2.13.0_Linux.tar.gz
              tar -xzf ZAP_2.13.0_Linux.tar.gz -C /opt
              ln -s /opt/ZAP_2.13.0 /opt/zap
              ln -s /opt/zap/zap.sh /usr/bin/zap

              # Final message
              echo "Jenkins, Trivy, and OWASP ZAP setup completed."
  EOF
}

# Output the public IP address of the Jenkins server
output "jenkins_server_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}
