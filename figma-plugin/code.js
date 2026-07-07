"use strict";
/// <reference types="@figma/plugin-typings" />
// Edit this file, not the generated code.js (what manifest.json loads). Compiled by
// `npm run figma:build` — tsc, target ES2017 — which down-levels syntax the plugin VM rejects
// (e.g. ES2019 optional catch binding), so VM-incompatible code can't ship.
figma.showUI(__html__, { width: 340, height: 520 });
// A weight maps to different style names across families — SF Pro Rounded is "Semibold",
// Inter is "Semi Bold". Try each alias so a family match isn't missed (which is what dropped
// the 600-weight buttons to the Inter fallback).
const WEIGHT_ALIASES = {
    100: ['Thin'], 200: ['Extra Light', 'ExtraLight'], 300: ['Light'], 400: ['Regular'],
    500: ['Medium'], 600: ['Semibold', 'Semi Bold', 'SemiBold'], 700: ['Bold'],
    800: ['Extra Bold', 'ExtraBold'], 900: ['Black', 'Heavy'],
};
// The capture IR shape this plugin understands; a document stamped with a different version is a
// stale capture (pushed by an older/newer app build) and won't render faithfully.
const EXPECTED_CAPTURE_VERSION = 1;
const loaded = new Set();
let masters = {};
// Falls back to Inter (always present): the app uses system-ui, which Figma lacks, and Inter is the
// chosen product typeface, so the fallback is intended.
async function resolveFont(family, weight, italic) {
    const bases = WEIGHT_ALIASES[Math.round(weight / 100) * 100] || ['Regular'];
    for (const candidate of [family, 'Inter']) {
        for (const base of bases) {
            const style = italic ? `${base} Italic` : base;
            const key = `${candidate}|${style}`;
            if (loaded.has(key))
                return { family: candidate, style };
            const available = await figma.loadFontAsync({ family: candidate, style }).then(() => true, () => false);
            if (available) {
                loaded.add(key);
                return { family: candidate, style };
            }
        }
    }
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    return { family: 'Inter', style: 'Regular' };
}
let colorVars = {};
let colorVarsByName = {};
let textStyles = {};
// The "Dark" toggle paints dark values directly (unbound), so it works without the paid variable-mode feature.
let darkMode = false;
let darkByToken = {};
function colorKey(c) {
    var _a;
    const to255 = (x) => Math.round(x * 255);
    return `${to255(c.r)},${to255(c.g)},${to255(c.b)},${Math.round(((_a = c.a) !== null && _a !== void 0 ? _a : 1) * 100)}`;
}
async function loadColorVars() {
    colorVars = {};
    colorVarsByName = {};
    for (const variable of await figma.variables.getLocalVariablesAsync('COLOR')) {
        colorVarsByName[variable.name] = variable;
        const value = variable.valuesByMode[Object.keys(variable.valuesByMode)[0]];
        if (value && typeof value === 'object' && 'r' in value)
            colorVars[colorKey(value)] = variable;
    }
}
// Binds to a token variable by name first (a captured fill carries its token, e.g. `actionText`),
// then by colour value; two tokens sharing a colour can't be told apart by value alone.
function solid(color, token) {
    if (darkMode && token && darkByToken[token]) {
        const d = darkByToken[token];
        return { type: 'SOLID', color: { r: d.r, g: d.g, b: d.b }, opacity: d.a };
    }
    const paint = { type: 'SOLID', color: { r: color.r, g: color.g, b: color.b }, opacity: color.a };
    const variable = (token && colorVarsByName['color/' + token]) || colorVars[colorKey(color)];
    return variable ? figma.variables.setBoundVariableForPaint(paint, 'color', variable) : paint;
}
function primaryAlign(value) {
    if (value === 'center')
        return 'CENTER';
    if (value === 'flex-end' || value === 'end')
        return 'MAX';
    if (value && value.startsWith('space'))
        return 'SPACE_BETWEEN';
    return 'MIN';
}
function counterAlign(value) {
    if (value === 'center')
        return 'CENTER';
    if (value === 'flex-end' || value === 'end')
        return 'MAX';
    if (value === 'baseline')
        return 'BASELINE';
    return 'MIN';
}
function applyAutoLayout(frame, layout) {
    const horizontal = layout.mode === 'row';
    frame.layoutMode = horizontal ? 'HORIZONTAL' : 'VERTICAL';
    // AUTO hugs (frame reflows); FIXED fills (a space-between row needs it to hold the split). The
    // web capture omits these and keeps the fixed sizes it measured.
    frame.primaryAxisSizingMode = layout.primarySizing || 'FIXED';
    frame.counterAxisSizingMode = layout.counterSizing || 'FIXED';
    frame.itemSpacing = (horizontal ? layout.columnGap : layout.rowGap) || 0;
    if (layout.wrap && horizontal) {
        frame.layoutWrap = 'WRAP';
        frame.counterAxisSpacing = layout.rowGap || 0;
    }
    frame.paddingTop = layout.pad[0];
    frame.paddingRight = layout.pad[1];
    frame.paddingBottom = layout.pad[2];
    frame.paddingLeft = layout.pad[3];
    if (layout.grid) {
        // Grid: the main (vertical) axis is align-content; the cross (horizontal) axis is centered via
        // justify-content or justify-items — NOT align-items (which controls the cross axis in flex).
        frame.primaryAxisAlignItems = primaryAlign(layout.alignContent);
        const cross = layout.justify && layout.justify !== 'normal' ? layout.justify : layout.justifyItems;
        frame.counterAxisAlignItems = counterAlign(cross);
    }
    else {
        frame.primaryAxisAlignItems = primaryAlign(layout.justify);
        frame.counterAxisAlignItems = counterAlign(layout.align);
    }
    // A hugging frame keeps this floor, so a short-label instance doesn't reflow below the real
    // control's minimum width (a PinButton's 100pt titled pill).
    if (typeof layout.minWidth === 'number')
        frame.minWidth = layout.minWidth;
}
// Not absolute x/y: you can't set x/y on a node inside an instance, and auto-layout
// re-centers an instance's own (shorter/longer) text override for free.
function centerViaAutoLayout(frame, width, height) {
    frame.layoutMode = 'HORIZONTAL';
    frame.primaryAxisSizingMode = 'FIXED';
    frame.counterAxisSizingMode = 'FIXED';
    frame.primaryAxisAlignItems = 'CENTER';
    frame.counterAxisAlignItems = 'CENTER';
    frame.resize(Math.max(width, 0.01), Math.max(height, 0.01));
}
// Figma renders SF Pro Rounded at a slightly different optical spacing than iOS. Rather than
// hardcode per-size tracking, the plugin (running inside Figma) measures its own rendered width
// and adds exactly the letter-spacing needed to hit the device-captured width.
function calibrateWidth(text, targetWidth) {
    const count = Math.max(text.characters.length, 1);
    if (targetWidth > text.width) {
        text.letterSpacing = { value: (targetWidth - text.width) / count, unit: 'PIXELS' };
    }
}
async function makeText(run, font) {
    const text = figma.createText();
    const style = font.style ? textStyles[font.style] : undefined;
    if (style) {
        await figma.loadFontAsync(style.fontName);
        // Put the node on the (loaded) style font before writing characters — a fresh text
        // node defaults to the unloaded "Inter Regular", which can't be written to.
        text.fontName = style.fontName;
        text.characters = run.text;
        await text.setTextStyleIdAsync(style.id);
    }
    else {
        text.fontName = await resolveFont(font.family, font.weight, font.italic);
        text.characters = run.text;
        text.fontSize = font.size;
    }
    if (font.color)
        text.fills = [solid(font.color, font.colorToken)];
    if (font.underline) {
        text.textDecoration = 'UNDERLINE';
        // iOS draws the underline 2.84pt below the baseline; Figma's AUTO sits ~2pt lower, so raise it.
        text.textDecorationOffset = { value: 2, unit: 'PIXELS' };
    }
    if (font.letterSpacing) {
        const letterSpacing = { value: font.letterSpacing, unit: 'PIXELS' };
        text.letterSpacing = letterSpacing;
    }
    // A label captured taller than a single line wrapped on device (its height is N line boxes). Pin the
    // captured width and let the height grow so Figma re-wraps it the same way, instead of laying it out on
    // one line that overflows the frame. A single-line label hugs and pins its line box to the captured
    // height so vertical centering lands where iOS drew it (Figma's SF Pro line box is a hair taller).
    if (typeof run.w === 'number' && run.w > 0 && typeof run.h === 'number' && run.h > font.size * 1.5) {
        text.textAutoResize = 'HEIGHT';
        text.resize(run.w, text.height);
    }
    else {
        text.textAutoResize = 'WIDTH_AND_HEIGHT';
        if (typeof run.h === 'number' && run.h > 0) {
            text.lineHeight = { value: run.h, unit: 'PIXELS' };
        }
    }
    return text;
}
function collectRunTexts(node) {
    const out = [];
    const walk = (current) => {
        if (current.texts)
            for (const run of current.texts)
                out.push(run.text);
        if (current.children)
            for (const child of current.children)
                walk(child);
    };
    if (node.children)
        for (const child of node.children)
            walk(child);
    return out;
}
// An instance inherits the master's text and fill; override them so repeats of a component
// (two Buttons: "Pay now" / "Cancel") show their own captured content, not the first one's.
async function applyInstanceContent(instance, node) {
    if (node.fill)
        instance.fills = [solid(node.fill, node.fillToken)];
    // A container instance (a list row): override only the nested text by position — the master's
    // per-label styling and native-bit image (chevron/switch) are inherited unchanged.
    const nested = node.children && node.children.length ? collectRunTexts(node) : [];
    if (nested.length) {
        const nestedTexts = instance.findAllWithCriteria({ types: ['TEXT'] });
        for (let index = 0; index < nestedTexts.length && index < nested.length; index += 1) {
            const text = nestedTexts[index];
            if (text.fontName !== figma.mixed)
                await figma.loadFontAsync(text.fontName);
            text.characters = nested[index];
        }
        return;
    }
    const runs = node.texts || [];
    if (!runs.length)
        return;
    const texts = instance.findAllWithCriteria({ types: ['TEXT'] });
    for (let index = 0; index < texts.length && index < runs.length; index += 1) {
        const text = texts[index];
        const style = node.font && node.font.style ? textStyles[node.font.style] : undefined;
        if (style) {
            await figma.loadFontAsync(style.fontName);
            text.fontName = style.fontName;
            text.characters = runs[index].text;
            await text.setTextStyleIdAsync(style.id);
        }
        else if (node.font) {
            text.fontName = await resolveFont(node.font.family, node.font.weight, node.font.italic);
            text.characters = runs[index].text;
        }
        else {
            await figma.loadFontAsync(text.fontName);
            text.characters = runs[index].text;
        }
        if (node.font && node.font.color)
            text.fills = [solid(node.font.color, node.font.colorToken)];
        calibrateWidth(text, runs[index].w);
    }
}
async function build(node, parent, parentX, parentY, flow, insideComponent = false) {
    if (node.grow) {
        // A SwiftUI Spacer: a transparent flow child that eats the slack, so one Spacer pushes its
        // neighbours apart (Figma has no per-gap flex, but a growing child reproduces it exactly).
        const spacer = figma.createFrame();
        parent.appendChild(spacer);
        spacer.name = 'Spacer';
        spacer.fills = [];
        spacer.resize(1, 1);
        spacer.layoutGrow = 1;
        return spacer;
    }
    if (node.image) {
        const rect = figma.createRectangle();
        parent.appendChild(rect);
        rect.resize(Math.max(node.w, 0.01), Math.max(node.h, 0.01));
        if (!flow) {
            rect.x = node.x - parentX;
            rect.y = node.y - parentY;
        }
        rect.name = node.component || 'image';
        const source = darkMode && node.imageDark ? node.imageDark : node.image;
        const image = figma.createImage(figma.base64Decode(source));
        rect.fills = [{ type: 'IMAGE', imageHash: image.hash, scaleMode: 'FILL' }];
        return rect;
    }
    // A captured text label inside an auto-layout parent: build a bare text node (which hugs), not a
    // fixed-size frame. Otherwise a reused row's longer text ("$30" overriding the master's "$3")
    // overflows the frame sized for the master and overlaps the next item instead of pushing it.
    if (flow && node.font && node.texts && node.texts.length === 1 && !(node.children && node.children.length) && !node.image) {
        const text = await makeText(node.texts[0], node.font);
        parent.appendChild(text);
        // Match the device-captured text width so the hugging parent (a button pill) doesn't reflow
        // narrower than the real control — Figma renders SF Pro at a slightly tighter metric.
        calibrateWidth(text, node.texts[0].w);
        // A multi-line label carries its paragraph alignment on the node; the wrapped lines must match it,
        // else a centered empty-state message (Tweakable) renders left-aligned. The non-flow path centers
        // via an auto-layout wrapper, but a bare flow text sets its own paragraph alignment.
        if (node.textAlign === 'center')
            text.textAlignHorizontal = 'CENTER';
        else if (node.textAlign === 'right')
            text.textAlignHorizontal = 'RIGHT';
        return text;
    }
    if (node.component && masters[node.component]) {
        const instance = masters[node.component].createInstance();
        parent.appendChild(instance);
        instance.resize(Math.max(node.w, 0.01), Math.max(node.h, 0.01));
        if (!flow) {
            instance.x = node.x - parentX;
            instance.y = node.y - parentY;
        }
        await applyInstanceContent(instance, node);
        return instance;
    }
    // Figma forbids a component inside a component, so only mint a master at the top level; a
    // component-tagged node nested in one (a row's labels) becomes a plain frame — the row is the
    // reusable unit, its labels are just its content.
    let frame;
    if (node.component && !insideComponent) {
        const component = figma.createComponent();
        masters[node.component] = component;
        frame = component;
    }
    else {
        frame = figma.createFrame();
    }
    frame.name = node.name || node.component || node.tag;
    frame.fills = node.fill ? [solid(node.fill, node.fillToken)] : [];
    frame.clipsContent = false;
    if (node.stroke) {
        frame.strokes = [solid(node.stroke)];
        frame.strokeWeight = node.strokeWidth;
    }
    if (node.radius)
        frame.cornerRadius = node.radius;
    if (typeof node.opacity === 'number')
        frame.opacity = node.opacity;
    parent.appendChild(frame);
    frame.resize(Math.max(node.w, 0.01), Math.max(node.h, 0.01));
    if (!flow) {
        frame.x = node.x - parentX;
        frame.y = node.y - parentY;
    }
    const childInside = insideComponent || Boolean(node.component);
    if (node.layout) {
        applyAutoLayout(frame, node.layout);
        if (node.ordered) {
            // A reflection-synthesized stack already carries its children in declaration order (and a
            // zero-origin Spacer would sort to the front) — keep the given order, don't sort by geometry.
            for (const child of node.children)
                await build(child, frame, node.x, node.y, true, childInside);
        }
        else {
            // Sort children and text runs top-to-bottom by row, then left-to-right within a row: sorting by
            // a single axis scrambles wrapped flex rows (a step wizard wrapping to a second line came out 1,2,4,3).
            const ROW_TOLERANCE = 8;
            const items = node.children.map((child) => ({ x: child.x, y: child.y, child }));
            if (node.texts)
                for (const run of node.texts)
                    items.push({ x: run.x, y: run.y, run });
            items.sort((a, b) => (Math.abs(a.y - b.y) > ROW_TOLERANCE ? a.y - b.y : a.x - b.x));
            for (const item of items) {
                if (item.child)
                    await build(item.child, frame, node.x, node.y, true, childInside);
                else
                    frame.appendChild(await makeText(item.run, node.font));
            }
        }
        // A growing child (Spacer), or a `.frame(maxWidth: .infinity)` leaf, needs to span the parent's
        // width — fill it (a reflection-synthesized row hugs at w=0, so resizing wouldn't help).
        const parentIsAutoLayout = frame.parent && 'layoutMode' in frame.parent && frame.parent.layoutMode !== 'NONE';
        if ((node.children.some((child) => child.grow) || node.fillWidth) && parentIsAutoLayout) {
            frame.layoutSizingHorizontal = 'FILL';
        }
        else if (node.children.some((child) => child.grow) && node.w > 1) {
            frame.primaryAxisSizingMode = 'FIXED';
            frame.resize(node.w, Math.max(node.h, 1));
        }
    }
    else {
        if (node.texts) {
            if (node.textAlign === 'center')
                centerViaAutoLayout(frame, node.w, node.h);
            for (const run of node.texts) {
                const text = await makeText(run, node.font);
                frame.appendChild(text);
                calibrateWidth(text, run.w);
                if (node.textAlign !== 'center') {
                    text.x = run.x - node.x;
                    text.y = run.y - node.y;
                }
            }
        }
        for (const child of node.children)
            await build(child, frame, node.x, node.y, false, childInside);
    }
    return frame;
}
// Slash = folder in a Figma variable name, so tokens group by kind: --spacing-m → spacing/m,
// --fs-title → type/size/title.
function variableName(token) {
    const base = token.name.replace(/^--/, '');
    if (token.type === 'color')
        return 'color/' + base;
    if (base === 'radius')
        return 'radius/default';
    if (base.indexOf('radius-') === 0)
        return 'radius/' + base.slice(7);
    if (base.indexOf('spacing-') === 0)
        return 'spacing/' + base.slice(8);
    if (base.indexOf('fs-') === 0)
        return 'type/size/' + base.slice(3);
    if (base.indexOf('wt-') === 0)
        return 'type/weight/' + base.slice(3);
    if (base.indexOf('lh-') === 0)
        return 'type/line-height/' + base.slice(3);
    if (base.indexOf('font-') === 0)
        return 'type/family/' + base.slice(5);
    return 'other/' + base;
}
// Idempotent: re-syncing updates the same-named variables in place rather than piling up duplicates.
async function syncTokens(tokens) {
    const collections = await figma.variables.getLocalVariableCollectionsAsync();
    let collection = collections.find((c) => c.name === 'Pinwheel Tokens');
    if (!collection)
        collection = figma.variables.createVariableCollection('Pinwheel Tokens');
    const lightModeId = collection.modes[0].modeId;
    collection.renameMode(lightModeId, 'Light');
    // A second mode carries the dark values; adding one needs a paid Figma plan, so degrade to
    // light-only if it's not allowed.
    let darkModeId = (collection.modes.find((m) => m.name === 'Dark') || {}).modeId || null;
    if (!darkModeId) {
        darkModeId = (() => { try {
            return collection.addMode('Dark');
        }
        catch (_a) {
            return null;
        } })();
    }
    const existing = await figma.variables.getLocalVariablesAsync();
    const byName = {};
    for (const v of existing)
        if (v.variableCollectionId === collection.id)
            byName[v.name] = v;
    let created = 0;
    let updated = 0;
    for (const token of tokens) {
        const name = variableName(token);
        const type = token.type === 'color' ? 'COLOR' : token.type === 'float' ? 'FLOAT' : 'STRING';
        let variable = byName[name];
        if (variable && variable.resolvedType !== type) {
            variable.remove();
            variable = undefined;
        }
        if (!variable) {
            variable = figma.variables.createVariable(name, collection, type);
            created += 1;
        }
        else {
            updated += 1;
        }
        // A float token (spacing/radius) carries its value in `float`, not `value`; feeding `value` (undefined)
        // to a FLOAT variable fails setValueForMode with "Required value missing".
        const light = token.type === 'float' ? token.float : token.value;
        const dark = token.type === 'float' ? token.float : (token.dark || token.value);
        if (light === undefined || light === null)
            continue;
        variable.setValueForMode(lightModeId, light);
        if (darkModeId)
            variable.setValueForMode(darkModeId, dark);
    }
    figma.notify('Tokens: ' + created + ' created, ' + updated + ' updated' + (darkModeId ? ' (light + dark)' : ' (light only)'));
}
async function syncTextStyles(styles) {
    textStyles = {};
    const existing = await figma.getLocalTextStylesAsync();
    const byName = {};
    for (const style of existing)
        byName[style.name] = style;
    for (const entry of styles) {
        const name = 'type/' + entry.name;
        const fontName = await resolveFont(entry.family, entry.weight, false);
        let style = byName[name];
        if (!style)
            style = figma.createTextStyle();
        style.name = name;
        style.fontName = fontName;
        style.fontSize = entry.size;
        textStyles[entry.name] = style;
    }
}
// Keep the ES-module keyword (i-m-p-o-r-t) out of comments: the sandbox scans raw source and
// rejects the plugin on a bare occurrence, even inside a comment.
async function boundVariableName(alias) {
    if (!alias || alias.type !== 'VARIABLE_ALIAS')
        return undefined;
    const variable = await figma.variables.getVariableByIdAsync(alias.id);
    return variable ? variable.name : undefined;
}
async function inspectFills(node) {
    const fills = node.fills;
    if (!fills || fills === figma.mixed || !fills.length)
        return undefined;
    const result = [];
    for (const paint of fills) {
        if (paint.type === 'SOLID') {
            const bound = paint.boundVariables && paint.boundVariables.color;
            result.push({ type: 'SOLID', color: paint.color, opacity: paint.opacity, variable: await boundVariableName(bound) });
        }
        else {
            result.push({ type: paint.type });
        }
    }
    return result;
}
async function inspectNode(node) {
    const result = { type: node.type, name: node.name };
    const box = node.absoluteBoundingBox;
    if (box)
        result.frame = { x: box.x, y: box.y, w: box.width, h: box.height };
    const fills = await inspectFills(node);
    if (fills)
        result.fills = fills;
    if (typeof node.cornerRadius === 'number')
        result.cornerRadius = node.cornerRadius;
    if (node.layoutMode && node.layoutMode !== 'NONE') {
        result.autoLayout = {
            mode: node.layoutMode,
            spacing: node.itemSpacing,
            padding: [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft],
            primarySizing: node.primaryAxisSizingMode,
            counterSizing: node.counterAxisSizingMode,
            primaryAlign: node.primaryAxisAlignItems,
            counterAlign: node.counterAxisAlignItems,
        };
    }
    if (node.type === 'TEXT') {
        result.characters = node.characters;
        result.fontName = node.fontName;
        result.fontSize = node.fontSize;
        if (node.letterSpacing && node.letterSpacing.value)
            result.letterSpacing = node.letterSpacing.value;
        if (typeof node.textStyleId === 'string' && node.textStyleId) {
            const style = await figma.getStyleByIdAsync(node.textStyleId);
            if (style)
                result.textStyle = style.name;
        }
    }
    if (node.type === 'INSTANCE') {
        const main = await node.getMainComponentAsync();
        if (main)
            result.mainComponent = main.name;
        const properties = node.componentProperties;
        if (properties) {
            const values = {};
            for (const key of Object.keys(properties))
                values[key] = properties[key].value;
            result.componentProperties = values;
        }
    }
    if (node.children && node.children.length) {
        result.children = [];
        for (const child of node.children)
            result.children.push(await inspectNode(child));
    }
    return result;
}
// Wrap the imported screen in an iPhone 17 device frame — rounded 402×874 with a status bar and a
// home indicator — so an import reads like the real device. Taller than 874 only if the content is.
async function wrapInDeviceFrame(content, screenName) {
    const WIDTH = 402;
    const CONTENT_TOP = 62;
    const HOME_H = 34;
    const height = Math.max(874, CONTENT_TOP + content.height + HOME_H);
    const chrome = darkMode ? { r: 1, g: 1, b: 1 } : { r: 0, g: 0, b: 0 };
    const device = figma.createFrame();
    device.name = screenName + ' — iPhone 17';
    figma.currentPage.appendChild(device);
    device.resize(WIDTH, height);
    device.cornerRadius = 55;
    device.clipsContent = true;
    device.fills = content.fills;
    // The status bar and content stack vertically (a real safe-area layout, not absolute siblings); the
    // home indicator floats absolutely at the bottom.
    device.layoutMode = 'VERTICAL';
    device.primaryAxisSizingMode = 'FIXED';
    device.counterAxisSizingMode = 'FIXED';
    device.primaryAxisAlignItems = 'MIN';
    device.counterAxisAlignItems = 'MIN';
    device.paddingTop = 0;
    device.paddingBottom = 0;
    device.paddingLeft = 0;
    device.paddingRight = 0;
    // Status bar is the first flow child; content follows it. Space-between auto-layout: the time and
    // indicators anchor to the two ears; the island floats absolutely in the middle, out of the flow.
    const statusBar = figma.createFrame();
    device.appendChild(statusBar);
    statusBar.name = 'Status Bar';
    // The bar spans the full safe-area top (iPhone 17 = 62pt), so content flows right after it.
    statusBar.resize(WIDTH, CONTENT_TOP);
    statusBar.fills = [];
    statusBar.clipsContent = false;
    statusBar.layoutMode = 'HORIZONTAL';
    statusBar.primaryAxisSizingMode = 'FIXED';
    statusBar.counterAxisSizingMode = 'FIXED';
    statusBar.primaryAxisAlignItems = 'SPACE_BETWEEN';
    statusBar.counterAxisAlignItems = 'CENTER';
    statusBar.itemSpacing = 0;
    // The clock/indicators ride the Dynamic Island's midline (~y32), 1pt below the bar's center, so a
    // 2pt top pad nudges the centered row down to meet it.
    statusBar.paddingTop = 2;
    statusBar.paddingBottom = 0;
    statusBar.paddingLeft = 52;
    statusBar.paddingRight = 32;
    const time = figma.createText();
    statusBar.appendChild(time);
    time.name = 'Time';
    time.fontName = await resolveFont('SF Pro', 500, false);
    time.characters = '9:41';
    time.fontSize = 17;
    time.fills = [{ type: 'SOLID', color: chrome }];
    // Floor the time width so a shorter string ('9:41') holds the same slot as a wider one ('19:15'),
    // right-aligned so the digits sit at the slot's right edge regardless of length.
    time.minWidth = 44;
    time.textAlignHorizontal = 'RIGHT';
    // Center on the glyphs, not the line box: SF Pro's line box sits ~1pt above the caps, so plain
    // vertical centering floats the clock 1pt above the Dynamic Island's midline.
    time.leadingTrim = 'CAP_HEIGHT';
    const indicators = figma.createNodeFromSvg(statusIndicatorsSvg(chrome));
    statusBar.appendChild(indicators);
    indicators.name = 'Indicators';
    const island = figma.createRectangle();
    statusBar.appendChild(island);
    island.name = 'Dynamic Island';
    island.resize(124, 37);
    island.cornerRadius = 19;
    island.fills = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }];
    island.layoutPositioning = 'ABSOLUTE';
    island.x = (WIDTH - 124) / 2;
    island.y = 13.5;
    // Content flows right after the safe-area-top bar — no gap, no absolute offset.
    device.appendChild(content);
    content.layoutSizingHorizontal = 'FILL';
    device.itemSpacing = 0;
    const home = figma.createRectangle();
    device.appendChild(home);
    home.layoutPositioning = 'ABSOLUTE';
    home.name = 'Home Indicator';
    home.resize(140, 5);
    home.x = (WIDTH - 140) / 2;
    home.y = height - 10;
    home.cornerRadius = 2.5;
    home.fills = [{ type: 'SOLID', color: chrome }];
    return device;
}
// Cellular bars, wifi, and battery, as one vector — the right cluster of the iOS status bar. Sized
// ~80×13 so it centers on the Dynamic Island's vertical midline.
function statusIndicatorsSvg(color) {
    const c = 'rgb(' + Math.round(color.r * 255) + ',' + Math.round(color.g * 255) + ',' + Math.round(color.b * 255) + ')';
    return '<svg width="80" height="13" viewBox="0 0 80 13" xmlns="http://www.w3.org/2000/svg">'
        + '<rect x="0" y="7" width="3" height="6" rx="1" fill="' + c + '"/>'
        + '<rect x="4.5" y="5" width="3" height="8" rx="1" fill="' + c + '"/>'
        + '<rect x="9" y="2.5" width="3" height="10.5" rx="1" fill="' + c + '"/>'
        + '<rect x="13.5" y="0" width="3" height="13" rx="1" fill="' + c + '"/>'
        + '<path d="M30 3.2c2.2 0 4.3.85 5.85 2.35l-1.05 1.05C33.5 5.4 31.8 4.7 30 4.7s-3.5.7-4.8 1.9L24.15 5.55C25.7 4.05 27.8 3.2 30 3.2zm0 3.1c1.35 0 2.6.52 3.55 1.4l-1.05 1.05C31.85 8.15 30.95 7.8 30 7.8s-1.85.35-2.5.95L26.45 7.7C27.4 6.82 28.65 6.3 30 6.3zm0 3.05c.55 0 1.05.2 1.45.55L30 10.9l-1.45-1c.4-.35.9-.55 1.45-.55z" fill="' + c + '"/>'
        + '<rect x="46.5" y="1" width="24" height="11" rx="3" fill="none" stroke="' + c + '" stroke-opacity="0.35"/>'
        + '<rect x="48" y="2.5" width="19" height="8" rx="1.5" fill="' + c + '"/>'
        + '<path d="M72 4.3v4.4c.9-.35 1.5-1.15 1.5-2.2s-.6-1.85-1.5-2.2z" fill="' + c + '"/>'
        + '</svg>';
}
figma.ui.onmessage = async (message) => {
    try {
        if (message.type === 'inspect') {
            const selection = figma.currentPage.selection;
            const roots = selection.length ? selection : figma.currentPage.children;
            const name = selection.length ? selection[0].name : figma.currentPage.name;
            const nodes = [];
            for (const node of roots)
                nodes.push(await inspectNode(node));
            figma.ui.postMessage({ type: 'inspected', data: { page: figma.currentPage.name, name, nodes } });
            figma.notify('Inspected ' + roots.length + ' node(s)');
            return;
        }
        if (message.type === 'import') {
            const data = message.data;
            if (!data || !data.root) {
                figma.notify('Nothing to import — the catalog entry had no document', { error: true });
                return;
            }
            if (typeof data.version === 'number' && data.version !== EXPECTED_CAPTURE_VERSION) {
                figma.notify('Stale capture: v' + data.version + ', plugin expects v' + EXPECTED_CAPTURE_VERSION + ' — re-capture', { error: true });
            }
            masters = {};
            darkMode = Boolean(message.dark);
            darkByToken = {};
            if (data.tokens)
                for (const token of data.tokens)
                    if (token.dark)
                        darkByToken[token.name] = token.dark;
            // Sync first so the token variables exist on a single "Import layers" click — fills bind
            // without a separate "Sync tokens" pass (the ordering that left them unbound before).
            if (data.tokens)
                await syncTokens(data.tokens);
            if (data.textStyles)
                await syncTextStyles(data.textStyles);
            await loadColorVars();
            // Stamp the app's capture version onto the frame name so the imported artifact carries the same
            // number the simulator shows — "10 in the sim = 10 in Figma".
            const baseName = data.root.name || 'Screen';
            const name = typeof message.version === 'number' ? baseName + ' · v' + message.version : baseName;
            const root = await build(data.root, figma.currentPage, 0, 0, false);
            const framed = root.type === 'FRAME' ? await wrapInDeviceFrame(root, name) : root;
            figma.viewport.scrollAndZoomIntoView([framed]);
            figma.ui.postMessage({ type: 'done' });
            figma.notify('Imported ' + data.width + '×' + data.height);
        }
    }
    catch (error) {
        const detail = error && error.message ? error.message : String(error);
        figma.ui.postMessage({ type: 'error', message: String(detail) });
        figma.notify('Import failed: ' + String(error));
    }
};
