# GitHub Actions → AWS: OIDC (AssumeRoleWithWebIdentity). AK/SK 없이 FE S3 배포·CloudFront 무효화.
# 순환 참조 없음: 본 파일은 frontend S3·CloudFront 리소스를 읽기만 함.

locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = local.github_oidc_url

  client_id_list = ["sts.amazonaws.com"]

  # token.actions.githubusercontent.com TLS 체인 기준(로테이션 시 AWS/GitHub 문서 확인)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

data "aws_iam_policy_document" "github_actions_fe_assume" {
  statement {
    sid     = "GithubActionsFeAssumeRoleWithWebIdentity"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_fe_oidc_subject]
    }
  }
}

data "aws_iam_policy_document" "github_actions_fe_deploy" {
  statement {
    sid    = "S3FrontendList"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.frontend.arn]
  }

  statement {
    sid    = "S3FrontendObjectsWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
  }

  statement {
    sid    = "CloudFrontInvalidateCache"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = [aws_cloudfront_distribution.frontend.arn]
  }
}

resource "aws_iam_role" "fe_github_actions" {
  name               = "${var.project_name}-fe-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_fe_assume.json

  tags = {
    Name = "${var.project_name}-fe-github-actions-role"
  }
}

resource "aws_iam_role_policy" "fe_github_actions_deploy" {
  name   = "${var.project_name}-fe-github-actions-deploy"
  role   = aws_iam_role.fe_github_actions.id
  policy = data.aws_iam_policy_document.github_actions_fe_deploy.json
}
