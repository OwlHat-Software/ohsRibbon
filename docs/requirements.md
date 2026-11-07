# ohsRibbon requirements

MoSCoW priority: M must, S should, C could. Scope is set by decision 0001.

| ID | Priority | Requirement |
|---|---|---|
| RB-001 | M | A ribbon on Fresnel with no LCL dependency, usable from code |
| RB-002 | M | Tabs that switch a panel of captioned groups |
| RB-003 | M | Large, medium and small buttons, stacked in columns of three |
| RB-004 | M | Toggle, dropdown and split buttons |
| RB-005 | M | Application menu button |
| RB-006 | M | Quick access toolbar |
| RB-007 | M | Collapse and expand; a collapsed ribbon shows the panel on demand |
| RB-008 | S | Group dialog launcher |
| RB-020 | M | Groups step down in size as the window narrows and collapse into a dropdown, and step back up as it widens |
| RB-030 | M | Galleries with paging and an expanded view |
| RB-031 | M | Contextual tabs shown and hidden by the application |
| RB-040 | M | KeyTips: key badges on two levels, with unique keys |
| RB-050 | M | Neutral light and dark look, restylable through CSS variables |
| RB-NFR-100 | M | Builds and runs on i386-win32 and x86_64-win64 with FPC 3.2.2 and Lazarus 4.8 |
| RB-NFR-101 | M | Sizing and KeyTip logic live in `src\model`, free of Fresnel and LCL, with unit tests |
