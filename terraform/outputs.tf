output "ecr_be_repository_url" {
  description = "백엔드 ECR 리포지토리 URL (k8s/overlays/prod-seoul Kustomize images.newName에 사용, 태그 제외)"
  value       = aws_ecr_repository.be.repository_url
}

output "s3_media_bucket_id" {
  description = "미디어 S3 버킷 ID (terraform/media.tf aws_s3_bucket.media)"
  value       = aws_s3_bucket.media.id
}

output "db_server_public_ip" {
  description = "DB/Redis EC2 퍼블릭 IP"
  value       = aws_instance.db_server.public_ip
}

output "db_server_private_ip" {
  description = "DB/Redis EC2 프라이빗 IP (ECS 태스크 env 등)"
  value       = aws_instance.db_server.private_ip
}

output "github_actions_fe_deploy_role_arn" {
  description = "FE GitHub Actions OIDC용 IAM Role ARN (configure-aws-credentials role-to-assume)"
  value       = aws_iam_role.fe_github_actions.arn
}

output "eks_cluster_name" {
  description = "EKS 클러스터 이름 (puppytalk-eks-seoul)"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_oidc_issuer_url" {
  description = "IRSA 등용 OIDC Issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = module.eks.cluster_arn
}
