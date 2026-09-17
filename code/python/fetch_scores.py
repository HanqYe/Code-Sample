"""
Collect admission cutoff records for 2024-2026.

Same API as the original scraper, but without rotating proxies, whose only
purpose is to evade the site's rate limit. This version uses a fixed low
request rate, resumes where it left off, and backs off a bounded number of
times before stopping for a human to look at it.

Usage:
    python fetch_scores.py index     # step 1: build the task list
    python fetch_scores.py fetch     # step 2: download JSON, interruptible
    python fetch_scores.py parse     # step 3: collapse into one CSV
    python fetch_scores.py stats     # progress at any point
"""

import json
import os
import random
import sys
import time

import pandas as pd
import requests

# ----------------------------------------------------------------------------
BASE = os.environ.get("GK_BASE", r"E:\replication")
RAW = os.path.join(BASE, "data", "raw_json")
IDX_CSV = os.path.join(BASE, "data", "fetch_tasks.csv")
OUT_CSV = os.path.join(BASE, "data", "scores_2024_2026.csv")
SCHOOLS_CSV = os.path.join(BASE, "data", "school_ids.csv")
REF_CSV = os.path.join(BASE, "raw", "fen_shu.csv")

YEARS = [2024, 2025, 2026]

# Measured: at a 1.0s interval the 63rd request is refused, so the threshold is
# about 60 requests per minute. 150 consecutive requests at 1.5s and 120 at
# 3.0s both went through. 1.5s leaves some headroom.
SLEEP = 1.50          # seconds between requests
JITTER = 0.30         # extra random jitter, upper bound

COOLDOWN = 900        # wait after being throttled, the block lifts in about fifteen minutes
MAX_COOLDOWN = 6      # how many times to accept that before giving up
MAX_RETRY = 3
PAGE_SIZE = 20

REST_EVERY = 1000     # take a longer break every this many combinations
REST_SECS = 30
ABORT_AFTER = 20      # stop if this many consecutive combinations return nothing

# Proxy credentials are never hardcoded. Set the environment variable first if
# you use one, for example
#   $env:GK_PROXY = "http://user:password@host:port"
# Direct connection otherwise.
_p = os.environ.get("GK_PROXY", "").strip()
PROXIES = {"http": _p, "https": _p} if _p else None

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

H_STATIC = {"User-Agent": UA, "Referer": "https://www.gaokao.cn/",
            "Accept": "application/json"}

H_API = {"Host": "api.zjzw.cn", "User-Agent": UA,
         "Accept": "application/json, text/plain, */*",
         "Content-Type": "application/json",
         "Origin": "https://www.gaokao.cn",
         "Referer": "https://www.gaokao.cn/"}

SESSION = requests.Session()


def nap():
    time.sleep(SLEEP + random.random() * JITTER)


def get_with_retry(url, **kw):
    for attempt in range(MAX_RETRY):
        try:
            r = SESSION.get(url, timeout=25, **kw)
            if r.status_code == 200:
                return r
            if r.status_code in (404, 403):
                return None
        except requests.RequestException as e:
            print(f"  [retry {attempt + 1}] {type(e).__name__}: {e}")
        time.sleep(2 ** attempt)
    return None


class Blocked(Exception):
    """The site has started refusing us. Stop immediately."""


def post_with_retry(url, params, **kw):
    body = json.dumps(params, separators=(",", ":"))
    for attempt in range(MAX_RETRY):
        try:
            r = SESSION.post(url, headers=H_API, params=params, data=body,
                             timeout=30, proxies=PROXIES, verify=PROXIES is None,
                             **kw)
            if r.status_code == 200:
                return r
            if r.status_code in (403, 429, 503):
                raise Blocked(f"HTTP {r.status_code}")
            print(f"  [retry {attempt + 1}] HTTP {r.status_code}")
        except requests.RequestException as e:
            print(f"  [retry {attempt + 1}] {type(e).__name__}: {e}")
        time.sleep(3 * 2 ** attempt)
    return None


