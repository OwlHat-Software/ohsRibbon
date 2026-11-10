# issue_00001: no way to remove an item, a group or a tab

## Symptom

A ribbon can only grow: `TRibbonGroup`, `TRibbonTab` and `TRibbon` have `Add...` methods but nothing that
takes an item, a group, a tab or a quick access button away again.

This matters to apps that add to the ribbon at run time and later want it gone. The XERTools Planner loads
plugins (ohsPluginFramework, `TOhsRibbonAdapter`): a plugin adds buttons, and often a group or a tab of its
own, and when it is unloaded or switched off in the planner's Plugins window those should go. Today they
cannot, so the adapter hides them:

- the button gets `cRibbonHiddenClass` and its `OnClick` is set to nil
  (`ohs.plugin.fresnel.ribbon.pas`, `TOhsRibbonAdapter.Remove`);
- a group, or a tab header, with nothing visible left is hidden too (`TOhsRibbonAdapter.TidyUp`);
- a plugin loaded again reuses the hidden group and tab.

So every load and unload of a plugin leaves a hidden `TRibbonItem` behind, which lives until the form goes.
Loading and unloading many times grows the ribbon without end, and the group's layout still counts the
hidden items.

## Reproducing it

1. In an app, `lItem:=Ribbon.AddTab('Plugins').AddGroup('Sample').AddButton('Check',risLarge,@Handler)`.
2. Try to take `lItem`, its group or its tab away again: there is no method for it.
3. Freeing `lItem` (or setting its `Parent` to nil) leaves a dangling pointer in `TRibbonGroup.FItems`,
   and the next layout pass (`TRibbonGroup` building its columns, around line 1038) uses it.

Always: it is a missing feature, not a race.

In the XERTools Planner: File > Plugins, switch the sample plugin off and on a few times. Its Activity
check button and Sample group disappear each time, but a new hidden button is made each time it comes back.

## Evidence

In `src/ohsribbon.ui.ribbon.pas` (main):

- `TRibbonGroup` keeps its items in `FItems: TFPList`, with `FPreferred` and `FMinimum` arrays in the same
  order (`AddElement`, around line 952). Nothing removes from them.
- `TRibbonTab` keeps its groups in `FGroups: TFPList` (`AddGroup`, around line 1228); nothing removes.
- `TRibbon` keeps its tabs in `FTabs` and the quick access buttons in `FQuickItems` (`AddTab`,
  `AddContextualTab`, `AddQuickButton`); nothing removes. `UpdateTitleRow` hides the title row only when
  `FQuickItems.Count=0`, so a hidden quick button still keeps the row.
- The ohsPluginFramework README lists this under its limits and asks for a `RemoveItem`/`RemoveGroup`.

Not checked: whether a hidden item still gets a key tip badge, or still counts when the group decides how
far to shrink its items (`ReducedSizes` over `FPreferred`/`FMinimum`).

## Likely cause

Not proven: the apps so far build their ribbon once at start, so removing was never needed. It is a
missing feature rather than a bug in what is there.

## Suggested fix

Add, each keeping the lists, the size arrays and the layout in step:

```pascal
// TRibbonGroup: takes the item out of the group and frees it.
procedure RemoveItem(aItem: TFresnelElement);
procedure RemoveItemAt(aIndex: Integer);
// TRibbonTab: frees the group and everything in it.
procedure RemoveGroup(aGroup: TRibbonGroup);
// TRibbon: frees the tab (with its header) and everything in it; a contextual tab leaves its context
// when it was the last one; the active tab moves to a neighbour.
procedure RemoveTab(aTab: TRibbonTab);
procedure RemoveQuickItem(aItem: TRibbonItem);
```

Things to take care of:

- Delete the entries of `FPreferred` and `FMinimum` with the item, set `FBuiltLevel:=-1` and
  `FTab.InvalidateLayout`, as `AddElement` does.
- An item can be in a column `TDiv` of the group's body, not directly in the group: free it from there and
  drop columns left empty.
