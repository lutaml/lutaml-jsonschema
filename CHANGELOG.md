## [Unreleased]

## [0.1.14] - 2026-05-10

### Redoc-style UX improvements (round 15)

- Markdown renderer converts `\n` to `<br>` for multi-line descriptions
- Definition mini-table shows `$ref` target name with clickable navigation
- Definition mini-table shows `const` badge for constant properties
- Definition mini-table shows deprecated strikethrough on property names
- Definition mini-table shows `N enum` label instead of just count
- Definition card header shows `N examples` instead of `N ex`
- Definition card expanded body shows required fields list and examples section
- DetailPanel properties tab rows are clickable (navigate to property)
- DetailPanel properties tab shows `$ref` target with clickable link
- Improved circular reference label (shows type badge, name, hint text)
- Source viewer: click on line number to highlight it
- Landing page card descriptions rendered with markdown
- Keyboard shortcut: `/` focuses search input from anywhere
- Search input placeholder shows shortcut hint
- Search results expand schema tree node automatically
- Hash navigation expands schema tree node automatically
- Definition mini-table type badges color-coded by type (string/number/integer/boolean/object/array)
- Definition mini-table rows show hover effect

## [0.1.13] - 2026-05-10

### Backend: property-level composition resolution

- Resolve `allOf` properties by merging sub-schemas into a unified type with merged properties
- Resolve `anyOf`/`oneOf` properties by showing variant type labels (e.g. `anyOf: object | object`)
- Resolve `not` properties with negated type label (e.g. `not string`)
- Extract `$ref` from allOf sub-schemas for frontend definition expansion
- Extract `resolve_prop_ref` helper to reduce complexity in `build_single_property`

### Redoc-style UX improvements (round 7)

- SeeMore description fade uses CSS mask-image instead of background gradient (works on any background)
- Array type badge shows items range constraint inline (e.g. `array of string [ 1 .. 10 ]`)
- Schema tree sidebar shows property count badge (P) alongside definition count (D)
- Definition mini-table shows format (`<email>`) and enum count badges
- Definition card description truncated to 2 lines when collapsed
- Landing card stats show min/max properties count

### Redoc-style UX improvements (round 8)

- Auto-expand definitions with single property (Redoc expandSingleSchemaField pattern)
- Clickable $ref navigation — clicking ref chip scrolls to definition
- Source viewer line numbers highlight on hover
- Definition mini-table shows composition source (allOf/anyOf/oneOf) badges
- Scroll centering for definition and property navigation

### Redoc-style UX improvements (round 9)

- Definition card header shows required field names when ≤3 required fields
- JSON preview shows hint when no fields are checked
- Definition expanded body shows title, type, property count, and composition badges

### Redoc-style UX improvements (round 10)

- Clickable $id/$schema URLs in schema header (opens in new tab)
- Keyboard support for definition card toggle (Enter/Space)
- Nested builder shows parent property path breadcrumb

### Redoc-style UX improvements (round 11)

- Composition type badges with teal color coding (type-composition class)
- Static label for composition properties instead of editable input
- `isCompositionType()` helper for frontend composition type detection
- Skip validation for composition type properties

### Redoc-style UX improvements (round 12)

- DetailPanel: clickable $ref link navigates to definition (closes panel, scrolls to def)
- DetailPanel: readOnly/writeOnly access badges in property overview
- DetailPanel: enum values shown as individual chips instead of comma-separated list
- DetailPanel: schema overview shows property count and definition count

### Redoc-style UX improvements (round 13)

- Search results show description snippets (truncated to 80 chars)
- Schema header breadcrumb shows Schema > Definition when a definition is selected
- Clickable breadcrumb link navigates back to schema overview

### Redoc-style UX improvements (round 14)

- Property filter in SchemaBuilder when schema has >8 properties (filters by name, title, description, type)
- Markdown renderer handles fenced code blocks (` ```code``` `)
- Global CSS for markdown pre/code blocks in descriptions

## [0.1.12] - 2026-05-10

### Redoc-style UX improvements (round 6)

- Property title display in type row when it differs from name (Redoc TypeTitle pattern)
- Copy fallback using `execCommand('copy')` for HTTP contexts where clipboard API unavailable
- Dark panel full-height background via BackgroundStub `::before` pattern
- Search result description snippets in search modal
- Tooltip with directional CSS arrow on copy buttons
- DetailPanel properties table: shows title, format with angle brackets, default value, enum count, inline examples

## [0.1.11] - 2026-05-09

### Redoc-style UX improvements (round 5)

- Dark JSON preview panel with themed syntax colors in SchemaBuilder
- Select-on-click for source viewer and builder JSON blocks (double-click to select all)
- Print stylesheet: hides sidebar, header, controls; content prints full-width
- Format badges display with angle brackets (`<email>`) and accent color
- Responsive builder layout: stacks vertically on mobile (<768px)

## [0.1.10] - 2026-05-09

### Redoc-style UX improvements

- JSON viewer collapsed objects show key names (e.g. `{a, b, c}`), arrays show item count
- Sidebar auto-scrolls to active schema node on selection
- Search results sorted by relevance: exact name > starts with > contains > description
- Copy button shows positioned tooltip overlay instead of text swap
- Mobile sidebar backdrop overlay (click-to-close)
- DetailPanel overview shows definition-level metadata: required fields, composition badges, property range, additionalProperties
- Nullable badge for union types (e.g. `string,null`) in SchemaBuilder
- Focus trap in DetailPanel: focus moves to panel on open, Tab/Shift+Tab trapped, Escape closes

## [0.1.0] - 2026-05-05

- Initial release
