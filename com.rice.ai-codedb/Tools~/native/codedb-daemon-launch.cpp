#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
#include <vector>
#include <cstdio>

// Windows CRT argument quoting, including empty strings and trailing backslashes.
static std::wstring Quote(const wchar_t* value) {
    std::wstring out = L"\"";
    unsigned slashes = 0;
    for (const wchar_t* p = value; *p; ++p) {
        if (*p == L'\\') { ++slashes; continue; }
        if (*p == L'\"') { out.append(slashes * 2 + 1, L'\\'); out += *p; }
        else { out.append(slashes, L'\\'); out += *p; }
        slashes = 0;
    }
    out.append(slashes * 2, L'\\'); out += L'\"';
    return out;
}

int wmain(int argc, wchar_t** argv) {
    if (argc < 3) { std::fprintf(stderr, "LAUNCH_USAGE executable cwd [arguments]\n"); return 64; }
    std::wstring line = Quote(argv[1]);
    for (int i = 3; i < argc; ++i) { line += L' '; line += Quote(argv[i]); }
    if (line.size() >= 32767) { std::fprintf(stderr, "LAUNCH_COMMAND_TOO_LONG\n"); return 64; }
    std::vector<wchar_t> command(line.begin(), line.end()); command.push_back(0);
    STARTUPINFOW startup = {}; startup.cb = sizeof(startup);
    PROCESS_INFORMATION child = {};
    // Do not set STARTF_USESTDHANDLES. Neither std handles nor incidental inherited
    // handles from upstream PowerShell/Node may cross this one-shot boundary.
    if (!CreateProcessW(argv[1], command.data(), nullptr, nullptr, FALSE,
        DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP, nullptr, argv[2], &startup, &child)) {
        const DWORD error = GetLastError();
        std::fprintf(stderr, "LAUNCH_CREATE_FAILED win32=%lu\n", error);
        return 70;
    }
    FILETIME created = {}, exited = {}, kernel = {}, user = {};
    const BOOL observed = GetProcessTimes(child.hProcess, &created, &exited, &kernel, &user);
    ULARGE_INTEGER ticks = {}; ticks.LowPart = created.dwLowDateTime; ticks.HighPart = created.dwHighDateTime;
    std::printf("{\"pid\":%lu,\"creation_filetime\":\"%llu\",\"time_observed\":%s}\n",
        child.dwProcessId, ticks.QuadPart, observed ? "true" : "false");
    CloseHandle(child.hThread);
    CloseHandle(child.hProcess);
    // Creation only. The existing authenticated coordinator protocol owns READY.
    return 0;
}
