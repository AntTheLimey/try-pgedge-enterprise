.PHONY: all lint validate test-all serve clean help

SHELL_FILES := $(shell find . -name '*.sh' -not -path './.git/*')
JSON_FILES  := $(shell find . -name '*.json' -not -path './.git/*' -not -path './.claude/*')

all: test-all

## Lint all shell scripts with shellcheck and validate JSON
lint:
	@echo "Linting shell scripts..."
	@shellcheck $(SHELL_FILES)
	@echo "✓ Shell scripts OK"
	@echo ""
	@echo "Validating JSON..."
	@for f in $(JSON_FILES); do \
		jq empty "$$f" || exit 1; \
	done
	@echo "✓ JSON OK"

## Validate catalog.json structure (categories, platforms, meta_packages)
validate:
	@echo "Validating catalog.json structure..."
	@python3 -c "\
import json, sys; \
d = json.load(open('package-catalog/catalog.json')); \
errors = []; \
if 'categories' not in d: errors.append('missing categories'); \
if 'platforms' not in d: errors.append('missing platforms'); \
if 'meta_packages' not in d: errors.append('missing meta_packages'); \
if 'pg_versions' not in d: errors.append('missing pg_versions'); \
for cat in d.get('categories', []): \
    for pkg in cat.get('packages', []): \
        if not pkg.get('name'): errors.append(f'package missing name in {cat[\"name\"]}'); \
        if not pkg.get('pg_versions'): errors.append(f'{pkg.get(\"name\",\"?\")} missing pg_versions'); \
for key, plat in d.get('platforms', {}).items(): \
    if not plat.get('install_pattern'): errors.append(f'{key} missing install_pattern'); \
if errors: \
    print('Validation errors:'); \
    [print(f'  - {e}') for e in errors]; \
    sys.exit(1); \
cats = len(d['categories']); \
pkgs = sum(len(c['packages']) for c in d['categories']); \
plats = len(d['platforms']); \
print(f'✓ catalog.json valid: {cats} categories, {pkgs} packages, {plats} platforms')"

## Run all quality checks
test-all: lint validate
	@echo ""
	@echo "═══════════════════════════════════"
	@echo "  ✓ All checks passed"
	@echo "═══════════════════════════════════"

## Serve the package catalog locally
serve:
	@bash package-catalog/serve.sh

## Remove generated files
clean:
	@echo "Nothing to clean (no build step)"

## Show this help
help:
	@echo "Available targets:"
	@echo "  make lint       - Lint shell scripts (shellcheck) and validate JSON (jq)"
	@echo "  make validate   - Validate catalog.json structure"
	@echo "  make test-all   - Run all quality checks"
	@echo "  make serve      - Serve package catalog on localhost:8080"
	@echo "  make clean      - Remove generated files"
	@echo "  make help       - Show this help"
