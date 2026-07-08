/// <reference types="@figma/plugin-typings" />
import { planText, planAutoLayout, orderChildren } from './plan'

figma.showUI(__html__, { width: 340, height: 520 })

const WEIGHT_ALIASES: Record<number, string[]> = {
  100: ['Thin'], 200: ['Extra Light', 'ExtraLight'], 300: ['Light'], 400: ['Regular'],
  500: ['Medium'], 600: ['Semibold', 'Semi Bold', 'SemiBold'], 700: ['Bold'],
  800: ['Extra Bold', 'ExtraBold'], 900: ['Black', 'Heavy'],
}

const EXPECTED_CAPTURE_VERSION = 1

const loaded = new Set<string>()
let masters: Record<string, ComponentNode> = {}

async function resolveFont(family: string, weight: number, italic: boolean): Promise<FontName> {
  const bases = WEIGHT_ALIASES[Math.round(weight / 100) * 100] || ['Regular']
  for (const candidate of [family, 'Inter']) {
    for (const base of bases) {
      const style = italic ? `${base} Italic` : base
      const key = `${candidate}|${style}`
      if (loaded.has(key)) return { family: candidate, style }
      const available = await figma.loadFontAsync({ family: candidate, style }).then(() => true, () => false)
      if (available) {
        loaded.add(key)
        return { family: candidate, style }
      }
    }
  }
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' })
  return { family: 'Inter', style: 'Regular' }
}

let colorVars: Record<string, Variable> = {}
let colorVarsByName: Record<string, Variable> = {}
let floatVarsByName: Record<string, Variable> = {}
let textStyles: Record<string, TextStyle> = {}
let darkMode = false
let darkByToken: Record<string, { r: number; g: number; b: number; a: number }> = {}

function colorKey(c: { r: number; g: number; b: number; a?: number }): string {
  const to255 = (x: number) => Math.round(x * 255)
  return `${to255(c.r)},${to255(c.g)},${to255(c.b)},${Math.round((c.a ?? 1) * 100)}`
}

async function loadColorVars(): Promise<void> {
  colorVars = {}
  colorVarsByName = {}
  for (const variable of await figma.variables.getLocalVariablesAsync('COLOR')) {
    colorVarsByName[variable.name] = variable
    const value = variable.valuesByMode[Object.keys(variable.valuesByMode)[0]]
    if (value && typeof value === 'object' && 'r' in value) colorVars[colorKey(value as RGBA)] = variable
  }
}

function solid(color: { r: number; g: number; b: number; a: number }, token?: string): SolidPaint {
  if (darkMode && token && darkByToken[token]) {
    const d = darkByToken[token]
    return { type: 'SOLID', color: { r: d.r, g: d.g, b: d.b }, opacity: d.a }
  }
  const paint: SolidPaint = { type: 'SOLID', color: { r: color.r, g: color.g, b: color.b }, opacity: color.a }
  const variable = (token && colorVarsByName['color/' + token]) || colorVars[colorKey(color)]
  return variable ? figma.variables.setBoundVariableForPaint(paint, 'color', variable) : paint
}

function applyAutoLayout(frame: FrameNode | ComponentNode, layout: any): void {
  const plan = planAutoLayout(layout)
  frame.layoutMode = plan.layoutMode
  frame.primaryAxisSizingMode = plan.primaryAxisSizingMode
  frame.counterAxisSizingMode = plan.counterAxisSizingMode
  frame.itemSpacing = plan.itemSpacing
  if (plan.layoutWrap) {
    frame.layoutWrap = plan.layoutWrap
    frame.counterAxisSpacing = plan.counterAxisSpacing as number
  }
  frame.paddingTop = plan.paddingTop
  frame.paddingRight = plan.paddingRight
  frame.paddingBottom = plan.paddingBottom
  frame.paddingLeft = plan.paddingLeft
  frame.primaryAxisAlignItems = plan.primaryAxisAlignItems
  frame.counterAxisAlignItems = plan.counterAxisAlignItems
  if (plan.minWidth !== null) frame.minWidth = plan.minWidth
  const gapVariable = layout.gapToken && floatVarsByName[layout.gapToken]
  if (gapVariable) {
    frame.setBoundVariable('itemSpacing', gapVariable)
    if (plan.layoutWrap) frame.setBoundVariable('counterAxisSpacing', gapVariable)
  }
  const padFields = ['paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft'] as const
  const padTokens = layout.padTokens || []
  for (let side = 0; side < padFields.length; side += 1) {
    const variable = floatVarsByName[padTokens[side]]
    if (variable) frame.setBoundVariable(padFields[side], variable)
  }
}

