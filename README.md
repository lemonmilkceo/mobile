# Bae & Lee — Member App (Flutter)

초대제 프라이빗 매칭 회원용 iOS/Android 앱.

- **Backend / Admin / Cron / FCM send:** [`wedding`](../wedding) Next.js BFF  
- **Auth / DB / Storage:** 공유 Supabase 프로젝트  
- **Firebase:** FCM 전용 (Auth/Firestore 미사용)

## Setup

```bash
cp lib/secrets.local.example.dart lib/secrets.local.dart
# SUPABASE_URL / ANON_KEY 채우기

flutter pub get
flutter run \
  --dart-define=API_BASE=https://privatematching.vercel.app
```

### FlutterFire / APNs (푸시)

1. Firebase Console에서 iOS/Android 앱 등록  
2. `dart pub global activate flutterfire_cli && flutterfire configure`  
3. APNs Auth Key (`.p8`)를 Firebase에 업로드  
4. `google-services.json` / `GoogleService-Info.plist` 배치  
5. 실행: `--dart-define=FCM_ENABLED=true`  
6. 로그인 후 `PUT /api/mobile/device-token`으로 토큰 등록되는지 확인  
7. wedding에 `FCM_PUSH_ENABLED=true` + `FIREBASE_SERVICE_ACCOUNT_JSON` 설정 후 테스트 발송

`FCM_ENABLED` 기본값은 `false`라 Firebase 파일 없이도 빌드·로그인·BFF 호출이 가능합니다.

### Deep links

- Android App Links / iOS Universal Links: `https://privatematching.vercel.app/match/*`  
- Host에 `/.well-known/assetlinks.json` · `apple-app-site-association` 배포 필요 (wedding 또는 Vercel)

## CI

GitHub Actions의 `Mobile E2E`는 Android 에뮬레이터와 iOS Simulator에서 mock 회원 여정을 실행합니다. 외부 Supabase·BFF 계정이나 키는 사용하지 않습니다.

로컬에서도 같은 검증을 실행할 수 있습니다.

```bash
test -f lib/secrets.local.dart || cp lib/secrets.local.example.dart lib/secrets.local.dart
flutter test integration_test/mock_member_journey_test.dart \
  -d <android-device-id> \
  --dart-define=MOCK_MODE=true
```

## Architecture

| 영역 | 경로 |
|------|------|
| Login / session | `supabase_flutter` 직결 |
| Signup / interest / inbox PII | BFF `/api/mobile/*` |
| Profile / photos / keywords | Supabase RLS |
| Push register | BFF device-token |

계약서: `../wedding/docs/mobile/BFF_API_CONTRACT.md`
