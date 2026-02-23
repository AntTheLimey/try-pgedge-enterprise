# Code Reviewer Knowledge Base

## Project Quality Standards

### Shell Scripts
- Follow try-pgedge-helm patterns exactly
- All scripts must pass shellcheck
- Interactive scripts source lib/helpers.sh
- Two-space indentation throughout

### Common Anti-Patterns to Flag

**Bash:**

```bash
# BAD: Unquoted variable
echo $VAR
# GOOD:
echo "$VAR"

# BAD: Missing error handling
cd some_dir
# GOOD:
cd some_dir || exit 1

# BAD: Using [ instead of [[
if [ "$x" = "y" ]; then
# GOOD:
if [[ "$x" = "y" ]]; then
```

**JavaScript:**

```javascript
// BAD: innerHTML without escaping
el.innerHTML = userInput;
// GOOD:
el.textContent = userInput;

// BAD: No error handling on fetch
const data = await fetch("catalog.json");
// GOOD:
const resp = await fetch("catalog.json");
if (!resp.ok) throw new Error(`Failed: ${resp.status}`);
const data = await resp.json();
```
