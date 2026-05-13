/**
 * Lightweight inline Markdown renderer for schema descriptions.
 * Handles: **bold**, *italic*, `code`, [link](url), ```fenced code blocks```,
 * bullet lists (-, *, +), numbered lists (1.), headings (###).
 */
export function renderInlineMarkdown(text: string): string {
  if (!text) return ''
  let html = escapeHtml(text)

  // Fenced code blocks: ```lang\n...\n```  (must run before inline code)
  html = html.replace(/```[\w]*\n([\s\S]*?)```/g, (_match, code: string) => {
    return `\x00FENCED${code.trim()}\x00ENDFENCED`
  })

  // Split into lines for block-level processing
  const lines = html.split('\n')
  const result: string[] = []
  let inUl = false
  let inOl = false

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]

    // Skip fenced code block internals (already escaped)
    if (line.includes('\x00FENCED') || line.includes('\x00ENDFENCED')) {
      if (inUl) { result.push('</ul>'); inUl = false }
      if (inOl) { result.push('</ol>'); inOl = false }
      result.push(line)
      continue
    }

    // Heading: ### text
    const headingMatch = line.match(/^(#{1,4})\s+(.+)$/)
    if (headingMatch) {
      if (inUl) { result.push('</ul>'); inUl = false }
      if (inOl) { result.push('</ol>'); inOl = false }
      const level = headingMatch[1].length
      result.push(`<h${level + 2} class="md-heading">${headingMatch[2]}</h${level + 2}>`)
      continue
    }

    // Bullet list: -, *, + followed by space
    const ulMatch = line.match(/^(\s*)([-*+])\s+(.+)$/)
    if (ulMatch) {
      if (inOl) { result.push('</ol>'); inOl = false }
      if (!inUl) { result.push('<ul class="md-list">'); inUl = true }
      result.push(`<li>${applyInline(ulMatch[3])}</li>`)
      continue
    }

    // Numbered list: 1. text
    const olMatch = line.match(/^(\s*)\d+\.\s+(.+)$/)
    if (olMatch) {
      if (inUl) { result.push('</ul>'); inUl = false }
      if (!inOl) { result.push('<ol class="md-list">'); inOl = true }
      result.push(`<li>${applyInline(olMatch[2])}</li>`)
      continue
    }

    // Close list if non-list line encountered
    if (inUl) { result.push('</ul>'); inUl = false }
    if (inOl) { result.push('</ol>'); inOl = false }

    // Regular line
    result.push(line)
  }

  if (inUl) result.push('</ul>')
  if (inOl) result.push('</ol>')

  html = result.join('\n')

  // Restore fenced code blocks
  html = html.replace(/\x00FENCED([\s\S]*?)\x00ENDFENCED/g, (_match, code: string) => {
    return `<pre class="md-pre"><code>${code}</code></pre>`
  })

  // Line breaks: \n → <br> (after block elements are formed)
  html = html.replace(/\n/g, '<br>')

  // Apply inline formatting to the whole output
  html = applyInline(html)

  return html
}

function applyInline(html: string): string {
  // Links: [text](url)
  html = html.replace(
    /\[([^\]]+)\]\(([^)]+)\)/g,
    '<a href="$2" target="_blank" rel="noopener" class="md-link">$1</a>',
  )
  // Bold: **text** or __text__
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/__(.+?)__/g, '<strong>$1</strong>')
  // Italic: *text* or _text_
  html = html.replace(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, '<em>$1</em>')
  html = html.replace(/(?<!_)_(?!_)(.+?)(?<!_)_(?!_)/g, '<em>$1</em>')
  // Code: `text`
  html = html.replace(/`([^`]+)`/g, '<code class="md-code">$1</code>')
  return html
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
}
