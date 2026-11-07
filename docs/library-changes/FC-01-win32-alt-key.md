# FC-01 - Deliver the Alt key on the Fresnel Win32 backend

Repository: Fresnel. Needed for: RB-040 (KeyTips start with Alt, as in the Windows ribbon).

## Problem

`src\win32\fresnel.win32.pas` handles `WM_KEYDOWN` and `WM_KEYUP` only. Windows sends Alt, F10 and Alt+key as
`WM_SYSKEYDOWN` and `WM_SYSKEYUP`, so these never reach `TFresnelViewport.WSKey`.

## Change

Route `WM_SYSKEYDOWN` and `WM_SYSKEYUP` through the same code as `WM_KEYDOWN` and `WM_KEYUP`. Return 0 when
`WSKey` reports the event as handled (`PreventDefault`); otherwise call `DefWindowProc`, so Alt+F4 and the system
menu keep working.

## Until then

`TRibbon.KeyTipKey` (default `F6`) and `TRibbon.ShowKeyTips` start KeyTips. The ribbon already reacts to `Alt`
if a backend delivers it, so no ribbon change is needed once this is done.
