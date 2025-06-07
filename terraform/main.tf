provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "available" {}

################### VPC + NAT Gateway Networking ###################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "zeebabes-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "zeebabes-igw" }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = { Name = "zeebabes-nat-gw" }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "zeebabes-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "zeebabes-private-rt" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "private-${count.index}" }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

################### IAM Roles ###################

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node_group_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

################### EKS Cluster + Nodes ###################

resource "aws_eks_cluster" "zeebabes" {
  name     = "zeebabes"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.zeebabes.name
  node_group_name = "zeebabes-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  disk_size      = 20
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  remote_access {
    ec2_ssh_key = "zeecentoskey"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.registry_policy
  ]
}

################### Kubernetes & Helm Providers ###################

data "aws_eks_cluster" "zeebabes" {
  name = aws_eks_cluster.zeebabes.name
}

data "aws_eks_cluster_auth" "zeebabes" {
  name = aws_eks_cluster.zeebabes.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.zeebabes.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.zeebabes.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.zeebabes.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.zeebabes.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.zeebabes.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.zeebabes.token
  }
}

################### aws-auth ConfigMap ###################

resource "kubernetes_config_map" "aws_auth" {
  depends_on = [aws_eks_node_group.default]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode([{
      rolearn  = aws_iam_role.node_group_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:bootstrappers",
        "system:nodes"
      ]
    }])
  }
}

################### ArgoCD Helm Chart ###################

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.52.1"

  create_namespace = true
  values = [file("argocd-values.yaml")]

  depends_on = [
    aws_eks_cluster.zeebabes,
    aws_eks_node_group.default
  ]
}

################### Outputs ###################

output "cluster_name" {
  value = aws_eks_cluster.zeebabes.name
}

output "endpoint" {
  value = aws_eks_cluster.zeebabes.endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region us-east-2 --name ${aws_eks_cluster.zeebabes.name}"
}

output "dashboard_access_command" {
  value = "kubectl proxy --address='0.0.0.0' --disable-filter=true"
}

output "aws_auth_applied" {
  value = "aws-auth ConfigMap is applied via Terraform"
}
