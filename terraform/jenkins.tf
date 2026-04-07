# Jenkins EC2 (Ubuntu 22.04, 퍼블릭 서브넷). CasC: /var/lib/jenkins/jenkins.yaml + CASC_JENKINS_CONFIG

data "aws_ami" "ubuntu_jammy_x86" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  jenkins_casc_rendered = templatefile("${path.module}/jenkins.yaml.tpl", {
    jenkins_casc_user     = var.jenkins_casc_user
    jenkins_casc_password = var.jenkins_casc_password
    github_token          = var.jenkins_github_token
  })
}

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu_jammy_x86.id
  instance_type          = var.jenkins_instance_type
  iam_instance_profile   = aws_iam_instance_profile.jenkins_ec2.name
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public_1.id

  user_data = templatefile("${path.module}/jenkins-userdata.sh.tpl", {
    jenkins_yaml_content = local.jenkins_casc_rendered
  })

  tags = {
    Name = "${var.project_name}-jenkins-server"
  }

  depends_on = [
    aws_route_table_association.public_1,
  ]
}
