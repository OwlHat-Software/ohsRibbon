# FC-05 - Deliver the Alt key on the Fresnel GTK3 backend

Repository: Fresnel. Needed for: RB-040 on Linux (KeyTips start with Alt). The counterpart of FC-01.

## Problem

`GdkKeyToFresnelKey` in `src\gtk3\fresnel.gtk3.pas` maps Shift, Control and Meta, but not Alt. Pressing Alt gives
`NumKey` 0 and no key name, so nothing can react to it.

## Change

Map `GDK_KEY_Alt_L` and `GDK_KEY_Alt_R` to `TKeyCodes.Alt`. AltGr stays as it is.

## Not in this change

`GDK_KEY_F1 .. GDK_KEY_F24` steps down from `F1`, but `F21` does not follow `F20` in `TKeyCodes`, so F21 to F24 give
the wrong key on GTK3 (see FC-03). The ribbon does not depend on those keys.

## Status

Applied in Fresnel as `8f655c74`.
