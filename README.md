# PuppyTalk Infra

**PuppyTalk** 커뮤니티용 **Docker Compose·Nginx** 설정 레포입니다.  
**로컬 개발용 스택**과 **EC2(프로덕션) 배포용 스택**을 같은 저장소에서 관리합니다.

- **백엔드**: [2-kyjness-community-be](https://github.com/kyjness/2-kyjness-community-be)
- **프론트엔드**: [2-kyjness-community-fe](https://github.com/kyjness/2-kyjness-community-fe)

---

## 파일 역할

| 파일 | 용도 |
|------|------|
| `docker-compose.local.yml` | **로컬**: Nginx + 백엔드 + **프론트** + PostgreSQL + Redis + **MinIO** |
| `docker-compose.yml` | **EC2/프로덕션**: Nginx(HTTP→HTTPS) + 백엔드 + DB + Redis. **MinIO·프론트 컨테이너 없음** (객체 저장소는 AWS S3 등, 프론트는 CloudFront 등 별도 배포) |
| `nginx/default.local.conf` | 로컬 전용: `:80`만, `/v1`→백엔드, `/`→프론트, `/minio/`→MinIO 프록시 |
| `nginx/default.conf` | 프로덕션: `puppytalk.shop` 도메인, **Let’s Encrypt** 인증서, `/v1`·`/api/v1`→백엔드, 루트는 API 안내 문구(프론트는 별도 URL 안내) |

프로덕션 Compose는 호스트의 `/etc/letsencrypt`를 Nginx 컨테이너에 **읽기 전용**으로 마운트합니다. 인증서는 서버에서 certbot 등으로 발급·갱신하는 전제입니다.

### 환경 파일 ↔ Compose 매핑

| Compose 파일 | 사용하는 env 파일 | `env_file`이 붙는 서비스 |
|--------------|-------------------|---------------------------|
| `docker-compose.local.yml` | **`.env.local`** (저장소 루트에 필수) | `db`, `minio`, `backend` |
| `docker-compose.yml` | **`.env`** (EC2 등 서버 루트에 필수) | `db`, `backend` |

Compose 파일 안에 `${...}` 보간은 쓰지 않습니다. DB·MinIO 자격 증명은 각 컨테이너가 위 env 파일에서 직접 읽습니다. (`.env.local` / `.env`는 `.gitignore`로 커밋하지 않습니다.)

---

## 로컬 실행 (Docker)

### 1. 레포 배치

백엔드·프론트·인프라 세 레포가 **같은 상위 폴더**에 있어야 빌드 컨텍스트가 맞습니다.

```
상위폴더/
├── 2-kyjness-community-be/
├── 2-kyjness-community-fe/
└── 2-kyjness-community-infra/   ← 여기서 명령 실행
```

### 2. 환경 변수

```bash
cd 2-kyjness-community-infra
cp .env.example .env.local
```

로컬 스택은 **`docker-compose.local.yml`만** 쓰고, **`db` / `minio` / `backend`는 모두 `.env.local`을 읽습니다.**  
반드시 맞출 항목(자세한 키는 `.env.example` 참고):

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`(또는 예시와 동일한 DB 관련 키)
- `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`(MinIO 컨테이너용; 예시 기본값 사용 가능)
- `DB_PASSWORD` 등 백엔드·DB 연결 문자열과 일치하는 값
- `JWT_SECRET_KEY`: 32자 이상 랜덤 문자열
- MinIO/S3: `STORAGE_BACKEND`, `S3_*`, `S3_PUBLIC_BASE_URL`(예: `http://localhost/minio/puppytalk`) 등

### 3. 스택 기동 (로컬)

```bash
docker compose -f docker-compose.local.yml up --build -d
```

- 첫 실행은 `--build` 권장.
- 재기동만: `docker compose -f docker-compose.local.yml up -d`

백엔드 컨테이너 기동 시 `alembic upgrade head`가 실행되어 마이그레이션이 적용됩니다.

### 4. 로컬 포트

| 용도 | 호스트 포트 | 비고 |
|------|-------------|------|
| 웹 전체 (Nginx) | 80 | 프론트 `/`, API `/v1/` |
| PostgreSQL | 5432 | DB 클라이언트용 |
| Redis | 6379 | |
| MinIO API | 9000 | S3 호환 |
| MinIO 콘솔 | 9001 | 웹 UI |

백엔드·프론트는 호스트 포트를 열지 않고 Nginx(80) 경유입니다.

### 5. 동작 확인

- 프론트: http://localhost  
- API: http://localhost/v1/  
- Swagger: http://localhost/v1/docs  
- 헬스: http://localhost/v1/health  

마이그레이션만 수동:

```bash
docker compose -f docker-compose.local.yml exec backend alembic upgrade head
```

### 6. MinIO 버킷 공개 (이미지 Access Denied 방지)

스택 기동 후(버킷 이름은 `.env`의 `S3_BUCKET_NAME`에 맞게 조정):

```bash
docker exec minio mc alias set myminio http://localhost:9000 minioadmin minioadmin
docker exec minio mc anonymous set download myminio/puppytalk
```

콘솔(http://localhost:9001)에서 Access Rules로 동일 설정 가능.

### 7. 종료·볼륨 삭제

```bash
docker compose -f docker-compose.local.yml down
docker compose -f docker-compose.local.yml down -v   # DB·Redis·MinIO 데이터까지 초기화
```

### 기타 (로컬)

- 재빌드: `docker compose -f docker-compose.local.yml up --build -d`
- 백엔드만 재시작: `docker compose -f docker-compose.local.yml restart backend`
- 로그: `docker compose -f docker-compose.local.yml logs -f [nginx|backend|frontend]`

---

## EC2 / 프로덕션 (요약)

- **실행 절차는 SSH로 인스턴스에 접속한 뒤** 서버 환경에 맞게 진행합니다. (배포 스크립트 자동화 여부, 도메인·방화벽·IAM 등은 운영 정책에 따름.)
- **구성 요지**: `docker-compose.yml` + `nginx/default.conf` + 서버의 Let’s Encrypt 경로(`/etc/letsencrypt`) + 프로덕션용 **`.env`**(`db`·`backend`의 `env_file`, S3 등; MinIO 없음).
- Nginx는 **80 → 443 리다이렉트**, API는 `/v1/`, `/api/v1/` 프록시. 프론트는 Nginx 정적 호스팅이 아니라 **별도 CDN/호스팅** 전제입니다(`default.conf` 안내 문구와 동일).

프로덕션에서 DB·Redis 포트를 인터넷에 열지 않을지, 보안 그룹·방화벽은 반드시 별도로 정리하세요.

---

## 로컬 vs 프로덕션 Compose 비교

| 항목 | `docker-compose.local.yml` | `docker-compose.yml` |
|------|----------------------------|----------------------|
| 프론트 컨테이너 | 있음 | 없음 |
| MinIO | 있음 | 없음 |
| Nginx TLS(443) | 없음 | 있음 (Let’s Encrypt 마운트) |
| Nginx 설정 파일 | `default.local.conf` | `default.conf` |
| 환경 파일 | `.env.local` | `.env` |
