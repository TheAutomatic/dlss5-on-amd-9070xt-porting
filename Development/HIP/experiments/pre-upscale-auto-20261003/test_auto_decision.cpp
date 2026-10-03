// Host-path unit test for DLSS5_PRE_UPSCALE=auto (Linux-native; the production auto block is extracted
// verbatim from src/native_pre_upscale.h by extract-auto-block.sh, so this tests the shipped code text).
// Covers what a Forza/Wo Long run would exercise at the decision point: first-frame probe, sticky decision,
// fallback to the post-upscale route, and the parsing/precedence rules. It does NOT cover the D3D12 replay
// path (compiled and reviewed; needs a live game -> 待 Zero 实测).
// One scenario per child process: the file-configured mode is a function-local static (read once, by design).
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cwchar>
#include <string>
#include <vector>
#include <sys/wait.h>
#include <unistd.h>

// ---- stubs for the block's two external dependencies ----
static const wchar_t* g_env_value; // nullptr = unset
static wchar_t g_env_buf[64];
static const wchar_t* _wgetenv(const wchar_t*) { return g_env_value; }
static std::vector<std::string> NativeConfigFileLines() {
  const char* v = std::getenv("TEST_CFG_LINE");
  return v ? std::vector<std::string>{v} : std::vector<std::string>{};
}

namespace NativePreUpscale { // the header opens this namespace before the block; the extractor copies the block only
#include "auto_block.inc"
}

static int failures = 0;
static void check(bool ok, const char* what) {
  std::printf("%s %s\n", ok ? "PASS" : "FAIL", what);
  if (!ok) ++failures;
}
static void set_env(const char* v) {
  if (!v) { g_env_value = nullptr; return; }
  std::mbstowcs(g_env_buf, v, 63);
  g_env_value = g_env_buf;
}

static int scenario(int id) {
  switch (id) {
    case 0: // no env, no config file
      set_env(nullptr);
      check(NativePreUpscale::RequestedMode() == 0 && !NativePreUpscale::Enabled(),
            "unset -> mode 0 (post-upscale route), add-on hook inert");
      check(NativePreUpscale::AutoDecide(true) == 0, "no auto requested -> AutoDecide is a no-op");
      break;
    case 1:
      set_env("1");
      check(NativePreUpscale::Mode() == 1 && NativePreUpscale::Enabled(), "env=1 -> pre-upscale forced");
      check(NativePreUpscale::AutoDecide(true) == 1, "forced 1 + later following work -> stays 1 (fatal path preserved)");
      break;
    case 2:
      set_env("0");
      check(NativePreUpscale::Mode() == 0 && !NativePreUpscale::Enabled(), "env=0 -> post-upscale route");
      break;
    case 3:
      set_env("yes");
      check(NativePreUpscale::RequestedMode() == 0, "invalid env value falls back to 0 (previous behaviour)");
      break;
    case 4:
      set_env("2");
      check(NativePreUpscale::RequestedMode() == 2, "env=2 keeps the FFX-only smoke replay mode");
      break;
    case 5: // auto, Stellar Blade layout: first processed job has nothing after the dispatch in its list.
      set_env("auto");
      check(NativePreUpscale::Mode() == 1 && NativePreUpscale::Enabled(), "auto undecided behaves as pre-upscale");
      check(NativePreUpscale::AutoDecide(false) == 1, "auto + tail-of-list -> stays on pre-upscale");
      check(NativePreUpscale::AutoDecision().load() == 1, "decision committed");
      check(NativePreUpscale::AutoDecide(true) == 1 && NativePreUpscale::AutoDecision().load() == 1,
            "committed decision is sticky: later following work keeps mode 1 (Process throws fatal, same as a forced 1)");
      break;
    case 6: // auto, Forza/Wo Long layout: first processed job already saw following work.
      set_env("auto");
      check(NativePreUpscale::AutoDecide(true) == 0, "auto + work after the dispatch -> falls back to mode 0");
      check(!NativePreUpscale::Enabled(), "fallback disables the pre-upscale hook (post route takes over next frame)");
      check(NativePreUpscale::Mode() == 0 && NativePreUpscale::AutoDecision().load() == 2,
            "fallback is sticky (no flip-flop)");
      break;
    case 7: // config file as the source (add-on templates)
      set_env(nullptr);
      setenv("TEST_CFG_LINE", "DLSS5_PRE_UPSCALE=auto", 1);
      check(NativePreUpscale::RequestedMode() == 3 && NativePreUpscale::Mode() == 1,
            "flags file auto -> pre-upscale semantics");
      check(NativePreUpscale::AutoDecide(true) == 0, "flags file auto + following work -> fallback");
      break;
    case 8:
      set_env(nullptr);
      setenv("TEST_CFG_LINE", "DLSS5_PRE_UPSCALE=AUTO", 1);
      check(NativePreUpscale::RequestedMode() == 0, "flags file value is case-sensitive: AUTO is invalid -> 0");
      break;
    case 9: // environment wins over the flags file
      set_env("1");
      setenv("TEST_CFG_LINE", "DLSS5_PRE_UPSCALE=auto", 1);
      check(NativePreUpscale::RequestedMode() == 1, "environment wins over the flags file");
      break;
    case 10:
      set_env(nullptr);
      setenv("TEST_CFG_LINE", "DLSS5_PRE_UPSCALE=2", 1);
      check(NativePreUpscale::RequestedMode() == 2, "flags file 2 keeps the smoke mode");
      break;
    default:
      return 1;
  }
  return failures ? 1 : 0;
}

int main(int argc, char** argv) {
  constexpr int kScenarios = 11;
  if (argc > 1) return scenario(std::atoi(argv[1]));
  int bad = 0;
  for (int i = 0; i < kScenarios; ++i) {
    std::printf("--- scenario %d ---\n", i);
    pid_t pid = fork();
    if (pid == 0) _exit(scenario(i));
    int status = 0;
    waitpid(pid, &status, 0);
    if (!WIFEXITED(status) || WEXITSTATUS(status)) { std::printf("FAIL scenario %d\n", i); ++bad; }
  }
  std::printf("%s (%d failing scenarios)\n", bad ? "FAILED" : "ALL PASS", bad);
  return bad ? 1 : 0;
}