function centerViaAutoLayout(frame: FrameNode | ComponentNode, width: number, height: number): void {
  frame.layoutMode = 'HORIZONTAL'
  frame.primaryAxisSizingMode = 'FIXED'
  frame.counterAxisSizingMode = 'FIXED'
  frame.primaryAxisAlignItems = 'CENTER'
  frame.counterAxisAlignItems = 'CENTER'
  frame.resize(Math.max(width, 0.01), Math.max(height, 0.01))
}

function calibrateWidth(text: TextNode, targetWidth: number): void {
  const count = Math.max(text.characters.length, 1)
  if (targetWidth > text.width) {
    text.letterSpacing = { value: (targetWidth - text.width) / count, unit: 'PIXELS' }
  }
}

async function makeText(run: any, font: any): Promise<TextNode> {
  const plan = planText(run, font)
  const text = figma.createText()
  const style = plan.styleName ? textStyles[plan.styleName] : undefined
  if (style) {
    await figma.loadFontAsync(style.fontName as FontName)
    text.fontName = style.fontName as FontName
    text.characters = plan.characters
    await text.setTextStyleIdAsync(style.id)
  } else {
    text.fontName = await resolveFont(plan.fontRequest.family, plan.fontRequest.weight, plan.fontRequest.italic)
    text.characters = plan.characters
    text.fontSize = plan.fontSize
  }
  if (plan.fill) text.fills = [solid(plan.fill.color, plan.fill.token)]
  if (plan.underline) {
    text.textDecoration = 'UNDERLINE'
    text.textDecorationOffset = { value: 2, unit: 'PIXELS' }
  }
  if (plan.letterSpacing !== null) text.letterSpacing = { value: plan.letterSpacing, unit: 'PIXELS' }
  text.textAutoResize = plan.autoResize
  if (plan.width !== null) text.resize(plan.width, text.height)
  if (plan.lineHeight !== null) text.lineHeight = { value: plan.lineHeight, unit: 'PIXELS' }
  return text
}

function collectRunTexts(node: any): string[] {
  const out: string[] = []
  const walk = (current: any) => {
    if (current.texts) for (const run of current.texts) out.push(run.text)
    if (current.children) for (const child of current.children) walk(child)
  }
  if (node.children) for (const child of node.children) walk(child)
  return out
}

async function applyInstanceContent(instance: InstanceNode, node: any): Promise<void> {
  if (node.fill) instance.fills = [solid(node.fill, node.fillToken)]

  const nested = node.children && node.children.length ? collectRunTexts(node) : []
  if (nested.length) {
    const nestedTexts = instance.findAllWithCriteria({ types: ['TEXT'] }) as TextNode[]
    for (let index = 0; index < nestedTexts.length && index < nested.length; index += 1) {
      const text = nestedTexts[index]
      if (text.fontName !== figma.mixed) await figma.loadFontAsync(text.fontName as FontName)
      text.characters = nested[index]
    }
    return
  }

  const runs: any[] = node.texts || []
  if (!runs.length) return
  const texts = instance.findAllWithCriteria({ types: ['TEXT'] }) as TextNode[]
  for (let index = 0; index < texts.length && index < runs.length; index += 1) {
    const text = texts[index]
    const style = node.font && node.font.style ? textStyles[node.font.style] : undefined
    if (style) {
      await figma.loadFontAsync(style.fontName as FontName)
      text.fontName = style.fontName as FontName
      text.characters = runs[index].text
      await text.setTextStyleIdAsync(style.id)
    } else if (node.font) {
      text.fontName = await resolveFont(node.font.family, node.font.weight, node.font.italic)
      text.characters = runs[index].text
    } else {
      await figma.loadFontAsync(text.fontName as FontName)
      text.characters = runs[index].text
    }
    if (node.font && node.font.color) text.fills = [solid(node.font.color, node.font.colorToken)]
    calibrateWidth(text, runs[index].w)
  }
}

