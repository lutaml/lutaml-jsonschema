import { describe, it, expect } from 'vitest'
import { renderInlineMarkdown } from '../composables/useMarkdownLite'

describe('renderInlineMarkdown', () => {
  it('returns empty for empty string', () => {
    expect(renderInlineMarkdown('')).toBe('')
  })

  it('renders bold text', () => {
    expect(renderInlineMarkdown('**bold**')).toBe('<strong>bold</strong>')
  })

  it('renders italic text', () => {
    expect(renderInlineMarkdown('*italic*')).toBe('<em>italic</em>')
  })

  it('renders inline code', () => {
    expect(renderInlineMarkdown('`code`')).toBe('<code class="md-code">code</code>')
  })

  it('renders links', () => {
    const result = renderInlineMarkdown('[click](https://example.com)')
    expect(result).toContain('<a href="https://example.com"')
    expect(result).toContain('class="md-link"')
    expect(result).toContain('>click</a>')
  })

  it('escapes HTML', () => {
    expect(renderInlineMarkdown('<b>no</b>')).toBe('&lt;b&gt;no&lt;/b&gt;')
  })

  it('returns plain text unchanged', () => {
    expect(renderInlineMarkdown('hello world')).toBe('hello world')
  })

  it('handles mixed formatting', () => {
    const result = renderInlineMarkdown('Use `method` for **special** cases.')
    expect(result).toContain('<code class="md-code">method</code>')
    expect(result).toContain('<strong>special</strong>')
  })
})
