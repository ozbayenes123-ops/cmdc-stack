# hostconfigs — diger uygulamalara hazir kurulum

`claude_desktop_config.json.example`, `codex.config.toml.example` ve `CHATGPT.md` dosyalari
`../../stack.manifest.json`'dan uretilmistir (kaynak: `../tools/gen_hostconfigs.py`).
Manifest degisince `python ../tools/gen_hostconfigs.py` ile yenileyin.

| Uygulama | Dosya nereye? |
|---|---|
| Claude Desktop | `%APPDATA%\Claude\claude_desktop_config.json` (icerigi bu JSON ile degistir/birlestir) |
| Codex CLI | `%USERPROFILE%\.codex\config.toml` (satirlari ekleyin) |
| ChatGPT | `CHATGPT.md`'ye bakin (connector/Developer Mode) |
| Hermes / CommandCode | `../../mcp/mcp.json.example` + `scripts/register-mcp.ps1` |

Her MCP deposunun kokunde tek sunuculuk `COMPAT.md` da vardir (yalniz o sunucu lazimsa ordan al).
