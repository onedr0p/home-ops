import * as lib from './index.mjs'

const commandRunner = (cmd, arg) => {
  if (!cmd) {
    throw new Error('No command was entered!')
  }

  if (!lib[cmd]) {
    throw new Error(`404: ${cmd} cmd not found`)
  }

  return new lib[cmd](arg)
}

export { commandRunner }