async function build(node: any, parent: BaseNode & ChildrenMixin, parentX: number, parentY: number, flow: boolean, insideComponent: boolean = false): Promise<SceneNode> {
  if (node.grow) {
    const spacer = figma.createFrame()
    parent.appendChild(spacer)
    spacer.name = 'Spacer'
    spacer.fills = []
    spacer.resize(1, 1)
    spacer.layoutGrow = 1
    return spacer
  }
  if (node.image) {
    const rect = figma.createRectangle()
    parent.appendChild(rect)
    rect.resize(Math.max(node.w, 0.01), Math.max(node.h, 0.01))
    if (!flow) {
      rect.x = node.x - parentX
      rect.y = node.y - parentY
    }
    rect.name = node.component || 'image'
    const source = darkMode && node.imageDark ? node.imageDark : node.image
    const image = figma.createImage(figma.base64Decode(source))
    rect.fills = [{ type: 'IMAGE', imageHash: image.hash, scaleMode: 'FILL' }]
    return rect
  }

  if (flow && node.font && node.texts && node.texts.length === 1 && !(node.children && node.children.length) && !node.image) {
    const text = await makeText(node.texts[0], node.font)
    parent.appendChild(text)
    calibrateWidth(text, node.texts[0].w)
    if (node.textAlign === 'center') text.textAlignHorizontal = 'CENTER'
    else if (node.textAlign === 'right') text.textAlignHorizontal = 'RIGHT'
    return text
  }

  if (node.component && masters[node.component]) {
    const instance = masters[node.component].createInstance()
    parent.appendChild(instance)
    instance.resize(Math.max(node.w, 0.01), Math.max(node.h, 0.01))
    if (!flow) {
      instance.x = node.x - parentX
      instance.y = node.y - parentY
    }
    await applyInstanceContent(instance, node)
    return instance
  }

  let frame: FrameNode | ComponentNode
  if (node.component && !insideComponent) {
    const component = figma.createComponent()
    masters[node.component] = component
    frame = component
  } else {
    frame = figma.createFrame()
  }
  frame.name = node.name || node.component || node.tag
  frame.fills = node.fill ? [solid(node.fill, node.fillToken)] : []
  frame.clipsContent = false
  if (node.stroke) {
    frame.strokes = [solid(node.stroke)]
    frame.strokeWeight = node.strokeWidth
  }
  if (node.radius) frame.cornerRadius = node.radius
  const radiusVariable = node.radiusToken && floatVarsByName[node.radiusToken]
  if (radiusVariable) {
    for (const corner of ['topLeftRadius', 'topRightRadius', 'bottomLeftRadius', 'bottomRightRadius'] as const) {
      frame.setBoundVariable(corner, radiusVariable)
    }
  }
  if (typeof node.opacity === 'number') frame.opacity = node.opacity
  parent.appendChild(frame)
  frame.resize(Math.max(node.w, 0.01), Math.max(node.h, 0.01))
  if (!flow) {
    frame.x = node.x - parentX
    frame.y = node.y - parentY
  }

  const childInside = insideComponent || Boolean(node.component)
  if (node.layout) {
    applyAutoLayout(frame, node.layout)
    for (const item of orderChildren(node)) {
      if (item.child) await build(item.child, frame, node.x, node.y, true, childInside)
      else frame.appendChild(await makeText(item.run, node.font))
    }
    const parentIsAutoLayout = frame.parent && 'layoutMode' in frame.parent && (frame.parent as FrameNode).layoutMode !== 'NONE'
    if ((node.children.some((child: any) => child.grow) || node.fillWidth) && parentIsAutoLayout) {
      frame.layoutSizingHorizontal = 'FILL'
    } else if (node.children.some((child: any) => child.grow) && node.w > 1) {
      frame.primaryAxisSizingMode = 'FIXED'
      frame.resize(node.w, Math.max(node.h, 1))
    }
  } else {
    if (node.texts) {
      if (node.textAlign === 'center') centerViaAutoLayout(frame, node.w, node.h)
      for (const run of node.texts) {
        const text = await makeText(run, node.font)
        frame.appendChild(text)
        calibrateWidth(text, run.w)
        if (node.textAlign !== 'center') {
          text.x = run.x - node.x
          text.y = run.y - node.y
        }
      }
    }
    for (const child of node.children) await build(child, frame, node.x, node.y, false, childInside)
  }
  return frame
}

