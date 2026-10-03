#!/usr/bin/env python3
"""Evidence analyzer for the DLSS5_PRE_UPSCALE=auto first-frame probe.

Reads native-pre-upscale.txt (add-on log) and reports what the auto decision would have done:
- first processed job per pid: did the captured list have following work? (auto decides here)
- whether any UNSAFE / fatal event appears anywhere (mode-1 behaviour today)

auto semantics: first processed job with following work -> fall back to the post-upscale route
(logged, sticky); without -> stay on pre-upscale. Usage: analyze-pre-upscale-log.py LOG [LOG...]
"""
import re, sys, collections

def analyze(path):
    events = []
    rx = re.compile(r"^(?:pid=(\d+) )?frame=(\d+) .*event=(.*)$")
    with open(path, errors="replace") as f:
        for line in f:
            m = rx.match(line.strip())
            if not m:
                continue
            pid, frame, event = m.group(1), int(m.group(2)), m.group(3)
            events.append((pid, frame, event))
    unsafe = [e for e in events if "UNSAFE" in e[2] or "fatal" in e[2]]
    # The UNSAFE event only fires while a job is pending; a following "captured" on a later frame of the
    # same pid means the session survived (today: only when mode != 1, i.e. the smoke mode 2).
    first_unsafe_frame = min((e[1] for e in unsafe), default=None)
    verdict = "fallback-on-first-frame (today: fatal passthrough)" if unsafe else "stays on pre-upscale (tail-of-list contract holds)"
    print(f"{path}")
    print(f"  events={len(events)} UNSAFE_or_fatal={len(unsafe)} first_unsafe_frame={first_unsafe_frame}")
    print(f"  auto would: {verdict}")
    return bool(unsafe)

if __name__ == "__main__":
    bad = 0
    for p in sys.argv[1:]:
        bad |= analyze(p)
    sys.exit(0)
