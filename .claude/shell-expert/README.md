# Shell Expert Knowledge Base

## Interactive Walkthrough Pattern

The guide scripts follow a 5-phase pattern per step:

1. `header()` -- Section title
2. `explain()` -- Description of what will happen
3. `prompt_continue()` -- Let user read
4. `prompt_run()` -- Execute commands with pauses
5. `info()` -- Success message

## Helper Functions (lib/helpers.sh)

| Function | Purpose |
|----------|---------|
| `header "text"` | Blue section header with decorations |
| `info "text"` | Green success/status message |
| `warn "text"` | Yellow warning message |
| `error "text"` | Red error message |
| `explain "text"` | Indented explanatory text |
| `show_cmd "cmd"` | Display command in yellow with $ prefix |
| `prompt_continue` | "Press Enter to continue..." |
| `prompt_run "cmd"` | Show command, wait for Enter, execute |
| `start_spinner "msg"` | Start background spinner animation |
| `stop_spinner` | Stop spinner, clear line |
| `require_cmd "cmd" "hint"` | Assert command exists or exit |
| `detect_os` | Set OS_FAMILY, OS_MAJOR, PKG_MGR from /etc/os-release |
| `setup_trap` | Register EXIT trap for spinner cleanup |

## Reference

- Gold standard: `/Users/apegg/PROJECTS/try-pgedge-helm/guide.sh`
- Shared library: `lib/helpers.sh`
