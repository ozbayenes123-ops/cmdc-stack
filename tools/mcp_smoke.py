"""MCP duman testi: manifestteki her sunucuya initialize + tools/list gonderir.

Kullanim:
    python tools/mcp_smoke.py [sunucu ...]
    python tools/mcp_smoke.py --manifest <yol> --root <kurulum koku>

Manifestte "smoke" alani olan ve dizini var olan sunucular denenir. Beklenen
tool isimleri ("want") eksikse sonuc ok=false olur.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

INIT = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "smoke", "version": "1.0"},
    },
}
NOTIF = {"jsonrpc": "2.0", "method": "notifications/initialized"}
LIST = {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}


def expand(value, tokens):
    if isinstance(value, str):
        for key, token in tokens.items():
            value = value.replace(key, token)
        return value
    if isinstance(value, list):
        return [expand(item, tokens) for item in value]
    if isinstance(value, dict):
        return {key: expand(item, tokens) for key, item in value.items()}
    return value


def test_one(name, spec, command, args, env_extra, want, timeout=40):
    env = dict(os.environ)
    env.update({k: str(v) for k, v in env_extra.items() if v})
    try:
        proc = subprocess.Popen(
            [command, *args],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            text=True,
            bufsize=1,
            encoding="utf-8",
            errors="replace",
        )
    except Exception as exc:  # spawn hatasi
        return {"server": name, "ok": False, "stage": "spawn", "error": str(exc)}

    try:
        def send(payload):
            proc.stdin.write(json.dumps(payload) + "\n")
            proc.stdin.flush()

        def recv():
            line = proc.stdout.readline()
            return json.loads(line) if line.strip() else {}

        send(INIT)
        init = recv()
        send(NOTIF)
        send(LIST)
        tools = recv()
        names = [t.get("name") for t in tools.get("result", {}).get("tools", [])]
        missing = [w for w in want if w not in names]
        return {
            "server": name,
            "ok": not missing,
            "protocol": init.get("result", {}).get("protocolVersion"),
            "tools": len(names),
            "missing": missing,
            "sample": names[:8],
        }
    except Exception as exc:  # rpc hatasi
        err = ""
        try:
            _, err = proc.communicate(timeout=2)
        except Exception:
            pass
        return {
            "server": name,
            "ok": False,
            "stage": "rpc",
            "error": str(exc)[:300],
            "stderr": (err or "")[:500],
        }
    finally:
        try:
            proc.kill()
        except Exception:
            pass


def load_manifest(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def main(argv=None):
    parser = argparse.ArgumentParser(description="MCP stdio duman testi")
    parser.add_argument("servers", nargs="*", help="yalnizca bu sunucular (varsayilan: hepsi)")
    parser.add_argument(
        "--manifest",
        default=str(Path(__file__).resolve().parents[1] / "stack.manifest.json"),
    )
    parser.add_argument("--root", default="", help="kurulum koku (manifest degerini ezer)")
    args = parser.parse_args(argv)

    manifest = load_manifest(args.manifest)
    root = args.root or manifest.get("installRoot", "")
    root_path = Path(root)
    java = os.environ.get("SHAMELA_JRE", "java")

    results = []
    for server in manifest.get("servers", []):
        name = server["name"]
        if args.servers and name not in args.servers:
            continue
        smoke = server.get("smoke")
        if not smoke:
            continue
        server_dir = root_path / server["dir"]
        if not server_dir.exists():
            results.append({"server": name, "ok": False, "stage": "missing", "path": str(server_dir)})
            continue
        tokens = {"${DIR}": str(server_dir), "${INSTALL_ROOT}": root, "${JAVA}": java}
        command = expand(server["command"], tokens)
        argv_list = expand(server.get("smokeArgs", server.get("args", [])), tokens)
        env_extra = expand(server.get("env", {}), tokens)
        results.append(
            test_one(name, server, command, argv_list, env_extra, smoke.get("want", []))
        )

    for result in results:
        print(json.dumps(result, ensure_ascii=False))
    return 0 if all(item["ok"] for item in results) else 1


if __name__ == "__main__":
    sys.exit(main())
