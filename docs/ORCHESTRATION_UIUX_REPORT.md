# Orchestration Report — Flutter vs Web UI/UX + Prototype Mode

Date: 2026-08-10  
Web: https://privatematching.vercel.app  
App: `/Users/hslee/orca/projects/baeandlee-app`  
Method: Ultrawork-style parallel Cursor agents (`explore` ×2, `designer`, `qa-tester`) + parent synthesis + implementation

---

## 1. Why the app looked green / ivory

**Root cause (code):** `lib/theme.dart` was authored with a “quiet editorial” palette intentionally avoiding common AI defaults:

| App (old) | Hex | Intent at scaffold time |
|-----------|-----|-------------------------|
| `sage` | `#3D5A4C` | primary / buttons |
| `paper` | `#F7F4F0` | ivory scaffold |
| `sageSoft` | `#D8E3DC` | nav indicator |

**Web brand (source of truth):** `wedding/src/app/globals.css`

| Token | Hex | Role |
|-------|-----|------|
| `--background` | `#ffffff` | page |
| `--ink` / `--foreground` | `#111111` | text / primary CTA |
| `--brand` | `#a24b5a` | rose accent (eyebrow, soft chips) |
| `--panel` | `#f7f7f7` | soft gray panels |
| `--line` | `#ebebeb` | borders |

The green/ivory choice was **not** from the web design system — it was a scaffold bias that conflicted with Bae & Lee’s black/white + muted rose identity.

**Fix applied:** `AppTheme` remapped to web tokens; primary CTA = ink black; brand rose for eyebrows / prototype banner.

---

## 2. Entry flow gap

| | Web | App (before) | App (after) |
|--|-----|--------------|-------------|
| Cold start | Landing `/` — brand hero, philosophy, flow, founders | `AuthScreen` login immediately | `OnboardingScreen` (3 pages) → auth |
| CTA | 초대 코드로 시작 / 로그인 | 로그인 / 가입 토글 | 동일 + **프로토타입 둘러보기** |
| Guest browse | Public landing content | None | Mock mode with banner |

---

## 3. UI/UX differences observed

1. **Color:** App sage/ivory vs web white/ink/rose → **fixed**
2. **Onboarding:** Missing web narrative (Invite only, why, 3 steps) → **fixed**
3. **Wait notice:** Both can show wait state; app now mirrors copy path; mock can toggle `MOCK_FEED_WAIT_NOTICE`
4. **Nav:** App bottom 3-tab (소개 / 받은 소개 / 내 정보) vs web header + bottom for logged-in — acceptable native IA
5. **Typography:** Web Pretendard; app Noto Sans KR — close enough; optional later align
6. **Alimtalk copy on web flow still says 알림톡** while app is push-first — product copy debt on web (P2)

---

## 4. Mock / prototype mode (implemented)

- Onboarding CTA: **프로토타입 둘러보기 (mock)**
- Or `--dart-define=MOCK_MODE=true`
- Corner banner: `프로토타입`
- Mock feed candidates, inbox, accept/reject simulation, settings profile
- Feed wait: `--dart-define=MOCK_FEED_WAIT_NOTICE=true` to preview notice

Test accounts (real login) remain:

| Role | Email | Password |
|------|-------|----------|
| Female | test.female@baeandlee.local | TestFemale!2026 |
| Male | test.male@baeandlee.local | TestMale!2026 |

---

## 5. E2E scenarios (post-fix)

1. Cold start → onboarding pages → 로그인 → auth (black CTA)
2. 프로토타입 둘러보기 → banner → 소개 탭 후보 목록 → 상세 → 소개 요청 snackbar
3. 받은 소개 → offered → 수락 → contact mock shown
4. Real login with test.male / test.female
5. Visual: scaffold white, buttons black, brand rose eyebrow on onboarding

Devices available at verify time: iPhone 17 sim (verified cold start → onboarding after uninstall). Android AVD (`ghostshark_pixel`) is intermittently dropping from `adb` in this agent environment — rebuild succeeded earlier today; re-run locally with emulator window focused if needed.

---

## 6. Modification plan (remaining)

### P0 (done in this wave)
- [x] Theme align to web tokens
- [x] Onboarding before auth
- [x] Mock prototype path

### P1
- [ ] Profile wizard parity with web keyword topics / visibility toggles
- [ ] Female guide screen parity when wait notice off
- [ ] Clear onboarding prefs reset in settings (debug)
- [ ] Store screenshots using mock mode

### P2
- [ ] Web copy: 알림톡 → 앱 푸시 병행 문구
- [ ] Pretendard bundling in Flutter
- [ ] Shared design tokens package / JSON export from `globals.css`

---

## 7. Agent lanes

| Lane | Agent | Focus |
|------|-------|-------|
| Web inventory | explore | tokens, onboarding routes |
| Flutter inventory | explore | theme, auth-first gap |
| Design | designer | target tokens, IA, mock UX |
| QA | qa-tester | devices, web fetch, scenario list |
| Parent | synthesis + implementation | theme, onboarding, mock, this report |

---

## 8. How to run prototype

```bash
cd /Users/hslee/orca/projects/baeandlee-app
# Clear onboarding once if needed:
# flutter: delete app or clear SharedPreferences key onboarding_done_v1

flutter run -d <device> --dart-define=API_BASE=https://privatematching.vercel.app
# or force mock:
flutter run -d <device> --dart-define=MOCK_MODE=true
```
