# 실사용 설정 체크리스트 (Flutter 앱)

앱은 **Supabase(회원·프로필)** + **Vercel BFF(`/api/mobile/*`)** + **(선택) Firebase FCM(푸시)** 구조입니다.

---

## 1. Supabase (필수)

이미 웹과 같은 프로젝트를 쓰면 추가 프로젝트는 필요 없습니다.

1. **Dashboard → Project Settings → API**
   - Project URL → 앱 `SUPABASE_URL` / `secrets.local.dart`
   - `anon` `public` key → `SUPABASE_ANON_KEY`
2. **Auth**
   - Email/Password 로그인 활성화
   - (스토어용) 리다이렉트·딥링크 도메인 등록
3. **Tables / RLS**
   - `profiles`, `profile_private`, `profile_photos`, `profile_keywords`, `interest_requests`, `device_tokens` 등 웹과 동일
   - 모바일도 **anon + 유저 JWT**로 RLS 직결 (프로필/사진)
4. **Storage**
   - 버킷 `profile-photos` (웹과 동일 정책)
5. **테스트 계정**
   - `wedding/docs/mobile/TEST_ACCOUNTS.md` 시드 계정으로 로그인 검증

앱 실행 예:

```bash
cd baeandlee-app
flutter run -d <device> \
  --dart-define=API_BASE=https://privatematching.vercel.app
# MOCK_MODE 넣지 않음 = 실데이터
```

`lib/secrets.local.dart`에 URL/anon이 있으면 dart-define 없이도 기본값으로 동작합니다.

---

## 2. Vercel / BFF (필수 — 소개·가입·인박스)

1. **wedding 재배포** (현재 P0)
   - 로컬 `middleware`가 `/api/*`를 `/invite`로 보내지 않도록 수정됨
   - prod가 아직 307이면 앱 실로그인 후 health/inbox/interest/signup 실패
2. 배포 후 확인:

```bash
curl -s https://privatematching.vercel.app/api/mobile/health
# → JSON { ok: true, feedWaitNotice, pushEnabled }
```

3. Vercel 환경변수 (wedding `.env.local.example` 참고)
   - `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `CRON_SECRET`
   - (푸시 켤 때) 아래 Firebase 서버 키

로그인:

```
npx vercel login
cd wedding && npx vercel deploy --prod --yes
```

---

## 3. Firebase (푸시만 — 선택, 스토어 전에는 꺼도 됨)

회원 DB는 Firebase가 아닙니다. **FCM 푸시 전용**입니다.

### 서버 (wedding / Vercel)

1. Firebase Console에서 프로젝트 생성 (또는 기존)
2. 서비스 계정 JSON 발급
3. Vercel env:
   - `FCM_PUSH_ENABLED=true`
   - `FIREBASE_PROJECT_ID=...`
   - `FIREBASE_SERVICE_ACCOUNT_JSON={...전체 JSON 문자열...}`

### 클라이언트 (baeandlee-app)

1. `flutterfire configure` (iOS/Android 앱 등록)
2. `firebase_core` + `firebase_messaging` 의존성 추가
3. `PushService` 실배선 (현재는 stub)
4. 실행 시 `--dart-define=FCM_ENABLED=true`
5. iOS: APNs 키를 Firebase에 연결, Xcode Push capability
6. Android: `google-services.json`, 알림 권한(Android 13+)

토큰은 로그인 후 `PUT /api/mobile/device-token`으로 BFF에 등록됩니다.

---

## 4. 앱 스토어 / 딥링크

- Android: `assetlinks.json` (wedding `public/.well-known`)
- iOS: `apple-app-site-association` + Team ID / bundle id 맞추기
- Host: `privatematching.vercel.app` (`DEEP_LINK_HOST`)

---

## 5. 당장 최소로 “실앱” 쓰려면

| 순서 | 할 일 |
|------|--------|
| 1 | Supabase URL/anon이 앱에 맞는지 확인 (이미 웹과 동일하면 OK) |
| 2 | **wedding prod 재배포** (middleware) → health 200 |
| 3 | `MOCK_MODE` 없이 `flutter run` + 테스트 계정 로그인 |
| 4 | 푸시는 나중에 Firebase + `FCM_*` |

알림톡(Solapi)은 업종 이슈로 막혀 있으면 `SOLAPI_ALIMTALK_ENABLED=false` 유지하고 FCM만 쓰면 됩니다.