# ----------------------------------------------------------------------------
def build_index():
    """One call per school to list every province, track and batch combination."""
    schools = pd.read_csv(SCHOOLS_CSV)
    ids = schools["school_id"].tolist()
    print(f"{len(ids)} schools, target years {YEARS}")

    rows = []
    for n, sid in enumerate(ids, 1):
        url = f"https://static-data.gaokao.cn/www/2.0/school/{sid}/dic/provincescore.json"
        r = get_with_retry(url, headers=H_STATIC, params={"a": "www.gaokao.cn"})
        nap()
        if r is None:
            print(f"[{n}/{len(ids)}] school {sid}: no index, skipped")
            continue
        try:
            blocks = r.json()["data"]["data"]
        except (ValueError, KeyError, TypeError):
            print(f"[{n}/{len(ids)}] school {sid}: unexpected index format, skipped")
            continue

        got = 0
        for blk in blocks:
            if blk.get("year") not in YEARS:
                continue
            for prov in blk.get("province", []):
                for tid in prov.get("type", []):
                    for bid in prov.get("batch", []):
                        rows.append({"year": blk["year"],
                                     "local_province_id": prov["pid"],
                                     "local_type_id": tid,
                                     "local_batch_id": bid,
                                     "school_id": sid})
                        got += 1
        print(f"[{n}/{len(ids)}] school {sid}: {got} combinations")

    df = pd.DataFrame(rows).drop_duplicates()
    df.to_csv(IDX_CSV, index=False, encoding="utf-8-sig")
    print(f"\ntask list written to {IDX_CSV}")
    print(df.groupby("year").size().to_string())


# ----------------------------------------------------------------------------
def page_path(task, page):
    return os.path.join(
        RAW,
        f'{task["year"]}_{task["local_province_id"]}_{task["local_type_id"]}'
        f'_{task["local_batch_id"]}_{task["school_id"]}_page{page}.json')


