# 설정·초기화·명령 스펙

## 1. 개요

| 항목 | 값 |
| --- | --- |
| 문서명 | spec_settings |
| 작성일 / 최종 수정일 | 2026-11-14 / 2026-11-15 |
| 버전 | 1.0 |
| 기준 커밋 ID | 935fad9 |

- **기능명:** 설정 패널, 설정 초기화, 슬래시 명령, 저장 데이터 형식 (UC4)
- **목적 (Why):** 알림 채널·금액 기준·장부·자동 메시지를 사용자가 정하고, 처음 상태로 되돌릴 수 있게 한다.

## 2. 목표 및 범위

### In Scope

- WoW 설정 창의 TradeLedger 패널(첫 화면 + 하위 3개), 거래 알림 설정, 설정 초기화, `/tl` 명령
- `TradeLedgerDB` 형식과 로드 규칙 (색인 NFR#1~NFR#5 의 TC)

### Out of Scope

- 장부 패널·자동 메시지 패널의 내용 → `spec_trade_history.md` FR#13, `spec_auto_message.md` FR#16

## 3. 요구사항

### 3.1 사용자 스토리

- `US#4` [as-built] 애드온을 쓰는 플레이어로서, 내 거래 방식에 맞추기 위해, 알림·장부·자동 메시지를 설정하고 필요하면 초기화하고 싶다 → FR#18~FR#21

### 3.2 기능 요구사항

- `FR#18` [as-built] 로드할 때 WoW 설정 창에 TradeLedger 를 등록한다: 첫 화면(제목·설명·설정 초기화 버튼) + 하위 패널 3개(enUS `Trade Alerts`·`Trade History`·`Auto Message`, koKR 은 로케일 문구).
  - 첫 화면 제목은 `TradeLedger v{버전}`, 설명은 애드온 설명 문구(TOC `## Notes` 와 같은 뜻)다. 버전은 TOC `## Version` 을 읽는다 (NFR#5).
- `FR#19` [as-built] [거래 알림] 패널: 각 항목을 바꾸는 즉시 저장한다. 패널을 열 때 저장된 값으로 다시 그린다.
  - 체크박스: 완료 알림, 그 아래 채널 4개(귓속말·파티·공격대·길드), 취소 알림, 거래 요청 알림, 금액 경고
  - 금액 기준(골드): 숫자만 입력, 0~10,000,000, 넘게 입력하면 바로 상한으로 바꾼다. Enter·초점 해제 시 저장한다. Esc 는 입력을 버리고 저장된 값을 유지한다. 표시할 때는 천 단위 쉼표를 붙인다.
  - ±1K·10K·100K·1M 버튼: 더하거나 빼고 0~10,000,000 범위로 맞춘다.
- `FR#20` [as-built] [설정 초기화] → 확인 대화상자 → 확인 시 자동 메시지를 모두 멈추고, `TradeLedgerDB` 전체(설정·장부·자동 메시지)를 기본값으로 되돌리고, 안내를 출력한다.
  - 확인 대화상자와 완료 안내는 설정뿐 아니라 자동 메시지와 거래 장부도 지워진다는 것을 알린다 → 되돌릴 수 없는 삭제를 모르고 확인하지 않게 한다.
- `FR#21` [as-built] 슬래시 명령 `/tl`, `/tradeledger` (인자는 대소문자 무시)

  | 입력 | 동작 |
  | --- | --- |
  | 인자 없음, 그 밖의 인자 (`testdata` 포함) | 설정 창의 TradeLedger 첫 화면 |
  | `add` | 자동 메시지 추가 대화상자 (`spec_auto_message.md` FR#17) |

## 4. 데이터 및 API 스펙

`TradeLedgerDB` 기본값 (색인 NFR#1·NFR#2)

| 키 | 형식 | 기본 | 스펙 |
| --- | --- | --- | --- |
| `channels.WHISPER` / `PARTY` / `RAID` / `GUILD` | boolean | true / false / false / false | `spec_trade_alert.md` FR#5 |
| `announceSuccess` / `announceCancel` | boolean | true / true | `spec_trade_alert.md` FR#3·FR#4 |
| `announceIncoming` | boolean | false | `spec_trade_alert.md` FR#8 |
| `goldThresholdEnabled` / `goldThreshold` | boolean / number(골드) | false / 1000 | `spec_trade_alert.md` FR#7 |
| `autoMessages` | 목록 | 빈 목록 | `spec_auto_message.md` §4 |
| `history` | 표 | `{ enabled = true, maxEntries = 50, entries = {} }` | `spec_trade_history.md` §4 |

- `ns:InitDB()`: 로드 규칙(NFR#2) 적용 후 `ns.db = TradeLedgerDB`
- `ns:ResetDB()`: 같은 표를 비우고 기본값을 채운다 → `ns.db` 와 전역이 같은 표를 계속 가리킨다

## 6. 동작 로직 및 정책

### 6.1 설계 결정

| 결정 | 선택 | 기각한 대안 | 근거 |
| --- | --- | --- | --- |
| `D#8` | 설정 패널 등록을 오류 보호 안에서 한다 | 다른 초기화와 같이 바로 호출 | 설정 창 API 가 바뀌어 패널이 실패해도 알림·장부·자동 메시지는 동작한다 [NFR#5] |
| `D#9` | 초기화는 새 표를 만들지 않고 같은 표를 비운다 | `TradeLedgerDB = {}` 로 교체 | 다른 파일이 쥔 `ns.db` 참조가 그대로 유효하다 [FR#20] |

## 7. 테스트 및 검증 기준

| TC | 시나리오 | 대상 | 비고 |
| --- | --- | --- | --- |
| `TC#1` | TOC 의 SavedVariables 가 `TradeLedgerDB`, 로드 뒤 `ns.db` 와 전역이 같은 표 | [NFR#1] | `Core/Config.test.lua` |
| `TC#2` | 빈 DB → §4 표의 기본값, 부분 DB → 없는 키만 채움(중첩)·있는 값·모르는 키 유지·`SAY`·`PRINT` 삭제 | [NFR#2] | `Core/Config.test.lua` |
| `TC#3` | `TradeAnnounceDB` 만 있어도 새 기본값 DB 를 만들고 옛 전역은 그대로, 둘 다 있으면 `TradeLedgerDB` 사용 | [NFR#3] | `Core/Config.test.lua` |
| `TC#4` | enUS·그 밖 언어 → 영어, koKR → 한국어, 두 로케일 키 집합 같음 | [NFR#4] | `Locale/koKR.test.lua` |
| `TC#5` | 다른 애드온의 ADDON_LOADED 무시, 자기 것에서 초기화·TOC 버전이 든 로드 안내·설정 제목·이벤트 해제, TOC 에 `## Version: X.Y.Z` 가 있음, 패널 실패 시 오류 출력 후 장부 정리·자동 메시지 시작·로드 안내 | [NFR#5, D#8] | `Core/Trade.test.lua` |
| `TC#25` | 설정 창에 첫 화면(제목의 버전이 애드온 목록의 버전과 같음, 애드온 설명)과 하위 3개 패널이 보이고 `/tl` 로 열림 | [FR#18] | (수동) 게임 내 |
| `TC#26` | 체크박스 즉시 저장·`/reload` 후 유지, 쉼표 표시, ± 버튼 범위 | [FR#19] | (수동) 게임 내 → 쉼표·± 버튼은 #16 에서 자동 테스트로 |
| `TC#32` | 금액 입력: Enter·초점 해제 → 입력값 저장, 상한 넘는 입력 → 10,000,000 으로 바꿔 저장, Esc → 입력을 버리고 저장된 값 유지·입력란 닫힘 | [FR#19] | `UI/Settings.test.lua` |
| `TC#27` | 초기화 후 같은 표가 기본값(장부·자동 메시지 비움) | [FR#20, D#9] | `Core/Config.test.lua` |
| `TC#31` | 초기화 확인·완료 문구가 enUS·koKR 모두 자동 메시지와 거래 장부를 언급 | [FR#20] | `Locale/koKR.test.lua` |
| `TC#28` | [설정 초기화] 확인 대화상자, 확인 시 자동 메시지 전송이 멈추고 패널 값이 기본값 | [FR#20] | (수동) 게임 내 |
| `TC#29` | `/tl`·`/tradeledger` 등록, 빈·모르는 인자 → 설정 창, `ADD` → 추가 대화상자, `testdata N` → 설정 창이며 장부·자동 메시지를 바꾸지 않음 | [FR#21] | `Core/Trade.test.lua` |

## 부록. 변경 이력

- GH-12: as-built 스펙 작성
- GH-22: 배포본의 시험 데이터 명령 `testdata` 제거
- GH-27: 초기화 확인·완료 문구가 장부 삭제를 알림
- GH-26: 설정 제목·로드 안내의 버전을 TOC 에서 읽음, 첫 화면 설명을 애드온 설명으로
- GH-40: 금액 기준 입력란의 Esc 가 입력을 버림
