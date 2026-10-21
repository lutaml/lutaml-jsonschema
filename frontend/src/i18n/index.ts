import { messages, type Locale, type MessageKey } from './messages'

let activeLocale: Locale = 'en'

export function locale(): Locale {
  return activeLocale
}

export function setLocale(next: Locale): void {
  activeLocale = next
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