def fetch_one(task):
    """Download every page of one combination. Returns (files written, requests sent)."""
    url = "https://api.zjzw.cn/web/api/"
    written = 0
    asked = 0
    page = 1
    total_pages = 1

    while page <= total_pages:
        dest = page_path(task, page)
        if os.path.exists(dest):
            if page == 1:
                try:
                    with open(dest, encoding="utf-8") as f:
                        n = json.load(f)["data"]["numFound"]
                    total_pages = max(1, -(-int(n) // PAGE_SIZE))
                except (ValueError, KeyError, TypeError, OSError):
                    total_pages = 1
            page += 1
            continue

        params = {"like_spname": "",
                  "local_batch_id": str(task["local_batch_id"]),
                  "local_province_id": str(task["local_province_id"]),
                  "local_type_id": str(task["local_type_id"]),
                  "page": str(page),
                  "school_id": str(task["school_id"]),
                  "sg_xuanke": "",
                  "size": str(PAGE_SIZE),
                  "special_group": "",
                  "uri": "apidata/api/gk/score/special",
                  "year": str(task["year"])}

        asked += 1
        r = post_with_retry(url, params)
        nap()
        if r is None:
            print(f"  giving up on {os.path.basename(dest)}")
            break

        try:
            payload = r.json()
        except ValueError:
            print(f"  non-JSON response for {os.path.basename(dest)}")
            break

        code = payload.get("code") if isinstance(payload, dict) else None

        # 1069 means too many requests. The HTTP status is still 200, so this
        # has to be caught on the business code, otherwise it looks like an
        # empty result and the combination is silently skipped.
        if code == "1069":
            raise Blocked(f"code 1069 {payload.get('message', '')}")

        if code != "0000":
            break

        data = payload.get("data")
        if not isinstance(data, dict):
            break

        n = data.get("numFound", 0)

        # Do not write empty results. That province and year may simply not be
        # published yet, and the next run should try again.
        if page == 1 and not n:
            break

        with open(dest, "w", encoding="utf-8") as f:
            f.write(r.text)
        written += 1

        if page == 1:
            total_pages = max(1, -(-int(n) // PAGE_SIZE))
        page += 1

    return written, asked


def fetch_all():
    tasks = pd.read_csv(IDX_CSV)

    # Optional year filter: python fetch_scores.py fetch 2024 2025
    want = [int(a) for a in sys.argv[2:] if a.isdigit()]
    if want:
        tasks = tasks[tasks["year"].isin(want)]
        print(f"restricted to {want}")

    print(f"{len(tasks)} combinations, {SLEEP}s between requests plus jitter, "
          f"safe to interrupt with Ctrl+C")
    t0 = time.time()
    new = 0
    misses = 0

    cooled = 0
    for i, task in enumerate(tasks.to_dict("records"), 1):
        while True:
            try:
                got, asked = fetch_one(task)
                break
            except Blocked as e:
                cooled += 1
                if cooled > MAX_COOLDOWN:
                    print(f"\nrepeatedly throttled on combination {i} ({e}), stopping")
                    print("downloaded files are kept, rerunning fetch resumes from here")
                    return
                print(f"\n[{i}/{len(tasks)}] throttled ({e}), "
                      f"resuming in {COOLDOWN // 60} minutes "
                      f"(attempt {cooled}/{MAX_COOLDOWN})")
                time.sleep(COOLDOWN)

        new += got
        misses = misses + 1 if (asked and not got) else 0
        if misses >= ABORT_AFTER:
            print(f"\n{ABORT_AFTER} consecutive combinations returned nothing, stopping")
            break

        if i % REST_EVERY == 0:
            print(f"  {i} combinations done, resting {REST_SECS}s")
            time.sleep(REST_SECS)

        if i % 50 == 0 or i == len(tasks):
            el = time.time() - t0
            rate = i / el if el else 0
            eta = (len(tasks) - i) / rate / 60 if rate else 0
            print(f"[{i}/{len(tasks)}] {new} new files, "
                  f"{rate:.2f} combinations/s, about {eta:.0f} minutes left")

    print(f"\n{new} new JSON files this run")


# ----------------------------------------------------------------------------
def parse_all():
    """Collapse raw_json into one CSV with the same columns as the earlier file."""
    files = [f for f in os.listdir(RAW) if f.endswith(".json")]
    print(f"{len(files)} JSON files")

    rows = []
    bad = 0
    for n, fn in enumerate(files, 1):
        full = os.path.join(RAW, fn)
        try:
            with open(full, encoding="utf-8") as f:
                items = json.load(f)["data"]["item"]
        except (ValueError, KeyError, TypeError, OSError):
            bad += 1
            continue
        for d in items:
            d = dict(d)
            if "sg_name" in d and d["sg_name"] is not None:
                d["sg_name"] = str(d["sg_name"]) + "\t"
            d["path"] = full
            rows.append(d)
        if n % 2000 == 0:
            print(f"  parsed {n}/{len(files)}")

    df = pd.DataFrame(rows)
    print(f"{len(df)} records, {bad} files failed to parse")

    ref = pd.read_csv(REF_CSV, nrows=1, low_memory=False).columns.tolist()
    for c in ref:
        if c not in df.columns:
            df[c] = None
    extra = [c for c in df.columns if c not in ref]
    if extra:
        print(f"API returned new columns, kept at the end: {extra}")
    df = df[ref + extra]

    df.to_csv(OUT_CSV, index=False, encoding="utf-8-sig")
    print(f"written to {OUT_CSV}")
    print(df.groupby("year").size().to_string())


# ----------------------------------------------------------------------------
def stats():
    if os.path.exists(IDX_CSV):
        t = pd.read_csv(IDX_CSV)
        print("task list:")
        print(t.groupby("year").size().to_string())
    files = [f for f in os.listdir(RAW) if f.endswith(".json")]
    print(f"\n{len(files)} JSON files downloaded")
    if files:
        yrs = pd.Series([f.split("_")[0] for f in files])
        print(yrs.value_counts().sort_index().to_string())


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "stats"
    {"index": build_index, "fetch": fetch_all,
     "parse": parse_all, "stats": stats}[cmd]()
