# PuppyTalk Infra

**PuppyTalk** 커뮤니티 서비스의 인프라·배포 설정 레포입니다.  
Docker Compose로 Nginx(리버스 프록시), 백엔드(FastAPI), 프론트엔드(React), PostgreSQL, Redis, MinIO를 한 번에 기동합니다.

- **백엔드**: [2-kyjness-community-be](https://github.com/kyjness/2-kyjness-community-be)
- **프론트엔드**: [2-kyjness-community-fe](https://github.com/kyjness/2-kyjness-community-fe)

---

## 포트

| 용도 | 호스트 포트 | 접속 URL |
|------|-------------|----------|
| **웹 전체** (Nginx) | 80 | http://localhost — 프론트(/)·API(/v1/) 통합 |
| **PostgreSQL** (직접 접속) | 5432 | `localhost:5432` (DB 클라이언트용) |
| **Redis** (직접 접속) | 6379 | `localhost:6379` |
| **MinIO API** | 9000 | http://localhost:9000 (S3 호환) |
| **MinIO 콘솔** | 9001 | http://localhost:9001 (웹 UI) |

백엔드·프론트는 호스트에 포트를 열지 않고, Nginx(80)를 통해서만 접근합니다.

---

## 실행 방법

### 1. 레포 배치

백엔드·프론트·인프라 세 레포가 **같은 상위 폴더**에 있어야 합니다.

```
상위폴더/
├── 2-kyjness-community-be/
├── 2-kyjness-community-fe/
└── 2-kyjness-community-infra/   ← 여기서 아래 명령 실행
```

### 2. 환경 변수

```bash
cd 2-kyjness-community-infra
cp .env.example .env
```

`.env`에서 아래 항목을 반드시 설정하세요.

- `POSTGRES_PASSWORD`, `DB_PASSWORD`: 동일한 비밀번호
- `JWT_SECRET_KEY`: 32자 이상 랜덤 문자열 (배포 시 필수)
- MinIO/S3 사용 시: `STORAGE_BACKEND=s3`, `S3_BUCKET_NAME`, `S3_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (예시는 `.env.example` 참고)

### 3. 스택 기동

```bash
docker compose up --build -d
```

- 첫 실행은 `--build`로 이미지 빌드 후 기동.
- 코드 수정 없이 재기동만 할 때: `docker compose up -d`

백엔드 컨테이너 기동 시 `alembic upgrade head`가 자동 실행되어 DB 마이그레이션이 적용됩니다.

### 4. 동작 확인

- **프론트**: http://localhost  
- **API 루트**: http://localhost/v1/  
- **API 문서 (Swagger)**: http://localhost/v1/docs  
- **헬스**: http://localhost/v1/health  

마이그레이션만 수동 실행하려면:

```bash
docker compose exec backend alembic upgrade head
```

### 5. MinIO 버킷 공개 설정 (이미지 Access Denied 해결)

MinIO 기본 계정은 `minioadmin` / `minioadmin`입니다. 프로필·게시글 이미지가 브라우저에서 바로 보이려면 **버킷을 읽기(다운로드) 공개**로 한 번 설정해야 합니다. 스택 기동 후 아래를 실행하세요.

```bash
# 1. mc로 MinIO에 관리자 alias 등록 (이름 myminio, 기본 계정 사용)
docker exec minio mc alias set myminio http://localhost:9000 minioadmin minioadmin

# 2. puppytalk 버킷을 누구나 다운로드 가능하게 설정
docker exec minio mc anonymous set download myminio/puppytalk
```

- `.env`의 `S3_BUCKET_NAME`이 `puppytalk`가 아니면 두 번째 명령의 `puppytalk`를 해당 버킷 이름으로 바꾸세요.
- MinIO 콘솔(http://localhost:9001)에서 버킷 → Access Rules로 같은 설정을 할 수도 있습니다.

### 6. 종료

```bash
docker compose down
```

### 7. 볼륨까지 삭제 (DB·Redis·MinIO 데이터 초기화)

```bash
docker compose down -v
```

- `postgres_data`, `redis_data`, `minio_data`가 삭제됩니다.

---

## 기타

- **재빌드 후 기동**: `docker compose up --build -d`
- **백엔드만 재시작**: `docker compose restart backend`
- **로그**: `docker compose logs -f backend` / `docker compose logs -f frontend` / `docker compose logs -f nginx`
