import vm from 'node:vm'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

export function loadPlugin() {
  const code = readFileSync(fileURLToPath(new URL('../code.js', import.meta.url)), 'utf8')
  const created = []
  const variableWrites = []
  let nodeId = 0
  const node = (type, extra = {}) => {
    const made = {
      type, id: `${type}-${++nodeId}`, children: [], width: 100, height: 20, layoutMode: 'NONE', boundVariables: {},
      appendChild(child) { this.children.push(child); child.parent = this },
      resize(width, height) { this.width = width; this.height = height },
      setBoundVariable(field, variable) { this.boundVariables[field] = variable },
      setTextStyleIdAsync(id) { this.textStyleId = id; return Promise.resolve() },
      setExplicitVariableModeForCollection(collection, modeId) { this.explicitModes = { ...(this.explicitModes || {}), [collection.id]: modeId } },
      findAllWithCriteria({ types }) {
        const found = []
        const walk = (parent) => { for (const child of parent.children) { if (types.includes(child.type)) found.push(child); walk(child) } }
        walk(this)
        return found
      },
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
    const made = node('TEXT', { fills: [], textStyleId: '' })
    let characters = ''
    Object.defineProperty(made, 'characters', {
      enumerable: true,
      get: () => characters,
      set: (value) => {
        if (!loadedFonts.has(fontKey(made.fontName))) throw new Error('characters written before font ' + fontKey(made.fontName) + ' was loaded')
        characters = value
      },
    })
    // Figma detaches an applied text style the moment a style-owned property is written afterwards, so
    // the node reverts to raw values. Model that: writing these after a bind clears textStyleId.
    const owned = { fontName: { family: 'Inter', style: 'Regular' }, fontSize: 12, letterSpacing: null, lineHeight: null, textDecoration: null }
    for (const prop of Object.keys(owned)) {
      Object.defineProperty(made, prop, {
        enumerable: true,
        get: () => owned[prop],
        set: (value) => { owned[prop] = value; if (made.textStyleId) made.textStyleId = '' },
      })
    }
    // Applying a text style overwrites the node's style-owned properties with the style's own, so a
    // plain style (no underline) clears a textDecoration set before the bind — write owned directly
    // (not through the setter) so this counts as the style applying, not a detaching manual edit.
    made.setTextStyleIdAsync = (id) => {
      made.textStyleId = id
      const style = created.find((n) => n.id === id)
      owned.textDecoration = (style && style.textDecoration) || 'NONE'
      return Promise.resolve()
    }
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
    createNodeFromSvg: () => node('SVG'),
    currentPage: node('PAGE'),
    createComponent: () => node('COMPONENT', { createInstance() { const deep = (n) => ({ ...n, children: (n.children || []).map(deep) }); const clone = node('INSTANCE'); clone.children = this.children.map(deep); return clone } }),
    createTextStyle: () => node('TEXTSTYLE'),
    getLocalTextStylesAsync: async () => [],
    createImage: (data) => ({ hash: `img-${data}` }),
    base64Decode: (source) => source,
    loadFontAsync: async (fontName) => { loadedFonts.add(fontKey(fontName)) },
    variables: {
      getLocalVariableCollectionsAsync: async () => [],
      createVariableCollection: (name) => { collection.name = name; return collection },
      getLocalVariablesAsync: async () => [...variablesByName.values()],
      createVariable: (name, coll, resolvedType) => {
        const variable = {
          name, resolvedType, variableCollectionId: coll.id, valuesByMode: {},
          setValueForMode(modeId, value) { this.valuesByMode[modeId] = value; variableWrites.push({ name, modeId, value }) },
          remove() { variablesByName.delete(name) },
        }
        variablesByName.set(name, variable)
        return variable
      },
      setBoundVariableForPaint: (paint, field, variable) => ({ ...paint, boundVariables: { ...(paint.boundVariables || {}), [field]: { type: 'VARIABLE_ALIAS', id: variable.name } } }),
    },
  }
  const figma = new Proxy(api, { get: (target, prop) => (prop in target ? target[prop] : () => {}) })
  const sandbox = { figma, __html__: '', console }
  sandbox.globalThis = sandbox
  vm.createContext(sandbox)
  vm.runInContext(code, sandbox)
  return { build: sandbox.PW.build, syncTokens: sandbox.PW.syncTokens, syncTextStyles: sandbox.PW.syncTextStyles, syncFromDocument: sandbox.PW.syncFromDocument, importFramed: sandbox.PW.importFramed, created, variableWrites }
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
