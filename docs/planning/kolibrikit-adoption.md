# KolibriKit Adoption — Plan

Goal: KolibriDemo in `tienda-ios` runs on Pinwheel's catalog instead of its own gallery, so Kolibri
component work gains tweaks, deep-links, device simulation, and a per-component screenshot sweep that
can gate CI.

## Why it pays

KolibriDemo today is a `NavigationStack` over one `GalleryPage` enum carrying a case per page — around
thirty, and one more with every component that lands. The pages hand-roll what a catalog owns: their own
state `Picker`s, their own `.sheet`s, a `UIViewRepresentable` to host a `KUIButton`, and one ad-hoc
`-page <name>` launch argument that every UI test in the target hangs off. Pinwheel already owns all of
that: a registry that doubles as the index and the preview index, `pinwheelTweaks` for named variants,
`.presentation(.medium)`, simulated devices, `PinwheelItem(_:view:)` for UIKit content.

The sweep is the part worth the migration. `tienda-ios`'s own PLAN asks to "sweep every preview and gate
that it renders" — the case that motivated it was 142 app preview blocks resolving
`KolibriTheme.placeholder` for months while every build stayed green, and PLAN still counts roughly forty
of them wrong. Pinwheel's `-PinwheelManifest` dump plus `Scripts/sweep.sh` walks every component id ×
tweak variant × appearance, which is that gate at component granularity.

Two pieces of the gate are still to build, and step 5 owns them. The sweep captures without comparing —
`Scripts/sweep.sh` holds no baseline — so gating means adding a comparison step. And brand is not yet an
axis: `PinwheelPreview` honours `-PinwheelPreviewTheme`, but the sweep never passes it, so a run covers
one theme. Brand coverage is why KolibriDemo wants this, so that axis comes first.

## Done — the theming groundwork

Pinwheel's theme was a single static `Config.colorProvider`/`fontProvider` pair that nothing observed, so
one catalog could only ever show one brand. It is now plural and live:

- `PinwheelTheme` is a named value read through `EnvironmentValues.pinwheelTheme` and bridged to
  `PinwheelThemeTrait`, so SwiftUI, UIKit-hosted items and the floating-controls window resolve one
  selection. This is the shape KolibriKit already uses (`\.kolibriTheme` + `KolibriThemeTrait`).
- `PinwheelThemeTrait.affectsColorAppearance = true`. Without it UIKit keeps a dynamic `UIColor` on the
  theme it was last drawn under, and the tell is a *mixed* result — one brand's icon beside another's.
- A theme carries `buttonShape`, because a silhouette is as much a brand's signature as its palette, and
  a capsule is half the control's height rather than a radius a `CGFloat` could hold.
- The display axes ride `ToolbarItem(placement: .bottomBar)`, and their sheets fit their content via a
  measured `.presentationDetents([.height(h)])`.
- Spacing and radius collapsed from mutable statics to constants; `minimumControlHeight` is the one token
  a row and a CTA share.

**KolibriKit inherits three findings, each with its own cause.**

- `KolibriThemeTrait` declares no `affectsColorAppearance`, so the hundreds of dynamic colours in
  `Generated/SemanticUIColor.swift` — each a `UIColor { $0[KolibriThemeTrait.self]… }` — keep the brand
  they were last drawn under. One line reaches every one of them.
- `KUIButton` takes its theme at `init` and holds it in a `let`, so a brand switch leaves a built instance
  as it was; KolibriDemo's UIKit button preview keys an `.id(...)` off the brand to force a rebuild. This
  is a separate cause, and the trait declaration does not retire it — the button reads a stored value,
  never a trait. Routing `KUIButton` through `SemanticUIColor` is what retires it.
- `theme.components.buttonCornerRadius` is a `CGFloat`, so it cannot express a capsule.

## Remaining

1. **Consumability audit.** Build KolibriKit against Pinwheel once and fix what the compiler names.
   `Config`'s statics under `defaultIsolation(MainActor)` and tools-6.2-vs-`.v5` language mode are the
   known candidates.
2. **Wire Pinwheel into KolibriDemo beside the existing `ContentView`.** Add a `KolibriCatalog` package
   holding the typed `PinwheelComponent` enum, mirroring `DemoCatalog`, so `KolibriDemoUITests` derives
   ids rather than copying slugs. One section, a handful of items, both brands switching live. Prove the
   seam before migrating anything.
3. **Migrate pages to items, section by section.** Tokens first (4 pages, near-mechanical), then
   Components. This is the bulk, and it is judgement work rather than mechanical: a "page" today is often
   many components — `CartComponentsDemo` is 17 sections over six component types — and splitting them is
   exactly what makes deep-links, tweaks and the sweep pay off.
4. **Retire the hand-rolled machinery**: `GalleryPage`, the `-page` argument, the state pickers, the
   `.sheet` calls, the `UIViewRepresentable`.
5. **Port the sweep and gate it.** `Scripts/sweep.sh` becomes `bin/kolibri-sweep` over brand × appearance
   × tweak, then runs in Bitrise `pull_request_run_tests`. `tienda-ios`'s PLAN already wants the
   `KolibriDemo` scheme in `fastlane test`.
6. **The other three demo apps** — `TiendaCoreDemo`, `SupportChatDemo`, `TiendaAPIDemo` — once KolibriDemo
   has proven it.

## The open design question

Pinwheel's nine colour tokens will never be KolibriKit's several hundred semantic tokens, and should not
try. So theming Pinwheel themes the *harness*, while `KButton` and the hundred-odd components beside it
read `\.kolibriTheme` and stay untouched. Same selection, two scopes.

The agreed shape: a `PinwheelTheme` also knows how to project itself into a design system Pinwheel does
not own — the theme is already "the values components read", so extending it from (colours, fonts, shape)
to include that projection keeps one concept rather than adding a parallel axis. It is deliberately
unbuilt: Pinwheel has no consumer for it until step 2 exists, and a seam ships with its first real use.

## Dependency shape

`kolonialno/Pinwheel` is a fork of `3lvis/Pinwheel`; refresh it by fast-forwarding `main` from upstream.
The dependency belongs to KolibriDemo's **app target** only — KolibriKit is a strict leaf that links into
the shipping Oda and Mathem apps, and a demo harness has no business in either. Expect `Package.resolved`
churn in `Tienda.xcworkspace`, which resolves local packages by path today.

## Cost this imposes on upstream code

Code written against the old static theme needs a two-line migration, and the compiler names each site.
Two precedents from the refresh that brought 33 upstream commits: `PinList` referenced the deleted
`PinwheelTheme.Colors` namespace, and `PinStepper` read `PinTextStyle.body.font` as a static property
where it now resolves from the theme. Both were textually clean merges that failed to compile — worth
expecting rather than being surprised by.
