# ChatGPT (masaustu / web) baglantisi

ChatGPT, MCP'yi "Connectors" uzerinden **uzak** (Streamable HTTP/SSE) uc nokta olarak alir;
yerel stdio sunuculari dogrudan takilmaz. Iki yol:

1. **Connector (onerilen):** `mcp-proxy` gibi bir stdio->HTTP relay calistirin, ardindan
   ChatGPT > Settings > Connectors > Create/Advanced > MCP alanina relay URL'sini verin.
   Orn.: `mcp-proxy --transport streamable-http http://127.0.0.1:8732/mcp` (relay'i her
   sunucu icin ayri portla kurun; kurulum tek komuttur).
2. **Developer Mode (beta):** Settings > Connectors > Advanced > Developer mode aciksa
   `mcpServers` JSON'i yapisi aynen `claude_desktop_config.json.example` ile aynidir;
   o dosyayi icerigi yapistirabilirsiniz.

Not: makineye bagli sunucular (shamela/JRE, Zotero masaustu, ChatCut) yalnizca o makinede
calisir; uzak makineden kullanilacaksa relay + ag erisimi gerekir.
