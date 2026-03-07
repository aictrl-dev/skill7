export * from "./client.js"
export * from "./server.js"

import { createSkill7Client } from "./client.js"
import { createOpencodeServer } from "./server.js"
import type { ServerOptions } from "./server.js"

export async function createOpencode(options?: ServerOptions) {
  const server = await createOpencodeServer({
    ...options,
  })

  const client = createSkill7Client({
    baseUrl: server.url,
  })

  return {
    client,
    server,
  }
}
