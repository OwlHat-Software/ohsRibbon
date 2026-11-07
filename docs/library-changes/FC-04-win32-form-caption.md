# FC-04 - The Win32 backend does not set the window title

Repository: Fresnel. Found while building the title bar of the demo. It affects every Fresnel application on Win32.

## Problem

In `src\win32\fresnel.win32.pas`, `TWin32WSForm.SetCaption` and `GetCaption` are still to do. `SetCaption` does
nothing and `GetCaption` raises, so every window keeps the title `FormTitle` from `CreateWSWindow`, also in the
taskbar and in Alt+Tab.

## Change

Set and read the title with `DefWindowProcW` and `WM_SETTEXT` and `WM_GETTEXT`, converting from and to UTF-8. The window
class is ANSI, so `SetWindowTextW` goes through the code page and turns other characters into `?`.

`TFresnelCustomForm.SetCaption` only passes a caption on if the window exists, so `CreateWSWindow` also sets the
caption of the form if it has one, much as the GTK3 backend does.

## Status

A form that never sets a caption keeps the title `FormTitle`, so applications without one do not change.

Applied in Fresnel as `f8412351`. The demo relies on it for its title; the ribbon library does not need it.
