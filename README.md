# TradeLedger

Trade completion/cancellation announcements and trade history ledger for World of Warcraft.

## Features

- **Trade Alerts**: Automatically announce trade results to Party, Raid, Guild, or Whisper channels
- **Trade History**: Keep a ledger of up to 50 recent trades with details. Entries older than 7 days are removed when the addon loads
- **Auto Message**: Send saved messages at a set interval to Guild, Party, Raid, or Whisper. The Trade channel is not supported because WoW blocks messages an addon sends there without a key press
- **High-Value Alert**: Show an on-screen warning when either side of a completed trade reaches a set gold amount
- **Localization**: English and Korean supported

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/tradeledger)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`

## Usage

- `/tl` or `/tradeledger` — Open settings panel
- `/tl add` — Add a new auto message

## Requirements

- World of Warcraft: Midnight (12.0.0+)
- Interface: 120105

## License

[MIT](LICENSE)