function variableName(token: any): string {
  const base = token.name.replace(/^--/, '')
  if (token.type === 'color') return 'color/' + base
  if (base === 'radius') return 'radius/default'
  if (base.indexOf('radius-') === 0) return 'radius/' + base.slice(7)
  if (base.indexOf('spacing-') === 0) return 'spacing/' + base.slice(8)
  if (base.indexOf('fs-') === 0) return 'type/size/' + base.slice(3)
  if (base.indexOf('wt-') === 0) return 'type/weight/' + base.slice(3)
  if (base.indexOf('lh-') === 0) return 'type/line-height/' + base.slice(3)
  if (base.indexOf('font-') === 0) return 'type/family/' + base.slice(5)
  return 'other/' + base
}

const TOKEN_COLLECTION = 'Pinwheel Tokens'
const LIGHT_MODE = 'Light'
const DARK_MODE = 'Dark'

async function syncTokens(tokens: any[]): Promise<void> {
  const collections = await figma.variables.getLocalVariableCollectionsAsync()
  let collection = collections.find((c) => c.name === TOKEN_COLLECTION)
  if (!collection) collection = figma.variables.createVariableCollection(TOKEN_COLLECTION)
  const lightModeId = collection.modes[0].modeId
  collection.renameMode(lightModeId, LIGHT_MODE)
  let darkModeId: string | null = (collection.modes.find((m) => m.name === DARK_MODE) || {}).modeId || null
  if (!darkModeId) {
    darkModeId = ((): string | null => { try { return collection.addMode(DARK_MODE) } catch { return null } })()
  }
  const existing = await figma.variables.getLocalVariablesAsync()
  const byName: Record<string, Variable> = {}
  for (const v of existing) if (v.variableCollectionId === collection.id) byName[v.name] = v

  let created = 0
  let updated = 0
  floatVarsByName = {}
  for (const token of tokens) {
    const name = variableName(token)
    const type: VariableResolvedDataType = token.type === 'color' ? 'COLOR' : token.type === 'float' ? 'FLOAT' : 'STRING'
    let variable: Variable | undefined = byName[name]
    if (variable && variable.resolvedType !== type) { variable.remove(); variable = undefined }
    if (!variable) { variable = figma.variables.createVariable(name, collection, type); created += 1 } else { updated += 1 }
    if (token.type === 'float') floatVarsByName[token.name] = variable
    const light = token.type === 'float' ? token.float : token.value
    const dark = token.type === 'float' ? token.float : (token.dark || token.value)
    if (light === undefined || light === null) continue
    variable.setValueForMode(lightModeId, light)
    if (darkModeId) variable.setValueForMode(darkModeId, dark)
  }
  figma.notify('Tokens: ' + created + ' created, ' + updated + ' updated' + (darkModeId ? ' (light + dark)' : ' (light only)'))
}

