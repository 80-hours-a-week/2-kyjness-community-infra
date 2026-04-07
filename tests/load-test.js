import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 20,          // 20명의 가상 유저
  duration: '2m',   // 2분 동안 테스트
};

export default function () {
  // 배포 완료 후 생성될 실제 ALB 주소로 나중에 교체해야 합니다.
  const res = http.get('https://api.puppytalk.shop/v1/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.1);
}