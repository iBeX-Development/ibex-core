import { existsSync, mkdirSync, writeFileSync } from 'fs'
import { resolve } from 'path'

const MAX_ICON_SIZE = 1024 * 1024

function publicPath(): string {
  const cwd = process.cwd()
  if (existsSync(resolve(cwd, 'public'))) return resolve(cwd, 'public')
  return resolve(cwd, '.app/public')
}

export default defineEventHandler(async (event) => {
  const body = (await readBody(event)) as { code?: string; dataUrl?: string }
  const code = body?.code ?? ''
  const match = body?.dataUrl?.match(
    /^data:image\/(png|jpeg|webp);base64,(.+)$/,
  )

  if (!/^[a-z][a-z0-9_-]{1,15}$/.test(code) || !match) {
    throw createError({ statusCode: 400, message: 'Invalid language icon' })
  }

  const extension = match[1] === 'jpeg' ? 'jpg' : match[1]
  const image = Buffer.from(match[2], 'base64')
  if (image.length > MAX_ICON_SIZE) {
    throw createError({
      statusCode: 413,
      message: 'Icon must be smaller than 1 MB',
    })
  }

  const directory = resolve(publicPath(), 'img/icons/flags')
  if (!existsSync(directory)) mkdirSync(directory, { recursive: true })

  //   const filename = `${code}-${Date.now()}.${extension}`
  const filename = `${code}`
  writeFileSync(resolve(directory, filename), image)
  return { icon: `/img/icons/flags/${filename}` }
})
