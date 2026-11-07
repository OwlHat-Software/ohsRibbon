# FC-02 - TTextButton raises when the caption of a button with an image is cleared

Repository: Fresnel. Found while building RB-020. The ribbon works around it, so this does not block ohsRibbon.

## Problem

In `src\base\fresnel.controls.pas`, `TTextButton.UpdateManagedContent` ends with:

```pascal
if (FLabelChild<>nil) and (FImageChild<>nil) and (FImageChild.NodeIndex>FLabelChild.NodeIndex) then
  InsertBefore(FImageChild,FLabelChild);
```

Setting `Caption:=''` on a button with an image detaches the label, but keeps `FLabelChild`. Its `NodeIndex` is then
lower than that of the image, so `InsertBefore` runs with a reference child whose parent is nil, and raises
`EFresnel('20250914125844')`. The exception aborts the layout pass.

## Change

Only reorder when both children are attached:

```pascal
if (FLabelChild<>nil) and (FImageChild<>nil) and (FLabelChild.Parent=Self) and (FImageChild.Parent=Self)
    and (FImageChild.NodeIndex>FLabelChild.NodeIndex) then
  InsertBefore(FImageChild,FLabelChild);
```

## Until then

`TRibbonItem` never clears a caption: an icon-only item hides its label through the CSS class `ribbon-icononly`.
