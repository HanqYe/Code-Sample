"""
Measure the rate limit on api.zjzw.cn.

Phase one sends one request a minute to find out how long a block lasts.
Phase two, once the block lifts, sends a run of requests at a chosen interval
to see whether that rate holds.

Traffic is minimal throughout. Results are appended to probe_limit.log.
"""

import json
import os
import sys
import time
from datetime import datetime

import requests

LOG = os.path.join(os.environ.get("GK_BASE", r"E:\replication"),
                   "output", "logs", "probe_limit.log")

H = {"Host": "api.zjzw.cn",
     "User-Agent": ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"),
     "Accept": "application/json, text/plain, */*",
     "Content-Type": "application/json",
     "Origin": "https://www.gaokao.cn",
     "Referer": "https://www.gaokao.cn/"}

P = {"like_spname": "", "local_batch_id": "14", "local_province_id": "61",
     "local_type_id": "2073", "page": "1", "school_id": "31", "sg_xuanke": "",
     "size": "20", "special_group": "", "uri": "apidata/api/gk/score/special",
     "year": "2025"}

BODY = json.dumps(P, separators=(",", ":"))
S = requests.Session()


def say(msg):
    line = f"{datetime.now():%H:%M:%S}  {msg}"
    print(line, flush=True)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def hit():
    """Returns 'ok', 'limited', or an error string."""
    try:
        r = S.post("https://api.zjzw.cn/web/api/", headers=H, params=P,
                   data=BODY, timeout=25)
    except requests.RequestException as e:
        return f"neterr:{type(e).__name__}"
    try:
        j = r.json()
    except ValueError:
        return f"http{r.status_code}:notjson"
    if not isinstance(j, dict):
        return "badshape"
    code = j.get("code")
    if code == "1069":
        return "limited"
    if code == "0000":
        return "ok"
    return f"code{code}"


def phase1(max_minutes=180):
    say("=== phase 1: one request a minute until the block lifts ===")
    t0 = time.time()
    for i in range(max_minutes):
        st = hit()
        mins = (time.time() - t0) / 60
        say(f"[{i + 1:>3}] waited {mins:5.1f} minutes -> {st}")
        if st == "ok":
            say(f">>> block lifted after about {mins:.1f} minutes")
            return mins
        time.sleep(60)
    say(">>> still blocked at the time limit")
    return None


def phase2(gap=3.0, n=120):
    say(f"=== phase 2: {n} requests {gap}s apart, testing whether that rate holds ===")
    ok = 0
    for i in range(1, n + 1):
        st = hit()
        if st == "ok":
            ok += 1
        else:
            say(f"request {i} returned {st} after {ok} consecutive successes")
            say(f">>> {gap}s is not sustainable, budget about {ok} requests")
            return ok, False
        if i % 20 == 0:
            say(f"  {ok} consecutive successes")
        time.sleep(gap)
    say(f">>> all {n} requests at {gap}s succeeded, that rate is usable")
    return ok, True


if __name__ == "__main__":
    gap = float(sys.argv[1]) if len(sys.argv) > 1 else 3.0
    waited = phase1()
    if waited is not None:
        time.sleep(5)
        phase2(gap=gap)
