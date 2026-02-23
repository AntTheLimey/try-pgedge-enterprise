# Code Reviewer Knowledge Base

## Project Quality Standards

### Shell Scripts
- Follow try-pgedge-helm patterns exactly
- All scripts must pass shellcheck
- Interactive scripts source lib/helpers.sh
- Two-space indentation throughout

### Common Anti-Patterns to Flag

**Bash:**
- Unquoted variables (`echo $VAR` instead of `echo "$VAR"`)
- Missing error handling (`cd some_dir` instead of `cd some_dir || exit 1`)
- Using `[` instead of `[[` for conditionals
- Missing `set -euo pipefail`

**JavaScript:**
- Using innerHTML without escaping (XSS risk)
- No error handling on fetch calls
- Missing null/undefined checks on DOM elements
