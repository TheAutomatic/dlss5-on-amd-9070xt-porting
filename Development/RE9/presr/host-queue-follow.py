# Applied by prepare-host.py after its own LmxxfBackend.cpp edits (exec'd in its scope: host, prefix, original, write).
# Generated from the build tested in Onimusha on 2026-09-27 (results/onimusha-presr-20260927/host-queue-follow.diff).
_hunks = {
 "LmxxfBackend.cpp": [
  [
   "\nID3D12Resource *LmxxfBackend::Record(ID3D12GraphicsCommandList *cmd, const AmdPreSr::Frame &frame,\n",
   "\n// Set by Submitted when our split list ran on a queue other than the session's; Record rebuilds the session there.\nstatic ID3D12CommandQueue *g_requeue = nullptr;\n\nID3D12Resource *LmxxfBackend::Record(ID3D12GraphicsCommandList *cmd, const AmdPreSr::Frame &frame,\n"
  ],
  [
   "{\n    if(pendingJob){SetStatus(\"lmxxf: prior job not yet submitted; original SR\");return nullptr;}\n",
   "{\n    if (g_requeue && !pendingJob)\n    {\n        if (g_requeue != queue)\n        {\n            if (session && api && api->table.Destroy)\n                api->table.Destroy(session);\n            session = nullptr;\n            sessionReady = false;\n            g_requeue->AddRef();\n            if (queue)\n                queue->Release();\n            queue = g_requeue;\n            LOG_INFO(\"lmxxf: game submits on a new queue {}; session rebuilt there\", static_cast<void *>(queue));\n        }\n        g_requeue = nullptr;\n    }\n    // A job whose list was never submitted (or submitted where Submitted() cannot see it, e.g. across a swapchain\n    // rebuild) would otherwise block every later frame until restart. After a few evaluations, give it up.\n    static unsigned stalledEvaluations = 0;\n    if(pendingJob && ++stalledEvaluations >= 8){\n        const bool enqueued = LmxxfCut::Pending().job != pendingJob;\n        if(enqueued) api->table.Retire(session, pendingJob); else api->table.CancelUnsubmitted(session, pendingJob);\n        LmxxfCut::ClearPendingEnqueue();\n        pendingJob = nullptr;\n        static unsigned recoveries = 0;\n        if(++recoveries <= 5 || recoveries % 100 == 0)\n            LOG_WARN(\"lmxxf: stalled job recovered ({}; recovery {})\", enqueued ? \"retired\" : \"cancelled\", recoveries);\n    }\n    if(pendingJob){SetStatus(\"lmxxf: prior job not yet submitted; original SR\");return nullptr;}\n"
  ],
  [
   "    if(pendingJob){SetStatus(\"lmxxf: prior job not yet submitted; original SR\");return nullptr;}\n    LmxxfCut::ClearPendingEnqueue();\n",
   "    if(pendingJob){SetStatus(\"lmxxf: prior job not yet submitted; original SR\");return nullptr;}\n    stalledEvaluations = 0;\n    LmxxfCut::ClearPendingEnqueue();\n"
  ],
  [
   "{\n    if(DlssNr::Submission::InsideLogicalExecute() || submittedQueue != queue || LmxxfCut::Pending().job)return;\n    if (session && pendingJob && api && api->table.Retire)\n",
   "{\n    if(DlssNr::Submission::InsideLogicalExecute() || LmxxfCut::Pending().job)return;\n    if(submittedQueue != queue)\n    {\n        if(!pendingJob || submittedQueue != LmxxfCut::Pending().lastQueue.load(std::memory_order_relaxed))return;\n        g_requeue = submittedQueue;\n    }\n    if (session && pendingJob && api && api->table.Retire)\n"
  ]
 ],
 "LmxxfEvaluateCut.h": [
  [
   "    std::atomic<int32_t> lastEnqueueRc { 0 };\n};\n",
   "    std::atomic<int32_t> lastEnqueueRc { 0 };\n    // Queue that actually executed the split list (can differ from the bootstrap queue after a swapchain rebuild).\n    std::atomic<ID3D12CommandQueue *> lastQueue { nullptr };\n};\n"
  ],
  [
   "    const EnqueueHipFn fn = p.enqueueHip;\n    // Consume before call so a nested Submitted cannot double-fire the same job.\n",
   "    const EnqueueHipFn fn = p.enqueueHip;\n    p.lastQueue.store(queue, std::memory_order_relaxed);\n    // Consume before call so a nested Submitted cannot double-fire the same job.\n"
  ]
 ]
}
for _f, _base in (('LmxxfBackend.cpp', 'written'), ('LmxxfEvaluateCut.h', 'original')):
    _name = 'dlssnr/backend/' + _f
    _s = (host/prefix/_name).read_text() if _base == 'written' else original(_name)
    for _old, _new in _hunks[_f]:
        assert _s.count(_old) == 1, (_f, _old[:60])
        _s = _s.replace(_old, _new)
    write(_name, _s)
