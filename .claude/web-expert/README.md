# Web Expert Knowledge Base

## Package Catalog Page Architecture

Single-file vanilla HTML/CSS/JS app at `package-catalog/index.html`.

### Data Flow

1. Page loads -> fetches `catalog.json` via `fetch()`
2. Populates dropdown selectors from platform/version data
3. Generates install commands dynamically on dropdown change
4. Renders categorized package tree with expand/collapse

### Three Zones

1. **Selector** -- 4 dropdowns cascading to generate commands
2. **Commands** -- Dynamically generated install steps + copy button
3. **Catalog** -- Expandable category tree showing all packages

### catalog.json Schema

- `meta_packages[]` -- Full and Minimal meta-packages
- `categories[]` -- Package groups with individual package entries
- `platforms{}` -- Platform configs with prerequisites and command patterns
- `pg_versions[]` -- Available PG versions
- `default_*` -- Default selections

### Style

- Brand colors: navy (#0D2137), teal (#2DD4BF)
- Dark code blocks (#0f172a) on light background (#f8fafc)
- Responsive grid for selectors
- No external dependencies
