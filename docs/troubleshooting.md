# Sorun giderme

## `uv sync` sırasında "dosya başka bir işlem tarafından kullanılıyor"

Çalışan bir MCP sunucusu (örneğin `bridge`) kendi `Scripts\*.exe` dosyasını kilitler.
Çözüm: Command Code oturumunu kapatıp `install.ps1`/`uv sync` çalıştırın, ya da
doğrulamayı sanal ortam Python'u ile yapın:

```powershell
& "<kurulum kökü>\bridge-mcp\.venv\Scripts\python.exe" -c "import bridge_mcp; print(bridge_mcp.__version__)"
```

## Türkçe karakterler konsolda bozuluyor (cp1254)

Python betiklerinin çıktısını UTF-8'e sabitleyin:

```powershell
$env:PYTHONIOENCODING = 'utf-8'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
```

`isnad_word.py` çıktısını dosyaya yazıp `read_file` ile okumak da güvenli yoldur.

## `pyproject.toml` derleme hatası: "Invalid statement (at line 1, column 1)"

PowerShell 5.1'in `Set-Content -Encoding UTF8` komutu BOM ekler; hatchling/TOML BOM
kabul etmez. Dosyaları BOM'suz yazın:

```powershell
[System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
```

## Shamela başlamıyor

- `java` PATH'te değilse `SHAMELA_JRE` ortam değişkenini tam yolla verin.
- `SHAMELA_INSTALL_ROOT` altında Shamela 4 kurulumu yoksa sunucu açılmaz; `doctor.ps1`
  bu dizini raporlar.

## Private repo klonu başarısız

`gh auth login` yapılmamış ya da token süresi dolmuş olabilir:

```powershell
gh auth status
gh auth login
```

## Bedesten (yargi) rate limit

`yargi` sunucusu ve `bridge` aynı IP'den paralel istek atarsa bütçe paylaşılır.
`BEDESTEN_RATE_*` ortam değişkenleriyle istek hızını düşürün (bkz. `yargi-mcp` README).

## Zotero yazma izni

İlk yazma işleminde Zotero yetki penceresi açar; reddedilirse yazma araçları hata
döndürür. Zotero açık ve kütüphane salt-okunur olmamalıdır.
