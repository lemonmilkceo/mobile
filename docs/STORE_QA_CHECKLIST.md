# Store / QA Checklist — Bae & Lee Member App

## 실기기 QA (남/여 각 1계정)

- [ ] 초대 코드 가입 → 로그인 → 세션 복구
- [ ] 프로필 필수값·키워드·사진 5장 저장
- [ ] 매칭 on/off · 계정 삭제 요청
- [ ] `FEED_WAIT_NOTICE=true`일 때 남/여 모두 대기 공지
- [ ] 공지 해제 후 남성 피드·상세·소개 요청 (BFF)
- [ ] 여성 기기 푸시 `offer_to_female` (FCM 설정 후)
- [ ] Inbox 수락/거절 → 남성 푸시 결과
- [ ] 수락 후 남성 연락처 표시 (이름·전화, 잠금화면 푸시 본문에 PII 없음)
- [ ] Universal Link `/match/{token}` → 앱 Inbox/상세 (미설치 시 웹 폴백)
- [ ] cron D+1 리마인드 · 만료 푸시 (wedding cron + FCM)

## TestFlight / Play 내부테스트

- [ ] Bundle ID / applicationId 확정 및 Apple/Google 등록
- [ ] 푸시 capability + APNs key
- [ ] 내부 테스터 그룹에 빌드 배포
- [ ] 약관·개인정보 인앱 링크 (`/terms`, `/privacy`)
- [ ] 신고 진입 (`/report`)
- [ ] 계정 삭제 경로 (스토어 필수)

## 스토어 프라이버시 / 데이팅 가이드

- [ ] App Privacy: 연락처·사진·식별자·사용 데이터 수집 고지
- [ ] 연령 제한 (17+ / 만 19+ 정책에 맞게)
- [ ] Dating 카테고리 가이드: 차단/신고, 안전 안내
- [ ] 푸시 권한 요청 전 한국어 설명 카피
- [ ] 스크린샷에 실명·전화·실사 민감 얼굴 노출 최소화
- [ ] 한국 광고성 푸시: 설정에서 수신 관리 가능 여부 명시

## 환경 변수 (wedding BFF)

- [ ] `FCM_PUSH_ENABLED=true` (스테이징 검증 후 prod)
- [ ] `FIREBASE_PROJECT_ID`
- [ ] `FIREBASE_SERVICE_ACCOUNT_JSON`
- [ ] Supabase `device_tokens` 마이그레이션 적용됨

## Cutover

- [ ] 웹 멤버 플로우에 앱 유도 배너 (선택)
- [ ] `FEED_WAIT_NOTICE` 원격 해제 절차 합의
- [ ] 베타 오픈 체크리스트 사인오프
