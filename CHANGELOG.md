## [Unreleased]

## [0.1.13] - 2026-05-10

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
