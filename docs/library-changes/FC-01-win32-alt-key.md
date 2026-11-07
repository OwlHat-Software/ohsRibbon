# FC-01 - Deliver the Alt key on the Fresnel Win32 backend

Repository: Fresnel. Needed for: RB-040 (KeyTips start with Alt, as in the Windows ribbon).

## Problem

`src\win32\fresnel.win32.pas` handles `WM_KEYDOWN` and `WM_KEYUP` only. Windows sends Alt, F10 and Alt+key as
`WM_SYSKEYDOWN` and `WM_SYSKEYUP`, so these never reach `TFresnelViewport.WSKey`.

## Change

Route `WM_SYSKEYDOWN` and `WM_SYSKEYUP` through the same code as `WM_KEYDOWN` and `WM_KEYUP`. Return 0 when
`WSKey` reports the event as handled (`PreventDefault`); otherwise call `DefWindowProc`, so Alt+F4 and the system
menu keep working.

## Status

Applied in Fresnel as `8370b3d5`. Alt now starts KeyTips; `TRibbon.KeyTipKey` (default `F6`) still works next to it.
