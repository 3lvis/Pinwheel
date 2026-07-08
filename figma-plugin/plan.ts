function primaryAlign(value: string): 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN' {
  if (value === 'center') return 'CENTER'
  if (value === 'flex-end' || value === 'end') return 'MAX'
  if (value && value.startsWith('space')) return 'SPACE_BETWEEN'
  return 'MIN'
}

function counterAlign(value: string): 'MIN' | 'CENTER' | 'MAX' | 'BASELINE' {
  if (value === 'center') return 'CENTER'
  if (value === 'flex-end' || value === 'end') return 'MAX'
  if (value === 'baseline') return 'BASELINE'
  return 'MIN'
}

export interface AutoLayoutPlan {
  layoutMode: 'HORIZONTAL' | 'VERTICAL'
  primaryAxisSizingMode: 'FIXED' | 'AUTO'
  counterAxisSizingMode: 'FIXED' | 'AUTO'
  itemSpacing: number
  layoutWrap: 'WRAP' | null
  counterAxisSpacing: number | null
  paddingTop: number
  paddingRight: number
  paddingBottom: number
  paddingLeft: number
  primaryAxisAlignItems: 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN'
  counterAxisAlignItems: 'MIN' | 'CENTER' | 'MAX' | 'BASELINE'
  minWidth: number | null
}

export function planAutoLayout(layout: any): AutoLayoutPlan {
  const horizontal = layout.mode === 'row'
  const wrap = Boolean(layout.wrap && horizontal)
  let primaryAxisAlignItems: AutoLayoutPlan['primaryAxisAlignItems']
  let counterAxisAlignItems: AutoLayoutPlan['counterAxisAlignItems']
  if (layout.grid) {
    primaryAxisAlignItems = primaryAlign(layout.alignContent)
    const cross = layout.justify && layout.justify !== 'normal' ? layout.justify : layout.justifyItems
    counterAxisAlignItems = counterAlign(cross)
  } else {
    primaryAxisAlignItems = primaryAlign(layout.justify)
    counterAxisAlignItems = counterAlign(layout.align)
  }
  return {
    layoutMode: horizontal ? 'HORIZONTAL' : 'VERTICAL',
    primaryAxisSizingMode: layout.primarySizing || 'FIXED',
    counterAxisSizingMode: layout.counterSizing || 'FIXED',
    itemSpacing: (horizontal ? layout.columnGap : layout.rowGap) || 0,
    layoutWrap: wrap ? 'WRAP' : null,
    counterAxisSpacing: wrap ? layout.rowGap || 0 : null,
    paddingTop: layout.pad[0],
    paddingRight: layout.pad[1],
    paddingBottom: layout.pad[2],
    paddingLeft: layout.pad[3],
    primaryAxisAlignItems,
    counterAxisAlignItems,
    minWidth: typeof layout.minWidth === 'number' ? layout.minWidth : null,
  }
}

export interface TextPlan {
  characters: string
  fontSize: number
  styleName?: string
  fontRequest: { family: string; weight: number; italic: boolean }
  fill: { color: { r: number; g: number; b: number; a: number }; token?: string } | null
  underline: boolean
  letterSpacing: number | null
  autoResize: 'HEIGHT' | 'WIDTH_AND_HEIGHT'
  width: number | null
  lineHeight: number | null
}

export function orderChildren(node: any): Array<{ child?: any; run?: any }> {
  if (node.ordered) return (node.children || []).map((child: any) => ({ child }))
  const ROW_TOLERANCE = 8
  const items: Array<{ x: number; y: number; child?: any; run?: any }> = (node.children || []).map((child: any) => ({ x: child.x, y: child.y, child }))
  if (node.texts) for (const run of node.texts) items.push({ x: run.x, y: run.y, run })
  items.sort((a, b) => (Math.abs(a.y - b.y) > ROW_TOLERANCE ? a.y - b.y : a.x - b.x))
  return items.map(({ child, run }) => (child ? { child } : { run }))
}

export function planText(run: any, font: any): TextPlan {
  const multiline = typeof run.w === 'number' && run.w > 0 && typeof run.h === 'number' && run.h > font.size * 1.5
  return {
    characters: run.text,
    fontSize: font.size,
    styleName: font.style,
    fontRequest: { family: font.family, weight: font.weight, italic: font.italic },
    fill: font.color ? { color: font.color, token: font.colorToken } : null,
    underline: Boolean(font.underline),
    letterSpacing: typeof font.letterSpacing === 'number' ? font.letterSpacing : null,
    autoResize: multiline ? 'HEIGHT' : 'WIDTH_AND_HEIGHT',
    width: multiline ? run.w : null,
    lineHeight: !multiline && typeof run.h === 'number' && run.h > 0 ? run.h : null,
  }
}
