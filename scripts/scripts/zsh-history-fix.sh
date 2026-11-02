#!/usr/bin/env bash
# zsh-history-fix.sh — repair corruption in a zsh history file.
#
# Repairs:
#   * NUL byte runs (the "hole" left when two shells write the file at the
#     same time) -> newline, so records stay separate
#   * leaked terminal escape sequences, e.g. bracketed-paste markers
#     ESC[200~ / ESC[201~ (and a stray trailing "~" they leave behind)
#   * stray CR / CRLF line endings
#   * continuation lines holding invalid UTF-8 (usually mangled prompt text)
#
# History records look like:  : 1763762352:0;some command
# Continuation lines (multi-line pasted commands) do not start with that
# header and are left alone.
#
# Usage:
#   zsh-history-fix.sh                    # dry run, reports only
#   zsh-history-fix.sh --apply            # backup + rewrite
#   zsh-history-fix.sh --apply FILE       # custom history file
#
set -euo pipefail

APPLY=0
FILE="$HOME/.zsh_history"
for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
        *) FILE="$arg" ;;
    esac
done

[[ -f "$FILE" ]] || { echo "no such file: $FILE" >&2; exit 1; }

export ZHF_FILE="$FILE"
export ZHF_APPLY="$APPLY"

python3 - <<'PY'
import os, re, sys, shutil, datetime

path = os.environ["ZHF_FILE"]
apply = os.environ["ZHF_APPLY"] == "1"
data = open(path, "rb").read()

stats = {}
def bump(key, n=1):
    stats[key] = stats.get(key, 0) + n

# 1. NUL runs -> record separator. If a newline is already sitting before the
#    hole, replace with nothing instead, otherwise we invent an empty record.
nul_runs = list(re.finditer(rb"\x00+", data))
if nul_runs:
    bump("nul_holes", len(nul_runs))
    bump("nul_bytes", sum(len(m.group()) for m in nul_runs))
    for m in reversed(nul_runs):
        before = data[m.start() - 1:m.start()]
        data = data[:m.start()] + (b"" if before == b"\n" else b"\n") + data[m.end():]

# 2. leaked CSI escape sequences (ESC[200~, ESC[201~, colours, ...)
esc = re.findall(rb"\x1b(?:\[[0-9;?]*[ -/]*[@-~]|\][^\x07]*\x07|[@-Z\\-_])", data)
if esc:
    bump("escape_sequences", len(esc))
# any remaining raw ESC bytes go too
if b"\x1b" in data:
    bump("raw_esc_bytes", data.count(b"\x1b"))
    data = data.replace(b"\x1b", b"")
data = re.sub(rb"\[20[01]~", b"", data)   # markers with the ESC already gone

# 3. CRLF / stray CR
crlf = data.count(b"\r\n")
if crlf:
    bump("crlf", crlf)
    data = data.replace(b"\r\n", b"\n")
lone_cr = data.count(b"\r")
if lone_cr:
    bump("lone_cr", lone_cr)
    data = data.replace(b"\r", b"")

# 4. invalid UTF-8: drop continuation lines that carry it, else mark bytes
lines = data.split(b"\n")
rec = re.compile(rb"^: \d+:\d+;")
kept, dropped = [], []
drop_after = set()   # index in `kept` of a record whose continuation is gone
for ln in lines:
    try:
        ln.decode("utf-8")
        kept.append(ln)
    except UnicodeDecodeError:
        if rec.match(ln):
            bump("bad_record_lines")
            kept.append(ln.decode("utf-8", "replace").encode("utf-8"))
        else:
            bump("bad_continuation_lines")
            dropped.append(ln.decode("utf-8", "replace"))
            if kept:
                drop_after.add(len(kept) - 1)

# 4b. trim the continuation backslash only on records whose mangled
#     continuation line was just dropped (a lone trailing "\" would otherwise
#     re-join the next record on read). Note: records that end with "\" and
#     are followed by a blank line are normal zsh encoding for a pasted
#     trailing newline -- leave those alone.
dangling = 0
for i in sorted(drop_after):
    if kept[i].endswith(b"\\"):
        kept[i] = kept[i][:-1]
        dangling += 1
if dangling:
    bump("dangling_backslashes", dangling)
data = b"\n".join(kept)

# 5. trailing "~" orphaned by a lost ESC[201~
fixed_tilde = 0
out = []
for ln in data.split(b"\n"):
    if ln.endswith(b"~") and len(ln) > 1 and ln[-2:-1] not in (b" ", b"\t", b""):
        # only inside a record body, never a bare "cd ~"
        body = ln.split(b";", 1)[1] if rec.match(ln) else ln
        if body.strip() != b"~":
            ln = ln[:-1]
            fixed_tilde += 1
    out.append(ln)
if fixed_tilde:
    bump("trailing_tildes", fixed_tilde)
data = b"\n".join(out)

# 6. single trailing newline
data = data.rstrip(b"\n") + b"\n"
data.decode("utf-8")  # must be clean now

records = len(re.findall(rb"(?m)^: \d+:\d+;", data))

print(f"file:      {path}")
print(f"size:      {len(open(path,'rb').read())} -> {len(data)} bytes")
print(f"records:   {records}")
if not stats:
    print("result:    clean, nothing to do")
    sys.exit(0)
for k, v in sorted(stats.items()):
    print(f"  {k}: {v}")
if dropped:
    print("dropped continuation lines:")
    for d in dropped:
        print("  " + repr(d[:100]))

if not apply:
    print("result:    DRY RUN — pass --apply to write (a backup is kept)")
    sys.exit(0)

stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup = f"{path}.bak-{stamp}"
shutil.copy2(path, backup)
os.chmod(backup, 0o600)
tmp = f"{path}.tmp-{stamp}"
with open(tmp, "wb") as f:
    f.write(data)
os.chmod(tmp, 0o600)
os.replace(tmp, path)
print(f"backup:    {backup}")
print("result:    repaired")
PY
