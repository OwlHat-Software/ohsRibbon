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
VK_F1..VK_F24 : Result:=TKeyCodes.F1-(aKey-VK_F1);
```

Check first that `F1` to `F24` are consecutive in `TKeyCodes`.

## Until then

`TRibbon.IsKeyTipKey` also accepts the wrong code for its key. Once this is fixed that code is never sent, so the
check does nothing and can be removed. Until then the Kana key on a Japanese keyboard also starts KeyTips.