async function syncTextStyles(styles: any[]): Promise<void> {
  textStyles = {}
  const existing = await figma.getLocalTextStylesAsync()
  const byName: Record<string, TextStyle> = {}
  for (const style of existing) byName[style.name] = style
  for (const entry of styles) {
    const name = 'type/' + entry.name
    const fontName = await resolveFont(entry.family, entry.weight, false)
    let style = byName[name]
    if (!style) style = figma.createTextStyle()
    style.name = name
    style.fontName = fontName
    style.fontSize = entry.size
    textStyles[entry.name] = style
  }
}

async function boundVariableName(alias: any): Promise<string | undefined> {
  if (!alias || alias.type !== 'VARIABLE_ALIAS') return undefined
  const variable = await figma.variables.getVariableByIdAsync(alias.id)
  return variable ? variable.name : undefined
}

async function inspectFills(node: any): Promise<any[] | undefined> {
  const fills = node.fills
  if (!fills || fills === figma.mixed || !fills.length) return undefined
  const result: any[] = []
  for (const paint of fills) {
    if (paint.type === 'SOLID') {
      const bound = paint.boundVariables && paint.boundVariables.color
      result.push({ type: 'SOLID', color: paint.color, opacity: paint.opacity, variable: await boundVariableName(bound) })
    } else {
      result.push({ type: paint.type })
    }
  }
  return result
}

async function inspectNode(node: any): Promise<any> {
  const result: any = { type: node.type, name: node.name }
  const box = node.absoluteBoundingBox
  if (box) result.frame = { x: box.x, y: box.y, w: box.width, h: box.height }
  const fills = await inspectFills(node)
  if (fills) result.fills = fills
  if (typeof node.cornerRadius === 'number') result.cornerRadius = node.cornerRadius
  if (node.layoutMode && node.layoutMode !== 'NONE') {
    result.autoLayout = {
      mode: node.layoutMode,
      spacing: node.itemSpacing,
      padding: [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft],
      primarySizing: node.primaryAxisSizingMode,
      counterSizing: node.counterAxisSizingMode,
      primaryAlign: node.primaryAxisAlignItems,
      counterAlign: node.counterAxisAlignItems,
    }
  }
  if (node.type === 'TEXT') {
    result.characters = node.characters
    result.fontName = node.fontName
    result.fontSize = node.fontSize
    if (node.letterSpacing && node.letterSpacing.value) result.letterSpacing = node.letterSpacing.value
    if (typeof node.textStyleId === 'string' && node.textStyleId) {
      const style = await figma.getStyleByIdAsync(node.textStyleId)
      if (style) result.textStyle = style.name
    }
  }
  if (node.type === 'INSTANCE') {
    const main = await node.getMainComponentAsync()
    if (main) result.mainComponent = main.name
    const properties = node.componentProperties
    if (properties) {
      const values: Record<string, any> = {}
      for (const key of Object.keys(properties)) values[key] = properties[key].value
      result.componentProperties = values
    }
  }
  if (node.children && node.children.length) {
    result.children = []
    for (const child of node.children) result.children.push(await inspectNode(child))
  }
  return result
}

// iPhone 17 chrome measurements (points).
const DEVICE_WIDTH = 402
const SAFE_AREA_TOP = 62
const SAFE_AREA_BOTTOM = 34
const MIN_DEVICE_HEIGHT = 874
const DEVICE_CORNER_RADIUS = 55
const STATUS_BAR_PAD_TOP = 2
const STATUS_BAR_PAD_LEFT = 52
const STATUS_BAR_PAD_RIGHT = 32
const CLOCK_FONT_SIZE = 17
const CLOCK_MIN_WIDTH = 44
const ISLAND_WIDTH = 124
const ISLAND_HEIGHT = 37
const ISLAND_CORNER_RADIUS = 19
const ISLAND_TOP = 13.5
const HOME_INDICATOR_WIDTH = 140
const HOME_INDICATOR_HEIGHT = 5
const HOME_INDICATOR_CORNER_RADIUS = 2.5
const HOME_INDICATOR_BOTTOM_GAP = 10

