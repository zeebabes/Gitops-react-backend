output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security Group associated with EKS Cluster"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS Region"
  value       = var.aws_region
}
