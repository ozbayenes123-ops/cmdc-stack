# Harici MCP sunucuları

Bu sunucular bizim repolarımız değildir; `cmdc-stack` onları **klonlamaz**. Dizinleri
kurulum kökünde varsa `mcp.json`'a kaydedilir ve duman testi denenir, yoksa atlanır.

## shamela (`shamela-mcp`)

- Kaynak: `alhoqbani/shamela-mcp` (MCPB paketi / kaynak)
- Çalıştırma: `node <kurulum kökü>\shamela-mcp\dist\index.js`
- Gereksinimler: Shamela 4 kurulumu + JDK (bkz. `prerequisites.md`)
- Kaydı `bridge` sunucusu da kullanır (`SHAMELA_ENTRY` ile yolu değiştirilebilir)

## hyperframes-local (`hyperframes-mcp`)

- `npm` paketi `hyperframes`'in ince sarmalayıcısıdır (`index.mjs`)
- Paket sürümü `npm view hyperframes version` ile denetlenir; güncelleme:
  `npm update hyperframes` (sarmalayıcı dizininde)

## zotero-bin (`zotero-bin`)

- `uv` + derlenmiş `zotero-mcp.exe` içeren ikili klasör (git deposu değil)
- Kaynağı `zotero-mcp-src` reposudur; tercih edilen çalıştırma yolu `uv run --project`
- Yeni bir makinede gerek yoktur; `zotero` sunucusunu kaynak repodan çalıştırın

## chatcut

- Kurulu ChatCut uygulamasının kendi MCP sunucusu (Electron `server.js`)
- Yolu uygulama kurulumuna bağlıdır; `cmdc-stack` yönetmez, `mcp.json`'daki mevcut
  kayıt korunur

## notion

- Uzak HTTP MCP: `https://mcp.notion.com/mcp`
- Yerel kurulum gerektirmez; OAuth akışı istemci tarafında yürütülür
