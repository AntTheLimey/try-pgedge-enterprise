.PHONY: all lint validate test-all serve clean help

SHELL_FILES := $(shell find . -name '*.sh' -not -path './.git/*')
JSON_FILES  := $(shell find . -name '*.json' -not -path './.git/*' -not -path './.claude/*')

all: test-all

## Lint all shell scripts with shellcheck and validate JSON
lint:
	@echo "Linting shell scripts..."
	@shellcheck -x -P SCRIPTDIR $(SHELL_FILES)
	@echo "✓ Shell scripts OK"
	@echo ""
	@echo "Validating JSON..."
	@for f in $(JSON_FILES); do \
		jq empty "$$f" || exit 1; \
	done
	@echo "✓ JSON OK"

## Validate catalog.json structure (categories, platforms, meta_packages)
validate:
	@python3 scripts/validate_catalog.py

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
