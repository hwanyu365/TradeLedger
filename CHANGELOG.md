# TradeLedger Changelog

## [1.1.0] - 2026-11-15

### Changed
- 자동 메시지 채널에서 거래 채널을 뺌 → WoW 가 타이머로 보내는 공개 채널 메시지를 막아 전송되지 않았음.
- 이미 저장된 거래 채널 자동 메시지는 보내지 않고, 로드할 때 한 번 안내하며 설정 목록에 회색으로 표시.
- 거래 알림을 꺼도 장부 기록과 금액 기준 경고는 동작.
- 거래 완료·취소 결과를 본인 대화창에도 출력.
- 설정 초기화 확인 창이 거래 장부도 지워진다고 안내.
- 설정 제목·로드 안내의 버전을 TOC 에서 읽음.

### Fixed
- 꺼 둔 자동 메시지를 편집해 저장하면 켜지던 문제.
- 금액 기준 입력란에서 Esc 를 눌러도 고친 값이 저장되던 문제.

### Removed
- 시험 데이터 명령 `/tl testdata` (실제 장부·자동 메시지에 가짜 항목을 넣었음).
- 동작하지 않던 옛 `TradeAnnounceDB` 이관 코드.

## [1.0.2] - 2026-10-18

### Changed
- Interface 번호를 `120105` (Midnight 12.1.5) 으로 갱신.

## [1.0.1] - 2026-08-15

### Changed
- Interface 번호를 `120100` (Midnight 12.1) 으로 갱신.

## [1.0.0] - 2026-04-15

### Added
- Trade completion/cancellation announcements to chat channels
- Trade history ledger with up to 50 entries
- Auto message system with timer-based broadcasting
- Multi-channel support (Party, Raid, Guild, Whisper)
- Gold threshold filtering for announcements
- Settings panel with subcategories (Trade Alerts, Trade History, Auto Message)
- Korean (koKR) and English (enUS) localization
- Minimap icon via custom addon icon

### Changed
- Renamed from TradeAnnounce to TradeLedger
- Added MIT license
