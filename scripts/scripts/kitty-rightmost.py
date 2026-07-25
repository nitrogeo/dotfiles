#!/usr/bin/env python3
import json
import subprocess
import sys

def main():
    out = subprocess.check_output(["kitty", "@", "ls"], text=True)
    data = json.loads(out)

    tabs = []
    for os_window in data:
        for tab in os_window.get("tabs", []):
            tabs.append(tab)

    if not tabs:
        sys.exit("No tabs found")

    last_tab = max(tabs, key=lambda t: t["index"])
    subprocess.check_call(["kitty", "@", "goto-tab", str(last_tab["index"])])

if __name__ == "__main__":
    main()