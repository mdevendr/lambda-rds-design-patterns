resource "aws_security_group" "ssm_ec2" {
  name        = "iam-mysql-ssm-ec2-sg"
  description = "Private EC2 instance managed via SSM"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ssm_ec2_role" {
  name = "iam-mysql-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_ec2_core" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_ec2_profile" {
  name = "iam-mysql-ssm-ec2-profile"
  role = aws_iam_role.ssm_ec2_role.name
}

resource "aws_instance" "ssm_helper" {
  ami                         = data.aws_ami.al2023_arm.id
  instance_type               = "t4g.nano"
  subnet_id                   = aws_subnet.private_1.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.ssm_ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_ec2_profile.name

  user_data = <<-EOF
    #!/bin/bash
    yum install -y mysql
    curl -s -o /home/ec2-user/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
    chown ec2-user:ec2-user /home/ec2-user/global-bundle.pem
  EOF

  tags = { Name = "iam-mysql-ssm-helper" }
}

