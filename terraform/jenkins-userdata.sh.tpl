#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# 1. 시스템 업데이트 및 필수 도구 (net-tools는 필수입니다!)
apt-get update -y
apt-get install -y fontconfig openjdk-17-jre wget curl git unzip net-tools

# 2. Jenkins 패키지 최신 LTS 버전으로 상향 (2.492.1 버전)
wget https://pkg.jenkins.io/debian-stable/binary/jenkins_2.492.1_all.deb
dpkg -i jenkins_2.492.1_all.deb || true

# [핵심 추가] 꼬인 의존성을 풀면서 젠킨스 서비스를 시스템에 강제로 등록시킵니다.
apt-get --fix-broken install -y
apt-get install -y jenkins  # 한 번 더 확인 사살 (서비스 등록 보장)

# 3. 자동화 설정 (JCasC) - 로그인 번거로움을 없애줍니다.
systemctl stop jenkins || true
install -d -o jenkins -g jenkins -m 0755 /var/lib/jenkins/plugins
curl -fsSL -o /var/lib/jenkins/plugins/configuration-as-code.hpi "https://updates.jenkins.io/latest/configuration-as-code.hpi"

install -d -o jenkins -g jenkins -m 0755 /var/lib/jenkins
cat > /var/lib/jenkins/jenkins.yaml <<'__JENKINS_CASC_YAML_EOF__'
${jenkins_yaml_content}
__JENKINS_CASC_YAML_EOF__
chown -R jenkins:jenkins /var/lib/jenkins
chmod 600 /var/lib/jenkins/jenkins.yaml

# systemd: CasC 파일 경로 고정 (tfvars의 jenkins_casc_password 등은 이 yaml에 이미 렌더됨)
mkdir -p /etc/systemd/system/jenkins.service.d
echo -e '[Service]\nEnvironment="CASC_JENKINS_CONFIG=/var/lib/jenkins/jenkins.yaml"' \
  > /etc/systemd/system/jenkins.service.d/override.conf

# 4. Docker 설치 및 권한
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins

# 5. AWS CLI 설치
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
./aws/install --update

# 6. override 반영 후 Jenkins 기동 (restart로 환경·CasC 재로드)
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins