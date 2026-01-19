import { invoke } from "@tauri-apps/api/core";

interface DialogFilter {
  name: string
  extensions: string[]
}

interface OpenDialogOptions {
  title?: string
  filters?: DialogFilter[]
  defaultPath?: string
  multiple?: boolean
  directory?: boolean
  recursive?: boolean
}

export async function open(
  options: OpenDialogOptions = {}
): Promise<null | string | string[]> {
  if (typeof options === 'object') {
    Object.freeze(options)
  }
  let res = invoke("tauri", {
    __tauriModule: 'Dialog',
    message: {
      cmd: 'openDialog',
      options
    }
  })

  return res as any;
}