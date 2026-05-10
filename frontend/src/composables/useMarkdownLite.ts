/**
 * Lightweight inline Markdown renderer for schema descriptions.
 * Handles: **bold**, *italic*, `code`, [link](url), ```fenced code blocks```
 */
export function renderInlineMarkdown(text: string): string {
  if (!text) return ''
  let html = escapeHtml(text)

  // Fenced code blocks: ```lang\n...\n```  (must run before inline code)
  html = html.replace(/```[\w]*\n([\s\S]*?)```/g, (_match, code: string) => {
    return `<pre class="md-pre"><code>${code.trim()}</code></pre>`
  })

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
