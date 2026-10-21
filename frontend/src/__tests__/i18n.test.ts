import { describe, it, expect, beforeEach } from 'vitest'
import { t, tf, setLocale, locale } from '../i18n'
import { messages } from '../i18n/messages'

describe('i18n', () => {
  beforeEach(() => setLocale('en'))

  it('looks up strings in the active locale', () => {
    expect(t('panel.tabs.overview')).toBe('Overview')
  })

  it('falls back to English, then to the key itself', () => {
    expect(t('panel.tabs.overview')).toBe(messages.en['panel.tabs.overview'])
    // @ts-expect-error — deliberate unknown key at runtime
    expect(t('panel.tabs.doesNotExist')).toBe('panel.tabs.doesNotExist')
  })

  it('interpolates parameters', () => {
    expect(tf('search.noResultsFor', { query: 'foo' }))
      .toBe('No results found for "foo"')
  })

  it('switches locales', () => {
    setLocale('en')
    expect(locale()).toBe('en')
  })
})