async function wrapInDeviceFrame(content: FrameNode, screenName: string): Promise<FrameNode> {
  const height = Math.max(MIN_DEVICE_HEIGHT, SAFE_AREA_TOP + content.height + SAFE_AREA_BOTTOM)
  const chrome = darkMode ? { r: 1, g: 1, b: 1 } : { r: 0, g: 0, b: 0 }

  const device = figma.createFrame()
  device.name = screenName + ' — iPhone 17'
  figma.currentPage.appendChild(device)
  device.resize(DEVICE_WIDTH, height)
  device.cornerRadius = DEVICE_CORNER_RADIUS
  device.clipsContent = true
  device.fills = content.fills
  device.layoutMode = 'VERTICAL'
  device.primaryAxisSizingMode = 'FIXED'
  device.counterAxisSizingMode = 'FIXED'
  device.primaryAxisAlignItems = 'MIN'
  device.counterAxisAlignItems = 'MIN'
  device.paddingTop = 0
  device.paddingBottom = 0
  device.paddingLeft = 0
  device.paddingRight = 0

  const statusBar = figma.createFrame()
  device.appendChild(statusBar)
  statusBar.name = 'Status Bar'
  statusBar.resize(DEVICE_WIDTH, SAFE_AREA_TOP)
  statusBar.fills = []
  statusBar.clipsContent = false
  statusBar.layoutMode = 'HORIZONTAL'
  statusBar.primaryAxisSizingMode = 'FIXED'
  statusBar.counterAxisSizingMode = 'FIXED'
  statusBar.primaryAxisAlignItems = 'SPACE_BETWEEN'
  statusBar.counterAxisAlignItems = 'CENTER'
  statusBar.itemSpacing = 0
  statusBar.paddingTop = STATUS_BAR_PAD_TOP
  statusBar.paddingBottom = 0
  statusBar.paddingLeft = STATUS_BAR_PAD_LEFT
  statusBar.paddingRight = STATUS_BAR_PAD_RIGHT

  const time = figma.createText()
  statusBar.appendChild(time)
  time.name = 'Time'
  time.fontName = await resolveFont('SF Pro', 500, false)
  time.characters = '9:41'
  time.fontSize = CLOCK_FONT_SIZE
  time.fills = [{ type: 'SOLID', color: chrome }]
  time.minWidth = CLOCK_MIN_WIDTH
  time.textAlignHorizontal = 'RIGHT'
  time.leadingTrim = 'CAP_HEIGHT'

  const indicators = figma.createNodeFromSvg(statusIndicatorsSvg(chrome))
  statusBar.appendChild(indicators)
  indicators.name = 'Indicators'

  const island = figma.createRectangle()
  statusBar.appendChild(island)
  island.name = 'Dynamic Island'
  island.resize(ISLAND_WIDTH, ISLAND_HEIGHT)
  island.cornerRadius = ISLAND_CORNER_RADIUS
  island.fills = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }]
  island.layoutPositioning = 'ABSOLUTE'
  island.x = (DEVICE_WIDTH - ISLAND_WIDTH) / 2
  island.y = ISLAND_TOP

  device.appendChild(content)
  content.layoutSizingHorizontal = 'FILL'
  device.itemSpacing = 0

  const home = figma.createRectangle()
  device.appendChild(home)
  home.layoutPositioning = 'ABSOLUTE'
  home.name = 'Home Indicator'
  home.resize(HOME_INDICATOR_WIDTH, HOME_INDICATOR_HEIGHT)
  home.x = (DEVICE_WIDTH - HOME_INDICATOR_WIDTH) / 2
  home.y = height - HOME_INDICATOR_BOTTOM_GAP
  home.cornerRadius = HOME_INDICATOR_CORNER_RADIUS
  home.fills = [{ type: 'SOLID', color: chrome }]

  return device
}