- Items with drop-down menus, galleries and split buttons own popups: free those as well.
- Key tips: remove the item's badge and its key tip, and let `RemoveBadges` not touch a freed item.
- Removing the active tab activates another; removing the last tab of a context removes the context from
  `FVisibleContexts`.
- `UpdateTitleRow` after removing a quick button.
- An item removed while its own click is running (a plugin unloading itself from its button): free it
  through `Application.QueueAsyncCall`, or document that the caller must.

Tests: add and remove items, groups and tabs in each order, check the counts and that a layout pass after
removal runs without the removed elements; remove the active tab; remove a quick button and see the title
row hide.

## Workaround

As `TOhsRibbonAdapter` does today: hide the element with `cRibbonHiddenClass`, cut its `OnClick`, hide the
group or tab header when nothing visible is left, and reuse them when the same item comes back. Once the
fix is in, the adapter's `Remove` and `TidyUp` can call the new methods instead.

## Checked

Valid, not fixed. Checked on 2026-11-10 against `src/ohsribbon.ui.ribbon.pas` at `2c48866`, by reading the
code; no run-time reproduction was needed for a missing method.

- Confirmed: no public method removes anything. `TRibbonGroup` only adds to `FItems`, `FPreferred` and
  `FMinimum` (`AddElement`, line 952); `TRibbonTab` only adds to `FGroups` (`AddGroup`, line 1224);
  `TRibbon` only adds to `FTabs` and `FQuickItems` (lines 1436, 1445, 1531). The only `Remove...`
  methods are the internal `RemoveKeyListeners` and `RemoveBadges`.
- Confirmed: freeing an item leaves it in `FItems`. Nothing registers a free notification for items, and
  `ArrangeBody` (line 1038) and `CollectKeyLevel` (line 1789) read `FItems` directly.
- Confirmed: a hidden item still counts in the layout. `ArrangeBody` passes every entry of `FPreferred`
  and `FMinimum` to `ReducedSizes` and `PackColumns`, so a hidden large button still takes a column slot
  and still decides how far the group shrinks.
- Found as well, and it affects the workaround: key tips ignore `cRibbonHiddenClass`.
  `CollectKeyLevel` (line 1764) adds every quick item, every group item and every tab header whose context
  is visible; `AddKeyElement` skips only disabled buttons. So a hidden plugin button or hidden tab header
  still gets a key tip letter and a badge. Until the fix is in, the adapter can also set `Enabled:=False`
  on what it hides, which keeps it out of the key tips.
- `UpdateTitleRow` (line 1537) tests only `FQuickItems.Count`, as the issue says.

The suggested fix is a sound starting point. The fix should also make `CollectKeyLevel` skip hidden
elements.

## Solved

Fixed in `d1732a0` (RB-010), as suggested, with these choices:

- `TRibbonGroup.RemoveItem`, `RemoveItemAt` and `IndexOfItem`; `TRibbonTab.RemoveGroup` and `IndexOfGroup`;
  `TRibbon.RemoveTab`, `IndexOfTab`, `RemoveQuickItem` and `IndexOfQuickItem`. A remove call with something
  that is not in the list does nothing.
- What is removed is freed with everything in it. Unused layout columns of a removed group and the expanded
  view of a removed gallery are freed too. A group keeps unused columns while it stays, for reuse; they
  do not grow with each load and unload.
- An open popup of what goes (a collapsed group, a gallery's expanded view) is closed first, and KeyTips
  are hidden.
- Removing from the element's own click is safe: the ribbon frees it after the click, through the
  application's async queue when there is one. The adapter does not need to queue anything.
- KeyTips skip elements with `cRibbonHiddenClass`, so the workaround no longer leaves key tips on hidden
  buttons.

Tests: 11 new tests in `test/utest.ui.ribbon.pas`, passing on i386-win32, x86_64-win64 and x86_64-linux.
The async path runs only inside a Fresnel application, so the tests cover the direct path.

For the planner: `TOhsRibbonAdapter.Remove` and `TidyUp` can call `RemoveItem`, `RemoveGroup` and
`RemoveTab` now, instead of hiding.
