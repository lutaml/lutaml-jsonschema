import { describe, it, expect, beforeEach } from 'vitest'
// @vitest-environment jsdom
import { t, tf, setLocale, locale, directionFor, applyDocumentLocale } from '../i18n'
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

  it('maps locales to writing directions', () => {
    expect(directionFor('en')).toBe('ltr')
  })

  it('mirrors lang and dir onto the document element', () => {
    applyDocumentLocale('en')
    expect(document.documentElement.lang).toBe('en')
    expect(document.documentElement.dir).toBe('ltr')
  })
})
