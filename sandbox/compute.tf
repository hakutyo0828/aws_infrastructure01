data "aws_ssm_parameter" "al2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ssm_parameter.al2.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  # Optional key pair
  key_name = var.key_name

  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}
