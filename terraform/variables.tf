variable "project_name" {
  type        = string
  default     = "puppytalk"
  description = "리소스 Name 태그·이름 접두에 공통 사용"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "domain_name" {
  type    = string
  default = "puppytalk.shop"
}

# --- Jenkins EC2 (SSH 키는 ec2_db.tf aws_key_pair.deployer와 동일) ---
variable "jenkins_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Jenkins + Docker 빌드용 인스턴스 타입"
}

variable "jenkins_casc_user" {
  type        = string
  default     = "admin"
  description = "JCasC 로컬 사용자 id"
}

variable "jenkins_casc_password" {
  type        = string
  sensitive   = true
  description = "JCasC 로컬 사용자 비밀번호"
}

variable "jenkins_github_token" {
  type        = string
  sensitive   = true
  description = "Jenkins GitHub credential (string id: github-token)"
}

# EC2 user_data에서 postgres 비밀번호로 사용
variable "db_master_password" {
  type        = string
  sensitive   = true
  description = "PostgreSQL postgres 사용자 비밀번호"
}

# GitHub Actions OIDC: IAM Role Trust의 sub 클레임 (해당 레포 워크플로만 Assume 허용)
variable "github_fe_oidc_subject" {
  type        = string
  default     = "repo:kyjness/2-kyjness-community-fe:*"
  description = "token.actions.githubusercontent.com:sub StringLike 패턴 (브랜치·환경 제한 시 :ref:refs/heads/main 등으로 좁힘)"
}

variable "eks_cluster_version" {
  type        = string
  default     = "1.31"
  description = "EKS Kubernetes 버전 (puppytalk-eks-seoul)"
}
