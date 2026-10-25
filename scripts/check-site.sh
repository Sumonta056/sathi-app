#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

FAIL=0
fail() { echo "site: $1"; FAIL=1; }

for f in index.html site.css robots.txt sitemap.xml 404.html; do
  [[ -f "site/$f" ]] || fail "missing site/$f"
done

for ref in $(grep -oE '(src|href)="[^"#:]+"' site/index.html site/404.html | sed -E 's/.*="([^"]+)"/\1/' | sort -u); do
  path="${ref#/sathi-app/}"
  [[ -e "site/${path:-index.html}" ]] || fail "a page links to missing file $ref"
done

python3 - site/index.html <<'PY' || FAIL=1
import json, re, sys
html = open(sys.argv[1]).read()
blocks = re.findall(r'<script type="application/ld\+json">(.*?)</script>', html, re.S)
if not blocks:
    sys.exit("site: no JSON-LD block")
for b in blocks:
    json.loads(b)
PY

APP="$(sed -n '/CFBundleShortVersionString/{n;s/.*<string>\(.*\)<\/string>.*/\1/p;}' Resources/Info.plist)"
grep -q "\"softwareVersion\": \"$APP\"" site/index.html || fail "JSON-LD softwareVersion is not $APP"

for tag in 'rel="canonical"' 'name="description"' 'property="og:image"' 'name="twitter:card"'; do
  grep -q "$tag" site/index.html || fail "index.html has no $tag"
done

[[ $FAIL -eq 0 ]] && echo "Site OK"
exit $FAIL
