# cmdc-stack

Bu PC'deki MCP sunucularını ve skill'leri tek manifestten kuran, senkronlayan ve
denetleyen şemsiye repo. Repolar ayrı kalır; bu depo yalnızca **kurulum, kayıt,
senkron ve sağlık** işlerini üstlenir.

## Yeni makinede kurulum

```powershell
gh auth login                                        # private repolar icin
git clone https://github.com/ozbayenes123-ops/cmdc-stack.git
cd cmdc-stack
.\scripts\install.ps1                                # klon + uv sync + mcp.json + skill + smoke
```

Kurulum kökü varsayılanı manifestten gelir (`C:\dev\mcp`); farklı bir yere kurmak için:

```powershell
.\scripts\install.ps1 -Root "$env:USERPROFILE\mcp"
```

Deneme (hiçbir şey yazmaz): `.\scripts\install.ps1 -DryRun`

## Script'ler

| Script | Ne yapar |
|---|---|
| `scripts/install.ps1` | Ön koşul kontrolü → eksik repoları klonlar, var olanları `git pull --ff-only` ile günceller → `uv sync` → `mcp.json` kaydı → skill kurulumu → duman testi |
| `scripts/register-mcp.ps1` | `mcp.json`'u **merge** eder: yönetilen sunucular eklenir/güncellenir, diğerleri (chatcut, notion, …) korunur; her yazımda `.bak` alınır |
| `scripts/sync.ps1` | Her repoda `git fetch` + ahead/behind/kirli ağaç raporu; `-Pull` ile hızlı ileri sarar |
| `scripts/doctor.ps1` | Ortam ve bileşen sağlığı (araçlar, gh oturumu, dizinler, Zotero yerel API, skill hedefi); `-Smoke` ile MCP duman testi |

## Manifest

`stack.manifest.json` tek kaynaktır. Sunucu kayıtları:

| Alan | Anlamı |
|---|---|
| `kind` | `managed` (git deposu), `skills` (skill reposu), `external` (bizim klonlamadığımız, yalnızca kayıt/test edilen) |
| `dir` | Kurulum kökü altındaki klasör adı |
| `version` | Önerilen sürüm etiketi (denetim amaçlı) |
| `register` | `mcp.json`'a yazılsın mı |
| `command` / `args` / `env` | stdio sunucu tanımı |
| `sync` | Kurulum sonrası çalışacak komut (örn. `uv sync --project ${DIR}`) |
| `smoke.want` | Duman testinde beklenen tool isimleri |

Şablon değişkenleri: `${INSTALL_ROOT}`, `${DIR}` (sunucu klasörü), `${JAVA}` (`SHAMELA_JRE` veya `java`).

## Sunucular

**Yönetilen (bu repodan kurulur):** `bridge`, `makale`, `yargi`, `zotero`
(+ `commandcode-skills` skill reposu)

**Harici (klonlanmaz, varsa kaydedilir/test edilir):** `shamela`, `hyperframes-local`, `zotero-bin`
Kurulum ve kaynak bilgisi: `docs/third-party-mcps.md`

## Günlük akış

```powershell
.\scripts\sync.ps1          # GitHub ile karsilastir: esit / geride / ileride
.\scripts\sync.ps1 -Pull    # geride ve temiz olanlari guncelle
.\scripts\doctor.ps1 -Smoke # saglik + MCP duman testi
```

Yerelde değişiklik yaptıysanız: `git add -A; git commit; git push` (her repo kendi
deposudur). `sync.ps1` "ileride" derse commit/push bekleyen iş var demektir.

## Platform notları

- **Windows öncelikli.** Skill'lerden `isnad-word` / `isnad` Word COM (pywin32)
  kullanır; Word + Windows şarttır.
- `shamela` sunucusu Java (JDK) ve Shamela 4 kurulumu ister.
- `zotero` sunucusu Zotero masaüstü uygulamasının açık olmasını ister.

Ayrıntılar: `docs/prerequisites.md`, `docs/troubleshooting.md`.
