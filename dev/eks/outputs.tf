# OUTPUTS

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Certificate authority of the EKS cluster"
  value       = module.eks.cluster_ca_certificate
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

output "node_group_name" {
  description = "Name of the node group"
  value       = module.eks.node_group_name
}