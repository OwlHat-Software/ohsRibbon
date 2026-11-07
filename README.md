# ohsRibbon

A ribbon component for [Fresnel](https://gitlab.com/OwlHatSoftware/fresnel), the CSS-based UI library for
Lazarus and Free Pascal.

- Tabs with captioned groups; large, medium and small buttons
- Toggle, dropdown and split buttons; group dialog launcher
- Application menu button and quick access toolbar
- Collapse and expand, with the panel on demand while collapsed
- Adaptive sizing: groups step down and collapse into a dropdown as the window narrows
- Galleries with paging and an expanded view
- Contextual tabs
- KeyTips
- Light and dark look, restylable through `--ribbon-*` CSS variables
- Optional title bar in place of the one of the system, on Windows and on Linux with GTK3

It builds with FPC 3.2.2 and Lazarus 4.8 for i386-win32 and x86_64-win64, and with FPC 3.2.2 and Lazarus 4.4 for x86_64-linux. It needs Fresnel with the fixes in `docs\library-changes`.

## Use

Add the package `src\ohsribbon.lpk` to your project, then build the ribbon from code:

```pascal
uses ohsribbon.model.sizing, ohsribbon.ui.ribbon;

Ribbon:=TRibbon.Create(Self);
Ribbon.Parent:=Body;
Ribbon.ApplicationMenu:=FileMenu;
Ribbon.AddQuickButton('Save',@SaveClick);

Tab:=Ribbon.AddTab('Home');
Group:=Tab.AddGroup('Clipboard');
Group.AddButton('Paste',risLarge,@PasteClick).Image:=PasteIcon;
Group.AddButton('Cut',risMedium,@CutClick);
Group.AddToggle('Bold',risSmall,@BoldClick);
Group.AddDropdown('Size',risMedium,SizeMenu);
Group.AddSplitButton('Find',risLarge,@FindClick,FindMenu);
Group.OnDialogLauncher:=@ClipboardDialogClick;

Gallery:=Tab.AddGroup('Styles').AddGallery(4);
Gallery.AddItem('Normal',NormalIcon);
Gallery.OnSelect:=@StyleSelect;

Format:=Ribbon.AddContextualTab('Picture tools','Format');
Ribbon.SetContextVisible('Picture tools',True);
```

To restyle it, override the variables in your stylesheet, for both the ribbon and its popups:

```css
ribbon, .ribbon-popup { --ribbon-accent: #7a3e9d; }
```

## Title bar

`TRibbonTitleBar` draws an icon, the title and minimize, maximize and close buttons. Windows and GTK keep doing the
shadow, resizing and, where they offer it, snapping. It is separate from the ribbon, so a program without it does not
link any of this.

```pascal
uses ohsribbon.ui.titlebar, ohsribbon.ui.titlebar.native;

Bar:=TRibbonTitleBar.Create(Self);
Bar.Caption:=Caption;
Bar.Parent:=Body; // first, above the ribbon

// Once, before the form is first shown, for example in an override of Show.
InstallTitleBar(Bar);
```

On other platforms the bar hides itself and the title bar of the system stays. To restyle it, override the
`--titlebar-*` variables. Right click opens the window menu of the system; where the system has none, as under Wayland in WSL, the bar opens its own with restore, minimize, maximize and close.

## Keys

Alt or F6 (`TRibbon.KeyTipKey`) starts KeyTips, Escape goes back a level.

## Limits

- The ribbon is built from code. It has no component palette entry or form designer support.
- Full keyboard navigation with the arrow keys is not there; KeyTips are the keyboard route.
- Under Wayland in WSL the right Alt key arrives as AltGr, which does not start KeyTips. The left Alt key and F6 do.
- Texts in the ribbon itself are the captions you pass in, apart from the default application button caption `File`.

## Build

```bash
build.cmd
```

This builds the package, tests and demo for both targets and runs the tests. It must end with
`BUILD OK, TESTS PASSED`. The demo is `out\<target>\ribbondemo.exe`. It uses `TRibbonTitleBar`.

On Linux, run `./build.sh` instead. It needs `lazbuild`, FPC and the GTK3 development files, and looks for Fresnel next
to this repository or in `FRESNEL_DIR`. The demo is `out/x86_64-linux/ribbondemo`, which finds `libsk4d.so` next to itself. How the project is worked on is in
`docs\claude-workflow.md`.
