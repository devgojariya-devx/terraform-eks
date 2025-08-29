resource "aws_iam_role" "jump_server_role" {
  name = "jump-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eks_create_access_entry_policy" {
  name = "eks-create-access-entry-policy"
  description = "Allow eks:CreateAccessEntry on cbd-dev-cluster"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "eks:CreateAccessEntry",
        "eks:DeleteAccessEntry",
        "eks:DescribeAccessEntry",
        "eks:ListAccessEntries",
        "eks:UpdateAccessEntry"
      ],
      Resource = "arn:aws:eks:ap-south-1:735902244362:cluster/cbd-dev-cluster"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_create_access_entry" {
  role = aws_iam_role.jump_server_role.name
  policy_arn = aws_iam_policy.eks_create_access_entry_policy.arn
}


resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.jump_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.jump_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.jump_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_instance_profile" "jump_server_profile" {
  name = "jump-server-instance-profile"
  role = aws_iam_role.jump_server_role.name
}

resource "aws_instance" "jump_server" {
  ami                      = "ami-02d26659fd82cf299"
  instance_type            = "t3.medium"
  subnet_id                = module.vpc[0].public_subnets[0]
  key_name                 = "terraform"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.jump_server_sg.id]
  

  iam_instance_profile     = aws_iam_instance_profile.jump_server_profile.name
  user_data = <<-EOF
  #!/bin/bash
  set -ex

  apt-get update
  apt-get install -y curl unzip gnupg

  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  cd aws
  ./install -i /usr/local/aws -b /usr/local/bin
  cd ..

  curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl /usr/local/bin/

  wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
  apt-get update
  apt-get install -y terraform
  EOF

  tags = {
    Name = "jump-server"
  }
}


resource "aws_security_group" "jump_server_sg" {
  name        = "jump-server-sg"
  description = "Allow SSH, HTTP, and HTTPS access"
  vpc_id      = module.vpc[0].vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
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
    Name = "jump-server-sg"
  }
}
