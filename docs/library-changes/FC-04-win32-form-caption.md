# FC-04 - The Win32 backend does not set the window title

Repository: Fresnel. Found while building the title bar of the demo. It affects every Fresnel application on Win32.

## Problem

In `src\win32\fresnel.win32.pas`, `TWin32WSForm.SetCaption` and `GetCaption` are still to do. `SetCaption` does
nothing and `GetCaption` raises, so every window keeps the title `FormTitle` from `CreateWSWindow`, also in the
taskbar and in Alt+Tab.

## Change

Set and read the title with `SetWindowTextW` and `GetWindowTextW`, converting from and to UTF-8.

`TFresnelCustomForm.SetCaption` only passes a caption on if the window exists. `CreateWSForm` should also pass the
caption set before that, or the form's first title is lost.

## Until then

The demo sets the title itself: `TWindowFrame.SetTitle` in `demo\ribbonframe.pas`. The ribbon library does not need
this change.
