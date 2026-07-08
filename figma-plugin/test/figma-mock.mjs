import vm from 'node:vm'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

export function loadPlugin() {
  const code = readFileSync(fileURLToPath(new URL('../code.js', import.meta.url)), 'utf8')
  const created = []
  const variableWrites = []
  const node = (type, extra = {}) => {
    const made = {
      type, children: [], width: 100, height: 20, layoutMode: 'NONE', boundVariables: {},
      appendChild(child) { this.children.push(child); child.parent = this },
      resize(width, height) { this.width = width; this.height = height },
      setBoundVariable(field, variable) { this.boundVariables[field] = variable },
      ...extra,
    }
    created.push(made)
    return made
  }
  const collection = {
    id: 'collection', name: 'Mode', modes: [{ modeId: 'light', name: 'Mode 1' }],
    renameMode(modeId, name) { this.modes.find((m) => m.modeId === modeId).name = name },
    addMode(name) { this.modes.push({ modeId: 'dark', name }); return 'dark' },
  }
  const variablesByName = new Map()
  // Figma requires a text node's font be loaded before its characters are written; a fresh node's default Inter Regular is unloaded, so writing first throws.
  const loadedFonts = new Set()
  const fontKey = (font) => font && `${font.family}|${font.style}`
  const createText = () => {
    const made = node('TEXT', { fontSize: 12, fills: [], fontName: { family: 'Inter', style: 'Regular' } })
    let characters = ''
    Object.defineProperty(made, 'characters', {
      enumerable: true,
      get: () => characters,
      set: (value) => {
        if (!loadedFonts.has(fontKey(made.fontName))) throw new Error('characters written before font ' + fontKey(made.fontName) + ' was loaded')
        characters = value
      },
    })
    return made
  }
  const api = {
    mixed: Symbol('mixed'),
    showUI() {},
    notify() {},
    ui: { onmessage: null, postMessage() {} },
    createText,
    createFrame: () => node('FRAME', { fills: [] }),
    createRectangle: () => node('RECT', { fills: [] }),
    createComponent: () => node('COMPONENT'),
    createTextStyle: () => node('TEXTSTYLE'),
    createImage: () => ({ hash: 'image' }),
    base64Decode: () => new Uint8Array(),
    loadFontAsync: async (fontName) => { loadedFonts.add(fontKey(fontName)) },
    variables: {
      getLocalVariableCollectionsAsync: async () => [],
      createVariableCollection: (name) => { collection.name = name; return collection },
      getLocalVariablesAsync: async () => [...variablesByName.values()],
      createVariable: (name, coll, resolvedType) => {
        const variable = {
          name, resolvedType, variableCollectionId: coll.id, values: {},
          setValueForMode(modeId, value) { this.values[modeId] = value; variableWrites.push({ name, modeId, value }) },
          remove() { variablesByName.delete(name) },
        }
        variablesByName.set(name, variable)
        return variable
      },
      setBoundVariableForPaint: (paint) => paint,
    },
  }
  const figma = new Proxy(api, { get: (target, prop) => (prop in target ? target[prop] : () => {}) })
  const sandbox = { figma, __html__: '', console }
  sandbox.globalThis = sandbox
  vm.createContext(sandbox)
  vm.runInContext(code, sandbox)
  return { build: sandbox.PW.build, syncTokens: sandbox.PW.syncTokens, created, variableWrites }
}

export function rootParent() {
  return { type: 'ROOT', children: [], layoutMode: 'NONE', appendChild(c) { this.children.push(c); c.parent = this }, resize() {} }
}

export function labelScreen(text = {}) {
  return {
    tag: 'screen', name: 'Screen', x: 0, y: 0, w: 402, h: 800,
    fill: { r: 0.1, g: 0.1, b: 0.1, a: 1 }, ordered: true,
    layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [300, 64, 300, 64], justify: 'center', align: 'center', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [{
      tag: 'text', x: 64, y: 380, w: 272, h: 40,
      font: { family: 'SF Pro Rounded', size: 15, weight: 400, style: 'subtitle', color: { r: 1, g: 1, b: 1, a: 1 } },
      texts: [{ text: 'Tap the settings button and choose an option.', x: 64, y: 380, w: 272, h: 40 }],
      children: [],
      ...text,
    }],
  }
}

export async function importedLabel(text) {
  const { build, created } = loadPlugin()
  await build(labelScreen(text), rootParent(), 0, 0, false)
  return created.find((n) => n.type === 'TEXT' && n.characters)
}
