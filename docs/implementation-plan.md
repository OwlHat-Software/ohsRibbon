# ohsRibbon implementation plan

| Work package | Content | Exit check | State |
|---|---|---|---|
| WP-0.1 | Package, `build.cmd`, test project | `build.cmd` ends with `BUILD OK, TESTS PASSED` | Done |
| WP-1.1 | Tabs, groups, buttons, application menu, quick access, collapse (RB-001 to RB-008) | Tests pass; visible in the demo | Done |
| WP-2.1 | Adaptive sizing (RB-020) | Tests pass; demo checked at several widths | Done |
| WP-3.1 | Galleries, contextual tabs (RB-030, RB-031) | Tests pass; visible in the demo | Done |
| WP-3.2 | KeyTips (RB-040) | Tests pass; visible in the demo | Done |
| WP-4.1 | Light and dark look on both targets (RB-050, RB-NFR-100) | Demo checked in both looks, both targets | Done |

## Changes needed in Fresnel

All six are applied on the Fresnel `main` branch, which is pushed to the fork on GitLab. The ribbon relies on FC-01 to FC-03 and FC-05, and the demo on FC-04 and FC-06.

| Spec | Problem | Fresnel commit |
|---|---|---|
| [FC-01](library-changes/FC-01-win32-alt-key.md) | The Win32 backend does not deliver Alt | `8370b3d5` |
| [FC-02](library-changes/FC-02-textbutton-clear-caption.md) | Clearing the caption of a button with an image raises | `02e3ef37` |
| [FC-03](library-changes/FC-03-win32-function-keys.md) | The Win32 backend reports F2 to F24 with the wrong key | `8370b3d5` |
| [FC-04](library-changes/FC-04-win32-form-caption.md) | The Win32 backend does not set the window title | `f8412351` |
| [FC-05](library-changes/FC-05-gtk3-alt-key.md) | The GTK3 backend does not deliver Alt | `8f655c74` |
| [FC-06](library-changes/FC-06-gtk3-wayland-title-bar.md) | Fresnel windows have no title bar on Wayland | `c8794a66` |

## Answered questions

| ID | Answer |
|---|---|
| Q-P01 | The ohsRibbon remote is on GitHub (`OwlHat-Software/ohsRibbon`), so the CI is GitHub Actions. The workflow is not there yet. |
| Q-P02 | The architecture rule in `build.cmd` stands as built: no Fresnel or LCL in `src\model`, no LCL in `src\`. |
| Q-P03 | Translations are in scope, but not for now. English stays the main language. The format is chosen when the work is taken up. |
