import { existsSync, readFileSync } from 'fs'
import { resolve } from 'path'

function localesPath(): string {
  const cwd = process.cwd()
  // dev: cwd = .app/  →  locales/en.json
  if (existsSync(resolve(cwd, 'locales/en.json')))
    return resolve(cwd, 'locales')
  // dev from workspace root: cwd = cmms-front/  →  .app/locales/en.json
  if (existsSync(resolve(cwd, '.app/locales/en.json')))
    return resolve(cwd, '.app/locales')
  // prod: cwd = .app/.output/  →  ../locales/en.json  =  .app/locales/en.json
  if (existsSync(resolve(cwd, '../locales/en.json')))
    return resolve(cwd, '../locales')
  // fallback
  return resolve(cwd, '.app/locales')
}

const DEFAULT_LANGUAGES = [
  { code: 'en', label: 'English', flag: '🇺🇸', icon: '/img/icons/flags/en.svg' },
  { code: 'mn', label: 'Монгол', flag: '🇲🇳', icon: '/img/icons/flags/mn.svg' },
  { code: 'zh', label: '中文', flag: '🇨🇳', icon: '/img/icons/flags/china.svg' },
  { code: 'jp', label: '日本語', flag: '🇯🇵', icon: '/img/icons/flags/jp.svg' },
  { code: 'ko', label: '한국어', flag: '🇰🇷', icon: '/img/icons/flags/ko.svg' },
  { code: 'kz', label: 'Қазақша', flag: '🇰🇿', icon: '/img/icons/flags/kz.svg' },
]

export default defineEventHandler(() => {
  const base = localesPath()
  const result: Record<string, any> = {}
  const configPath = `${base}/lang.config.json`
  let config: { active?: string[]; languages?: typeof DEFAULT_LANGUAGES }

  try {
    config = existsSync(configPath)
      ? JSON.parse(readFileSync(configPath, 'utf-8'))
      : {}
  } catch {
    config = {}
  }

  const languages = config.languages?.length
    ? config.languages
    : DEFAULT_LANGUAGES

  for (const { code } of languages) {
    try {
      const filePath = `${base}/${code}.json`
      const data = JSON.parse(readFileSync(filePath, 'utf-8'))
      result[code] = data
    } catch (error) {
      result[code] = {}
    }
  }

  result.config = {
    active: config.active?.filter((code) =>
      languages.some((l) => l.code === code),
    ) ?? ['en', 'mn'],
    languages,
  }

  return result
})
