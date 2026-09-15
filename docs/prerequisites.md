# Ön koşullar

Windows öncelikli kurulum. Aşağıdaki araçlar gerekir:

| Araç | Zorunlu | Neden | Kurulum |
|---|---|---|---|
| Git | Evet | Repoları klonlar | `winget install Git.Git` |
| GitHub CLI (`gh`) | Evet (private repolar) | Kimlik doğrulama + klon | `winget install GitHub.cli` sonra `gh auth login` |
| uv | Evet | Python projelerini çalıştırır (`uv sync`, `uv run`) | `winget install --id=astral-sh.uv` |
| Node.js 20+ | Önerilen | Shamela ve hyperframes sunucuları | `winget install OpenJS.NodeJS.LTS` |
| Java (JDK 21) | Shamela için | Shamela MCP Java motorunu çalıştırır | `winget install EclipseAdoptium.Temurin.21.JDK` |
| Zotero 7 masaüstü | Zotero skill/sunucuları için | Yerel API künye kaynağıdır | zotero.org |
| Microsoft Word | İsnad skill'leri için | COM ile dipnot/kaynakça eklenir | Office kurulumu |

> Paket kimlikleri değişebilir; emin değilseniz `winget search <ad>` ile doğrulayın.

Python ayrıca kurmanız gerekmez: `uv`, proje başına uygun Python sürümünü indirir.

## Zotero ayarı

Zotero → Ayarlar → Gelişmiş → **"Bu bilgisayardaki diğer uygulamaların Zotero ile
iletişim kurmasına izin ver"** seçeneği açık olmalı. Sunucular `ZOTERO_LOCAL=true`
ile yerel API'yi kullanır; ilk yazma işleminde Zotero bir kez yetki sorar.

## Shamela ayarı

`shamela` MCP, Shamela 4 kurulumunu ve bir JDK'yı bekler. Varsayılanlar:

- `SHAMELA_INSTALL_ROOT` → `C:\shamela4`
- `SHAMELA_JRE` → PATH'teki `java`; yoksa `C:\Program Files\Java\jdk-21\bin\java.exe`

Farklı bir kurulumunuz varsa `stack.manifest.json` içindeki `shamela` girdisinin
`env` alanını düzenleyin.

## Skill'ler için

`isnad`, `isnad-word` skill'leri **pywin32** ister:

```powershell
pip install pywin32
```

İSNAD CSL dosyaları (`isnad-dipnotlu.csl`, `isnad-metinici.csl`) ve örnek tablolar
`%USERPROFILE%\isnad-resources\` klasöründe beklenir; bu materyaller İSNAD projesine
aittir ve bu repolarda dağıtılmaz.
