local _, ns = ...
if GetLocale() ~= "koKR" then return end

local L = ns.L

-- Messages
L.TRADE_COMPLETE      = "%s 거래 완료"
L.TRADE_CANCEL        = "%s 거래 취소"
L.TRADE_REQUEST_FROM  = "%s님이 거래를 요청합니다"
L.SENT                = "보냄"
L.RECV                = "받음"
L.NOTHING             = "없음"
L.LOADED              = "v2.0.0 로드됨. /tl 로 설정 패널 열기"
L.HIGH_VALUE_TRADE    = "고액 거래: %s"

-- Settings UI - Tabs
L.TAB_TRADE_ALERTS    = "거래 알림"
L.TAB_AUTO_MESSAGE    = "자동 메시지"
L.TAB_HISTORY         = "거래 기록"

-- Trade Alerts
L.SUCCESS_ALERTS      = "거래 성공 알림"
L.CANCEL_ALERTS       = "거래 취소 알림"
L.WHISPER_CHANNEL     = "귓속말 (거래 상대)"
L.PARTY_CHANNEL       = "파티"
L.RAID_CHANNEL        = "공격대"
L.GUILD_CHANNEL       = "길드"
L.INCOMING_ALERTS     = "거래 요청 수신 알림"
L.GOLD_THRESHOLD      = "고액 거래 알림"
L.GOLD_UNIT           = "g"
L.BTN_1K              = "1천"
L.BTN_10K             = "1만"
L.BTN_100K            = "10만"
L.BTN_1M              = "100만"

-- Tooltips
L.SUCCESS_ALERTS_TIP  = "거래 성공 시 알림을 표시합니다."
L.CANCEL_ALERTS_TIP   = "거래 취소 시 알림을 표시합니다."
L.WHISPER_TIP         = "거래 결과를 거래 상대에게 귓속말로 보냅니다."
L.PARTY_TIP           = "거래 결과를 파티 채팅에 보냅니다."
L.RAID_TIP            = "거래 결과를 공격대 채팅에 보냅니다."
L.GUILD_TIP           = "거래 결과를 길드 채팅에 보냅니다."
L.INCOMING_TIP        = "다른 플레이어가 거래를 요청할 때 알림을 표시합니다."
L.GOLD_THRESHOLD_TIP  = "설정한 골드 이상의 거래가 성사되면 화면 중앙에 경고를 표시합니다."

-- History
L.HISTORY_TOGGLE      = "거래 이력 저장"
L.HISTORY_TIP         = "거래 이력을 저장합니다. 거래 기록 탭에서 조회."
L.HISTORY_CLEAR_BTN   = "초기화"
L.HISTORY_CLEAR_CONFIRM = "모든 거래 이력을 삭제하시겠습니까?"
L.HISTORY_COL_TIME    = "시간"
L.HISTORY_COL_STATUS  = "상태"
L.HISTORY_COL_PARTNER = "플레이어"
L.HISTORY_NO_ENTRIES  = "기록된 거래 이력이 없습니다."
L.HISTORY_NO_SELECTION = "거래 기록을 클릭하면 상세 정보가 표시됩니다."
L.HISTORY_OK          = "성공"
L.HISTORY_FAIL        = "취소"
L.HISTORY_CLEARED     = "거래 이력이 삭제되었습니다."
L.NO_HISTORY          = "거래 이력이 없습니다."

-- Auto Message
L.AUTO_MSG_ADD            = "추가"
L.AUTO_MSG_EDIT           = "편집"
L.AUTO_MSG_DELETE         = "삭제"
L.AUTO_MSG_CHANNEL        = "채널"
L.AUTO_MSG_INTERVAL       = "주기"
L.AUTO_MSG_MESSAGE        = "메시지"
L.AUTO_MSG_ACTIONS        = "동작"
L.AUTO_MSG_CONFIRM        = "확인"
L.AUTO_MSG_CANCEL         = "취소"
L.AUTO_MSG_NO_ENTRIES     = "설정된 자동 메시지가 없습니다."
L.AUTO_MSG_CH_TRADE       = "거래"
L.AUTO_MSG_CH_WHISPER     = "귓속말"
L.AUTO_MSG_CH_PARTY       = "파티"
L.AUTO_MSG_CH_RAID        = "공격대"
L.AUTO_MSG_CH_GUILD       = "길드"
L.AUTO_MSG_WHISPER_TARGET = "귓속말 대상"
L.AUTO_MSG_ENABLED        = "활성화"
L.AUTO_MSG_SEC            = "%d초"
L.AUTO_MSG_ON             = "활성"
L.AUTO_MSG_OFF            = "비활성"

-- Settings Reset
L.SETTINGS_RESET          = "모든 설정이 초기화되었습니다."
L.SETTINGS_RESET_BTN      = "설정 초기화"
L.SETTINGS_RESET_CONFIRM  = "모든 TradeLedger 설정을 초기화하시겠습니까?\n\n자동 메시지 설정 등 모든 설정이 기본값으로 복원됩니다."
