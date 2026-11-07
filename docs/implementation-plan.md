# ohsRibbon implementation plan

| Work package | Content | Exit check | State |
|---|---|---|---|
| WP-0.1 | Package, `build.cmd`, test project | `build.cmd` ends with `BUILD OK, TESTS PASSED` | Done |
| WP-1.1 | Tabs, groups, buttons, application menu, quick access, collapse (RB-001 to RB-008) | Tests pass; visible in the demo | Done |
| WP-2.1 | Adaptive sizing (RB-020) | Tests pass; demo checked at several widths | Done |
| WP-3.1 | Galleries, contextual tabs (RB-030, RB-031) | Tests pass; visible in the demo | Done |
| WP-3.2 | KeyTips (RB-040) | Tests pass; visible in the demo | Done with F6; Alt waits for FC-01 |
| WP-4.1 | Light and dark look on both targets (RB-050, RB-NFR-100) | Demo checked in both looks, both targets | Done |

## Changes needed in Fresnel

The ribbon works around FC-02 and FC-03. Only FC-01 limits it.

| Spec | Problem |
|---|---|
| [FC-01](library-changes/FC-01-win32-alt-key.md) | The Win32 backend does not deliver Alt |
| [FC-02](library-changes/FC-02-textbutton-clear-caption.md) | Clearing the caption of a button with an image raises |
| [FC-03](library-changes/FC-03-win32-function-keys.md) | The Win32 backend reports F2 to F24 with the wrong key |

## Open questions

| ID | Question |
|---|---|
| Q-P01 | Where is the remote hosted, GitHub or GitLab (the Fresnel fork is on GitLab)? This decides the CI. |
| Q-P02 | Is the architecture rule in `build.cmd` right: no Fresnel or LCL in `src\model`, no LCL in `src\`? It is built as proposed. |
| Q-P03 | Are translations in scope for a library, and in which format? |
