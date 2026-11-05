import html, json, os, subprocess, sys, time, urllib.error, urllib.request
from datetime import datetime, timezone

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CSS = """body{margin:0;background:#f4f5f7;font:13px/1.45 -apple-system,Segoe UI,Roboto,sans-serif;color:#172b4d}
.w{width:1100px;padding:20px}.h{background:#fff;border:1px solid #dfe1e6;border-radius:8px;padding:14px 18px;margin-bottom:12px}
h1{font-size:17px;margin:0 0 4px}.sub{color:#5e6c84;font-size:12px}.tag{display:inline-block;padding:2px 8px;border-radius:4px;font-weight:600;font-size:12px;margin-right:6px}
.ok{background:#e3fcef;color:#006644}.fail{background:#ffebe6;color:#bf2600}.info{background:#deebff;color:#0747a6}.warn{background:#fffae6;color:#974f0c}
pre{font:12px/1.4 SFMono-Regular,Menlo,monospace;background:#091e42;color:#e6edf7;padding:10px;border-radius:6px;white-space:pre-wrap;word-break:break-all;margin:6px 0 0}"""


def call(url, headers=None):
    req = urllib.request.Request(url, headers=headers or {})
    t0 = time.time()
    try:
        r = urllib.request.urlopen(req, timeout=60)
        code, body, hdrs = r.status, r.read(), dict(r.headers)
    except urllib.error.HTTPError as e:
        code, body, hdrs = e.code, e.read(), dict(e.headers)
    ms = int((time.time() - t0) * 1000)
    try:
        data = json.loads(body) if body else None
    except Exception:
        data = body.decode(errors="replace")[:2000]
    return {"url": url, "at": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"), "status": code, "ms": ms,
            "headers": {k: v for k, v in hdrs.items() if k.lower() in ("date", "age", "x-cache", "cache-control", "content-type", "via")},
            "body": data}


def render(path_png, title, verdict, note, calls):
    tag = {"ok": "ok", "fail": "fail", "warn": "warn"}.get(verdict, "info")
    blocks = []
    for c in calls:
        body = json.dumps(c["body"], ensure_ascii=False, indent=1) if not isinstance(c["body"], str) else c["body"]
        blocks.append(f"<div class=h><b>GET</b> <span class=sub>{html.escape(c['url'])}</span><div class=sub>{c['at']} · HTTP {c['status']} · {c['ms']} ms</div>"
                      f"<pre>{html.escape(json.dumps(c['headers'], ensure_ascii=False))}</pre><pre>{html.escape(body[:2500])}</pre></div>")
    doc = f"<!doctype html><meta charset=utf-8><style>{CSS}</style><div class=w><div class=h><span class='tag {tag}'>{verdict.upper()}</span><h1>{html.escape(title)}</h1><div class=sub>{html.escape(note)}</div></div>{''.join(blocks)}</div>"
    hp = path_png[:-4] + ".html"
    open(hp, "w").write(doc)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--window-size=1140,1600", f"--screenshot={path_png}", f"file://{hp}"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=60)


if __name__ == "__main__":
    spec = json.load(open(sys.argv[1]))
    out_dir = sys.argv[2]
    calls = []
    for u in spec["urls"]:
        calls.append(call(u, spec.get("headers")))
        if spec.get("sleep_s"):
            time.sleep(spec["sleep_s"])
    name = spec["name"]
    json.dump({"spec": spec, "calls": calls}, open(os.path.join(out_dir, "cenarios", name + ".json"), "w"), ensure_ascii=False, indent=1)
    print(json.dumps([{k: c[k] for k in ("status", "ms", "headers")} for c in calls], ensure_ascii=False))
