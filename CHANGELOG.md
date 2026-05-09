## [Unreleased]

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
