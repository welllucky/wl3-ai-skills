import http.server, json, os, ssl, sys, time, urllib.error, urllib.parse, urllib.request
from datetime import datetime, timedelta, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.environ.get("QA_PROXY_STATE", os.path.join(HERE, "proxy-state.json"))
LOG = os.environ.get("QA_PROXY_LOG", os.path.join(HERE, "proxy-calls.jsonl"))
UPSTREAM = os.environ.get("QA_PROXY_UPSTREAM", "").rstrip("/")
PORT = int(os.environ.get("QA_PROXY_PORT", "5199"))
CTX = ssl.create_default_context()
MEMO = {}


def load_state():
    try:
        st = json.load(open(STATE))
        st["_mtime"] = os.path.getmtime(STATE)
        return st
    except FileNotFoundError:
        return {"rules": [], "_mtime": 0}


def iso(dt):
    return dt.astimezone(timezone.utc).isoformat(timespec="seconds")


def fixed_deadline(key, mtime, seconds):
    k = (key, mtime)
    if k not in MEMO:
        MEMO[k] = datetime.now(timezone.utc) + timedelta(seconds=seconds)
    return MEMO[k]


def match(rule, path, query):
    if not path.startswith(rule.get("path", "/")):
        return False
    pid = rule.get("product")
    return pid is None or query.get(rule.get("product_param", "ProductId"), [None])[0] == str(pid)


def rewrite_options(options, rule, key, mtime):
    type_field = rule.get("type_field", "deliveryTypeId")
    deadline_field = rule.get("deadline_field", "purchaseDeadline")
    for o in options:
        if type_field in rule and o.get(type_field) != rule[type_field]:
            continue
        if type_field not in rule and "deliveryTypeId" in o and o.get("deliveryTypeId") != rule.get("deliveryTypeId", 1):
            continue
        if "deadline_in_s" in rule:
            o[deadline_field] = iso(fixed_deadline(key, mtime, rule["deadline_in_s"]))
        if rule.get("deadline_null"):
            o[deadline_field] = None
        if "deadline_raw" in rule:
            o[deadline_field] = rule["deadline_raw"]
        for f, v in (rule.get("set") or {}).items():
            o[f] = v
        for f in ("value", "arrivesText", "arrivesTextShort", "arrives"):
            if f in rule:
                o[f] = rule[f]
    return options


class P(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _go(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0) or 0)) or None
        u = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(u.query)
        st = load_state()
        rule = next((r for r in st.get("rules", []) if match(r, u.path, q)), None)
        t0 = time.time()
        rec = {"t": round(t0, 3), "iso": iso(datetime.now(timezone.utc)), "method": self.command, "path": self.path,
               "rule": rule.get("name") if rule else None}
        if rule and rule.get("mode") in ("500", "timeout", "empty", "garbage"):
            mode = rule["mode"]
            if mode == "timeout":
                time.sleep(rule.get("sleep_s", 30))
            code, out, hdrs = (500, b'{"error":"qa"}', {}) if mode in ("500", "timeout") else (200, b'{"serverTime":"' + iso(datetime.now(timezone.utc)).encode() + b'","options":[]}' if mode == "empty" else b'{"x":1}', {})
            rec.update(status=code, injected=mode)
        else:
            hdrs_in = {k: v for k, v in self.headers.items() if k.lower() not in ("host", "connection", "accept-encoding", "content-length")}
            req = urllib.request.Request(UPSTREAM + self.path, data=body, method=self.command, headers=hdrs_in)
            try:
                r = urllib.request.urlopen(req, timeout=60, context=CTX)
                code, out, hdrs = r.status, r.read(), dict(r.headers)
            except urllib.error.HTTPError as e:
                code, out, hdrs = e.code, e.read(), dict(e.headers)
            except Exception as e:
                code, out, hdrs = 502, str(e).encode(), {}
            rec.update(status=code, upstream_ms=int((time.time() - t0) * 1000),
                       up_date=hdrs.get("Date") or hdrs.get("date"), up_age=hdrs.get("Age") or hdrs.get("age"),
                       x_cache=hdrs.get("X-Cache") or hdrs.get("x-cache"))
            if rule and code == 200 and out:
                try:
                    d = json.loads(out)
                    opts = d.get(rule.get("list_field", "options")) if isinstance(d, dict) else d
                    key = (u.path, q.get("ProductId", [""])[0], rule.get("name"))
                    rewrite_options(opts, rule, key, st["_mtime"])
                    out = json.dumps(d).encode()
                    rec["rewritten"] = [(o.get("deliveryTypeId"), o.get("purchaseDeadline"), o.get("value")) for o in opts]
                except Exception as e:
                    rec["rewrite_error"] = str(e)
            if rule and "date_shift_s" in rule:
                for k in list(hdrs):
                    if k.lower() == "date":
                        dt = datetime.strptime(hdrs[k], "%a, %d %b %Y %H:%M:%S GMT").replace(tzinfo=timezone.utc) + timedelta(seconds=rule["date_shift_s"])
                        hdrs[k] = dt.strftime("%a, %d %b %Y %H:%M:%S GMT")
            if rule and "age" in rule:
                hdrs = {k: v for k, v in hdrs.items() if k.lower() != "age"}
                hdrs["Age"] = str(rule["age"])
        if self.path.startswith(os.environ.get("QA_PROXY_SUMMARY_PREFIX", "/")):
            try:
                d = json.loads(out)
                opts = d.get("options") if isinstance(d, dict) else d
                if isinstance(opts, list):
                    rec["sent"] = [{k: o.get(k) for k in ("deliveryTypeId", "arrivesText", "purchaseDeadline", "value") if isinstance(o, dict) and k in o} for o in opts][:20]
                if isinstance(d, dict):
                    rec["serverTime"] = d.get("serverTime")
            except Exception:
                pass
            rec["sent_date"] = next((v for k, v in hdrs.items() if k.lower() == "date"), None)
            rec["sent_age"] = next((v for k, v in hdrs.items() if k.lower() == "age"), None)
        open(LOG, "a").write(json.dumps(rec, ensure_ascii=False) + "\n")
        self.send_response_only(code)
        if not any(k.lower() == "date" for k in hdrs):
            self.send_header("Date", self.date_time_string())
        for k, v in hdrs.items():
            if k.lower() in ("transfer-encoding", "connection", "content-length", "content-encoding"):
                continue
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _go


if __name__ == "__main__":
    if not UPSTREAM:
        sys.exit("defina QA_PROXY_UPSTREAM com a URL base da API (ex.: https://api-qas.exemplo.com)")
    print(f"qa_api_proxy :{PORT} -> {UPSTREAM} state={STATE}", flush=True)
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), P).serve_forever()
