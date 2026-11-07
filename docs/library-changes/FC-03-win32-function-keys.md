# FC-03 - The Win32 backend reports F2 to F24 with the wrong key

Repository: Fresnel. Found with real key input while testing RB-040. It affects every Fresnel application on Win32.

## Problem

`WinKeyToFresnelKey` in `src\win32\fresnel.win32.pas` has:

```pascal
VK_F1..VK_F24 : Result:=TKeyCodes.F1+(aKey-VK_F1);
```

The codes in `TKeyCodes` count downward (`F1 = SpecialKeysOffset - 92`, `F2 = SpecialKeysOffset - 93`), so adding
goes the wrong way. Only F1 is right. F6 becomes `SpecialKeysOffset - 87`, which is `KanaMode`.

## Change

```pascal
VK_F1..VK_F20  : Result:=TKeyCodes.F1-(aKey-VK_F1);
VK_F21..VK_F24 : Result:=TKeyCodes.F21-(aKey-VK_F21);
```

`F21` does not follow `F20` in `TKeyCodes`, so those four need their own line.

## Status

Applied in Fresnel as `8370b3d5`. The check for the wrong code in the ribbon is removed.
