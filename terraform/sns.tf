# sns.tf

# 1. SNS 토픽 생성 (알림을 모아두는 방송국 역할)
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications-topic"
}

# 2. ECS(백엔드 서버)가 SNS에 알림을 보낼 수 있도록 권한 부여
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "${var.project_name}-sns-publish-policy"
  description = "Allow ECS tasks to publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

# 3. SNS Publish 권한은 ecs_task_role에 연결 (iam.tf ecs_task_role_sns)