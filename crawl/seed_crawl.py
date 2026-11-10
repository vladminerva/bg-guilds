"""Seed crawl: try candidate guild spellings on Warmane WotLK realms, save rosters.
Usage: python3 -I seed_crawl.py <candidates.txt> <out_dir>
candidates.txt lines: Guild Name | Realm1,Realm2  (realms optional -> all WotLK realms)
"""
import json, sys, time, subprocess, urllib.parse, pathlib

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36"
REALMS = ["Icecrown", "Lordaeron", "Onyxia", "Blackrock"]
GAP = 3.5

def get(url):
    for attempt in range(8):
        raw = subprocess.run(["curl", "-s", "-m", "30", "-A", UA, url], capture_output=True, text=True).stdout
        try:
            d = json.loads(raw)
        except ValueError:
            d = {"error": "Too many requests."} if not raw else {"error": "bad response: " + raw[:80]}
        time.sleep(GAP)
        if d.get("error") == "Too many requests.":
            time.sleep(GAP * (attempt + 2))
            continue
        return d
    return {"error": "gave up (rate limit)"}

def main(cand_file, out_dir):
    out = pathlib.Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    found, missing, seen = [], [], set()
    for line in pathlib.Path(cand_file).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"): continue
        name, _, realms = line.partition("|")
        name = name.strip()
        realms = [r.strip() for r in realms.split(",") if r.strip()] or REALMS
        for realm in realms:
            url = f"https://armory.warmane.com/api/guild/{urllib.parse.quote_plus(name)}/{realm}/summary"
            d = get(url)
            if "roster" in d:
                key = (d["name"], d["realm"])
                if key in seen:
                    print(f"dup   {name!r} -> {d['name']!r} @ {realm}", flush=True); continue
                seen.add(key)
                fn = out / f"{d['realm']}__{d['name'].replace(' ', '_').replace('/', '_')}.json"
                fn.write_text(json.dumps(d, ensure_ascii=False))
                lvl80 = sum(1 for m in d["roster"] if str(m.get("level")) == "80")
                found.append({"tried": name, "name": d["name"], "realm": d["realm"], "faction": d.get("faction"),
                              "members": len(d["roster"]), "lvl80": lvl80})
                print(f"FOUND {name!r} -> {d['name']!r} @ {d['realm']}  members={len(d['roster'])} lvl80={lvl80} faction={d.get('faction')}", flush=True)
            else:
                missing.append({"tried": name, "realm": realm, "error": d.get("error")})
                print(f"miss  {name!r} @ {realm}: {d.get('error')}", flush=True)
    (out / "_summary.json").write_text(json.dumps({"found": found, "missing": missing}, ensure_ascii=False, indent=1))

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
