#!/usr/bin/env python3

import json
import subprocess
import sys

try:
    data = json.loads(
        subprocess.check_output(["kitty", "@", "ls"], text=True)
    )
except subprocess.CalledProcessError as e:
    sys.exit(f"kitty @ ls failed: {e}")

tabs = [
    tab
    for window in data
    for tab in window.get("tabs", [])
]

if not tabs:
    sys.exit("No tabs found.")

last_index = max(tab["index"] for tab in tabs)

subprocess.run(
    ["kitty", "@", "goto-tab", str(last_index)],
    check=True,
)