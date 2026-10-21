import { messages, type Locale, type MessageKey } from './messages'

let activeLocale: Locale = 'en'

/** Writing direction per locale — RTL locales must mirror the layout. */
const RTL_LOCALES: readonly string[] = ['ar', 'he', 'fa', 'ur']

export function locale(): Locale {
  return activeLocale
}

export function directionFor(id: Locale): 'ltr' | 'rtl' {
  return RTL_LOCALES.includes(id) ? 'rtl' : 'ltr'
}

/** Mirror <html lang/dir> so layout, fonts and scrollbars follow the locale. */
export function applyDocumentLocale(id: Locale = activeLocale): void {
  if (typeof document === 'undefined') return
  document.documentElement.lang = id
  document.documentElement.dir = directionFor(id)
}

export function setLocale(next: Locale): void {
  activeLocale = next
  applyDocumentLocale(next)
}

/** Look up a UI string in the active locale, falling back to English. */
export function t(key: MessageKey): string {
  const table = messages[activeLocale] as Record<string, string>
  const english = messages.en as Record<string, string>
  return table[key] ?? english[key] ?? key
}

/** Interpolated variant: t('search.noResultsFor', { query: 'foo' }) */
export function tf(
  key: MessageKey,
  params: Record<string, string | number>,
): string {
  return Object.entries(params).reduce(
    (text, [name, value]) => text.replaceAll(`{${name}}`, String(value)),
    t(key),
  )
}