function statusIndicatorsSvg(color: RGB): string {
  const c = 'rgb(' + Math.round(color.r * 255) + ',' + Math.round(color.g * 255) + ',' + Math.round(color.b * 255) + ')'
  return '<svg width="80" height="13" viewBox="0 0 80 13" xmlns="http://www.w3.org/2000/svg">'
    + '<rect x="0" y="7" width="3" height="6" rx="1" fill="' + c + '"/>'
    + '<rect x="4.5" y="5" width="3" height="8" rx="1" fill="' + c + '"/>'
    + '<rect x="9" y="2.5" width="3" height="10.5" rx="1" fill="' + c + '"/>'
    + '<rect x="13.5" y="0" width="3" height="13" rx="1" fill="' + c + '"/>'
    + '<path d="M30 3.2c2.2 0 4.3.85 5.85 2.35l-1.05 1.05C33.5 5.4 31.8 4.7 30 4.7s-3.5.7-4.8 1.9L24.15 5.55C25.7 4.05 27.8 3.2 30 3.2zm0 3.1c1.35 0 2.6.52 3.55 1.4l-1.05 1.05C31.85 8.15 30.95 7.8 30 7.8s-1.85.35-2.5.95L26.45 7.7C27.4 6.82 28.65 6.3 30 6.3zm0 3.05c.55 0 1.05.2 1.45.55L30 10.9l-1.45-1c.4-.35.9-.55 1.45-.55z" fill="' + c + '"/>'
    + '<rect x="46.5" y="1" width="24" height="11" rx="3" fill="none" stroke="' + c + '" stroke-opacity="0.35"/>'
    + '<rect x="48" y="2.5" width="19" height="8" rx="1.5" fill="' + c + '"/>'
    + '<path d="M72 4.3v4.4c.9-.35 1.5-1.15 1.5-2.2s-.6-1.85-1.5-2.2z" fill="' + c + '"/>'
    + '</svg>'
}

figma.ui.onmessage = async (message: any) => {
  try {
    if (message.type === 'inspect') {
      const selection = figma.currentPage.selection
      const roots = selection.length ? selection : figma.currentPage.children
      const name = selection.length ? selection[0].name : figma.currentPage.name
      const nodes: any[] = []
      for (const node of roots) nodes.push(await inspectNode(node))
      figma.ui.postMessage({ type: 'inspected', data: { page: figma.currentPage.name, name, nodes } })
      figma.notify('Inspected ' + roots.length + ' node(s)')
      return
    }
    if (message.type === 'import') {
      const data = message.data
      if (!data || !data.root) {
        figma.notify('Nothing to import — the catalog entry had no document', { error: true })
        return
      }
      if (typeof data.version === 'number' && data.version !== EXPECTED_CAPTURE_VERSION) {
        figma.notify('Stale capture: v' + data.version + ', plugin expects v' + EXPECTED_CAPTURE_VERSION + ' — re-capture', { error: true })
      }
      masters = {}
      darkMode = Boolean(message.dark)
      darkByToken = {}
      if (data.tokens) for (const token of data.tokens) if (token.dark) darkByToken[token.name] = token.dark
      if (data.tokens) await syncTokens(data.tokens)
      if (data.textStyles) await syncTextStyles(data.textStyles)
      await loadColorVars()
      const baseName = data.root.name || 'Screen'
      const name = typeof message.version === 'number' ? baseName + ' · v' + message.version : baseName
      const root = await build(data.root, figma.currentPage, 0, 0, false)
      const framed = root.type === 'FRAME' ? await wrapInDeviceFrame(root as FrameNode, name) : root
      figma.viewport.scrollAndZoomIntoView([framed])
      figma.ui.postMessage({ type: 'done' })
      figma.notify('Imported ' + data.width + '×' + data.height)
    }
  } catch (error) {
    const detail = error && (error as any).message ? (error as any).message : String(error)
    figma.ui.postMessage({ type: 'error', message: String(detail) })
    figma.notify('Import failed: ' + String(error))
  }
}

export { build, syncTokens }
