# Onimusha: Way of the Sword with the 0.33 RE9 package (2026-09-27)

Zero installed the 0.33 OptiScaler-REFramework package into the Xbox build (`C:\XboxGames\Onimusha- Way of the Sword\Content`)
and reported "not working". Reproduced on the 9070 with the game started from an ssh session (interactive scheduled task,
`explorer shell:AppsFolder\F024294D.63383C66B8708_8fty0by30jkny!OnimushaWotS`) and keyboard input through `SendInput` scan codes
(`SendKeys` does not reach the game).

## What works

- The route is the RE9 one unchanged: FFX 3.1 inputs → OptiScaler NGX evaluate → `AmdBridge::Before` → lmxxf split + HIP.
  `lmxxf nr: ... betweenHits/enqueueCalls` climb every frame, `lastEnqueueRc=0`, no submit failures.
- `[DlssNr] DebugView=4` (magenta tint in the decoder) is visible **in gameplay** and toggles with F6
  (screen mean RGB 44/25/54 on, 37/46/48 off). Net 900 tier (1512×848 → 2560×1440).
- **The title/main menu is not affected** even with the tint: the menu background never reaches the screen through the
  upscaler's colour input. Judging the effect in the menus shows nothing.

## What broke Zero's session

Zero's log: NR ran from 09:22:42 (1040×584 → 1760×990 start), FSR re-created at 2560×1440 at 09:23:16, then at 09:24:01 the game
built a new swapchain (a display / frame-generation change; config.ini was rewritten at 09:24:26). From there the backend status
stayed `prior job not yet submitted; original SR` until exit: one job never got retired and blocked every later frame.

Reproduced once (watchdog build, after windowed→borderless and FG off→on): jobs were **enqueued** (the between-slot ran, HIP ran)
but never retired, because `LmxxfBackend::Submitted()` only accepts the queue the backend was constructed with and the game now
executed our split list on another queue. The bridge comment already says the bootstrap queue is only a hint.

## Fix (host backend, `Development/RE9/presr/host-queue-follow.py`, diff in `host-queue-follow.diff`)

1. `BetweenThunk` records the queue that executed the split list (`PendingHip::lastQueue`).
2. `Submitted()` on that queue retires the job and marks the session for a rebuild; the next `Record()` destroys the session and
   recreates it on the new queue (runtime waits and fences then match the queue the game uses).
3. Watchdog: a job still pending after 8 evaluations is retired (enqueued) or cancelled (never enqueued), with a warning.

Build: `host-requeue` from the 0.33 source archive, `OptiScaler.dll` sha256 `aa3761f2…`, installed in Onimusha as `dxgi.dll`
(0.33 `dxgi.dll` 0ef10229 kept at `D:\DLSSNR-Lab\host-watchdog-20260927\dxgi-0.33.dll`). Tested: windowed 1760×990 start,
switch to borderless 2560×1440, 8 frame-generation toggles (swapchains 2–11), NR tint present after each, no stall, no recovery.
The queue switch did not recur in that run, so the rebuild path is untested live; the watchdog path ran in the previous build
(700+ recoveries, NR kept at ~1 frame in 8 instead of 0).

Not in any package. Hand to TheAutomatic: the queue check in `Submitted()` is ours (prepare-host), but his bridge hands
`State::currentCommandQueue` as the bootstrap queue; a game that rebuilds its swapchain/queue needs the session to follow.
