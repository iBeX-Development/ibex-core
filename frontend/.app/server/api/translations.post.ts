import { existsSync, readFileSync, renameSync, rmSync, writeFileSync } from 'fs'
import { resolve } from 'path'

function localesPath(): string {
  const cwd = process.cwd()
  // dev: cwd = .app/
  if (existsSync(resolve(cwd, 'locales/en.json')))
    return resolve(cwd, 'locales')
  // dev from workspace root: cwd = cmms-front/
  if (existsSync(resolve(cwd, '.app/locales/en.json')))
    return resolve(cwd, '.app/locales')
  // prod: cwd = .app/.output/  →  ../locales = .app/locales
  if (existsSync(resolve(cwd, '../locales/en.json')))
    return resolve(cwd, '../locales')
  return resolve(cwd, '.app/locales')
}

type Language = { code: string; label: string; flag?: string; icon?: string }

const isValidCode = (code: string) => /^[a-z][a-z0-9_-]{1,15}$/.test(code)

export default defineEventHandler(async (event) => {
  const body = (await readBody(event)) as {
    langs?: Record<string, Record<string, string>>
    config?: { active?: string[]; languages?: Language[] }
    renamed?: Record<string, string>
    deleted?: string[]
  }

  if (!body) throw createError({ statusCode: 400, message: 'body required' })

  const base = localesPath()
  const configPath = `${base}/lang.config.json`
  const existingConfig = existsSync(configPath)
    ? JSON.parse(readFileSync(configPath, 'utf-8'))
    : { active: ['en', 'mn'], languages: [] }
  let languages: Language[] =
    body.config?.languages ?? existingConfig.languages ?? []

  languages = languages
    .filter((language) => isValidCode(language.code) && language.label?.trim())
    .map((language) => ({
      code: language.code,
      label: language.label.trim(),
      flag: language.flag ?? '',
      ...(language.icon ? { icon: language.icon } : {}),
    }))

  if (!languages.some((language) => language.code === 'en')) {
    throw createError({ statusCode: 400, message: 'English is required' })
  }

  if (
    new Set(languages.map((language) => language.code)).size !==
    languages.length
  ) {
    throw createError({
      statusCode: 400,
      message: 'Language codes must be unique',
    })
  }

  if (body.renamed) {
    for (const [oldCode, newCode] of Object.entries(body.renamed)) {
      if (!isValidCode(newCode) || oldCode === newCode) continue
      const oldPath = `${base}/${oldCode}.json`
      const newPath = `${base}/${newCode}.json`
      if (existsSync(oldPath) && !existsSync(newPath))
        renameSync(oldPath, newPath)
    }
  }

  // Save language files
  if (body.langs) {
    for (const [lang, data] of Object.entries(body.langs)) {
      if (!languages.some((language) => language.code === lang)) continue
      writeFileSync(
        `${base}/${lang}.json`,
        JSON.stringify(data, null, 2) + '\n',
      )
    }
  }

  for (const language of languages) {
    const filePath = `${base}/${language.code}.json`
    if (!existsSync(filePath)) writeFileSync(filePath, '{}\n')
  }

  for (const code of body.deleted ?? []) {
    if (
      code !== 'en' &&
      !languages.some((language) => language.code === code)
    ) {
      const filePath = `${base}/${code}.json`
      if (existsSync(filePath)) rmSync(filePath)
    }
  }

  const active = (body.config?.active ?? existingConfig.active ?? []).filter(
    (code) => languages.some((language) => language.code === code),
  )
  if (!active.includes('en')) active.unshift('en')
  writeFileSync(
    configPath,
    JSON.stringify({ active, languages }, null, 2) + '\n',
  )

  return { ok: true }
})
