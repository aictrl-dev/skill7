import type { CommandModule } from "yargs"

export const GenerateCommand = {
  command: "generate",
  handler: async () => {
    const specs = {
      openapi: "3.1.1",
      info: {
        title: "skill7",
        version: "1.0.0",
      },
      paths: {},
    }
    const json = JSON.stringify(specs, null, 2)

    // Wait for stdout to finish writing before process.exit() is called
    await new Promise<void>((resolve, reject) => {
      process.stdout.write(json, (err) => {
        if (err) reject(err)
        else resolve()
      })
    })
  },
} satisfies CommandModule
