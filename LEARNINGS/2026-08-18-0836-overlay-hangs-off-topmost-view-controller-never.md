**The overlay hangs off the topmost view controller, never straight off the window.** A
`UIHostingController`'s view has to live inside its parent controller's own view tree; parenting the
hosting controllers to the presenter while adding their views to the window raises
`_associatedViewControllerForwardsAppearanceCallbacks` and kills the app on first present. Walking
`presentedViewController` to the top also puts the tray above whatever is currently presented.
*— Elvis, 2026-08-18 08:36*
