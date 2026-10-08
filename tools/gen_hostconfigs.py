# stack.manifest.json -> mcp/hostconfigs/ uretir (python tools/gen_hostconfigs.py)
import json, pathlib, sys
ROOT = r"C:\\dev\\mcp"
HERE = pathlib.Path(__file__).resolve().parent.parent
mf = json.loads((HERE / "stack.manifest.json").read_text(encoding="utf-8"))

def expand(v, d):
    return v.replace("${INSTALL_ROOT}", ROOT).replace("${DIR}", ROOT + "\\" + d).replace("${JAVA}", "java")

servers = []
for s in mf["servers"]:
    if not s.get("register"):
        continue
    servers.append({"name": s["name"], "dir": s["dir"],
                    "command": expand(s["command"], s["dir"]),
                    "args": [expand(a, s["dir"]) for a in s["args"]],
                    "env": {k: expand(v, s["dir"]) for k, v in s.get("env", {}).items()}})
servers.append({"name": "laya-router", "dir": "laya-router",
                "command": "uv", "args": ["run", "--project", ROOT + "\\laya-router", "laya-router"], "env": {}})

mcs = {s["name"]: {"command": s["command"], "args": s["args"], **({"env": s["env"]} if s["env"] else {})} for s in servers}
out = HERE / "mcp" / "hostconfigs"
out.mkdir(parents=True, exist_ok=True)
(out / "claude_desktop_config.json.example").write_text(json.dumps({"mcpServers": mcs}, ensure_ascii=False, indent=2), encoding="utf-8")

t = ["# Codex CLI: %USERPROFILE%\\.codex\\config.toml\n"]
for s in servers:
    t.append(f"[mcp_servers.{s['name']}]")
    t.append(f'command = "{s["command"]}"')
    t.append("args = [" + ", ".join(f'"{a}"' for a in s["args"]) + "]")
    if s["env"]:
        t.append(""); t.append(f"[mcp_servers.{s['name']}.env]")
        t += [f'{k} = "{v}"' for k, v in s["env"].items()]
    t.append("")
(out / "codex.config.toml.example").write_text("\n".join(t), encoding="utf-8")
print("uretildi:", out, "|", len(servers), "sunucu")
