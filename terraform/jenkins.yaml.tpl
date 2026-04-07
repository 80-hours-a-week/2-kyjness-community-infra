# aws-credentials(id)는 CasC에 넣지 않음 → Jenkins UI에서 등록하거나 Jenkins EC2에 IAM Instance Profile 부여 권장.
# Terraform은 export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN 후 apply.
jenkins:
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: '${jenkins_casc_user}'
          password: '${jenkins_casc_password}'
credentials:
  system:
    domainCredentials:
      - credentials:
          - string:
              scope: GLOBAL
              id: "github-token"
              secret: '${github_token}'
