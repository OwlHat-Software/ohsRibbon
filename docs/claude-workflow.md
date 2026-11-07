# Working with Claude Code - the workflow

This is how ohsRibbon, a ribbon component for Fresnel, is built with Claude Code. It is adapted from the
Masterplanner workflow, a Delphi/FMX application, to a Lazarus/Free Pascal library.

## 0. Where the project stands (2026-11-07)

Sections 2 and 4 to 6 are in place; section 7 waits for a remote. Section 10 is the checklist. Do not assume
something exists until it is ticked off there.

| Item | State |
|---|---|
| Component | First version in `src\`, see `README.md` and `docs\implementation-plan.md` |
| Requirements, plan, decision records | `docs\requirements.md`, `docs\implementation-plan.md`, `docs\decisions\` |
| `build.cmd`, tests, demo | In place, for both targets |
| `CLAUDE.md` | Not created yet: section 9 has the text |
| Git remote, CI | None. `git push` and CI are not available yet (Q-P01) |

Toolchain on this machine (fpcupdeluxe install in `C:\lazarus`; neither tool is on `PATH`):

| Tool | Path | Version |
|---|---|---|
| lazbuild | `C:\lazarus\lazarus\lazbuild.exe` | Lazarus 4.8 |
| fpc | `C:\lazarus\fpc\bin\i386-win32\fpc.exe` | FPC 3.2.2, default target i386-win32; `ppcrossx64` for x86_64-win64 |
| Lazarus config | `C:\lazarus\config_lazarus` | Pass with `--pcp=` so lazbuild finds the installed packages |
| Fresnel | `C:\Users\JaccoUijlenhoet\Documents\development\lazarus_libraries\fresnel` (`src\fresnel.lpk`, `design\fresneldsgn.lpk`) | Separate repository |

The open questions are in `docs\implementation-plan.md`. Q-P04 is answered by decision 0001.

## 1. Roles

- **The developer decides.** Scope, choices between options, priorities and releases are theirs.
- **Claude implements.** It writes the code, tests and docs, builds, commits and, once there is a remote, pushes
  and watches CI.
- When a choice comes up that the developer should make, Claude stops, writes it down with a recommendation, and
  asks (section 4). It does not build on a choice that has not been made.
- Anything Claude cannot do itself (checks by hand, installing the package in the IDE, other hardware, work in
  other repositories) goes on a clear list for the developer at the end of each piece of work.

## 2. The documents in `docs\` lead

| Document | What it holds | IDs |
|---|---|---|
| Requirements | What the component must do, with MoSCoW priority | `RB-xxx`, `RB-NFR-xxx` |
| Implementation plan | Milestones (M1, M2, ...) split into work packages, each with an exit check | WP-x.y |
| Open questions in the plan | Questions for the developer | Q-Pxx |
| `docs\decisions\` | One decision record per choice (section 4) | 0001, 0002, ... |
| `docs\library-changes\` | Specs for changes needed in separate library repositories, such as Fresnel | FC-xx |
| Component guide, release notes | Kept up to date with the work | - |

- Work goes one work package at a time, in plan order. "Continue with WP-1.2" is a complete instruction.
- Every commit message and pull request names the IDs it serves (`WP-1.3: tab groups ... (RB-012)`).
- When a work package is done, its exit check is met, and the plan is updated to say so.

## 3. Where Claude works

- By default in the project folder itself, on `main`, with no worktrees and no `claude/<topic>` branches unless
  the developer asks for them. The point: the demo the developer starts from `out\` is always the latest one.
- Larger or risky work can still go on a branch with a pull request when the developer asks.
- If a session is started in a worktree anyway, edit there, then move `main` to the result and build in the
  main folder, so `out\` is still current.
- **This session is such a case.** It runs in the worktree `.claude\worktrees\adapt-claude-workflow-docs-595135`
  on the branch `claude/adapt-claude-workflow-docs-595135`, so `out\` in the main folder is not current until the
  branch is on `main`.

## 4. Decision records

- Template: `docs\decisions\0000-template.md`, with the sections Question / Options (a table with For and
  Against) / Recommendation / Decision / Consequences.
- Claude writes a new record with status **Proposed**, gives its recommendation, and asks the developer, offering
  the options with the recommended one first.
- After the answer it sets **Accepted**, writes who chose what and when, and only then builds on it.
- A later change to a decision is a new record (or a dated note in the old one) that says what it amends.
- `docs\decisions\README.md` keeps an index.

## 5. One build script as the gate

`build.cmd` is the only way to build, locally and in CI. It calls lazbuild with
`--pcp=C:\lazarus\config_lazarus`. The paths can be set through `RIBBON_LAZARUS_DIR` and `FRESNEL_DIR`. In one run,
for i386-win32 and x86_64-win64, it:

1. Checks the architecture rule. Proposed until Q-P02 is decided: the non-visual units in `src\model` may not use
   Fresnel or LCL units, and nothing in `src\` may use LCL units directly. A broken rule stops the build.
2. Builds the package (`src\ohsribbon.lpk`), the test project and the demo.
3. Runs all unit tests. These use stand-in windows and fonts, so a change in input or look also needs a check with
   the real demo (`out\<target>\ribbondemo.exe`, see the switches in `demo\ribbonform.pas`).

It ends with one fixed line - `BUILD OK, TESTS PASSED` - and distinct exit codes (1 tests failed, 2 tools
missing, 3 architecture rule broken, 4 package or demo build failed). Claude runs it after every change; a change
is not done until that line appears. Logs go to `out\build.log` and `out\tests.log`.

## 6. Tests and code rules

- Core logic lives in units without UI dependencies, and every such unit gets unit tests (FPCUnit, with its
  console runner, so they run without the IDE).
- New units are registered everywhere they must be: the package file `ohsribbon.lpk` **and** the test project.
- Naming: `ohsribbon.<area>.<name>.pas` (dotted, like Fresnel's own units), tests `test\utest.<area>.<name>.pas`.
- Visual behaviour that cannot be unit tested gets a command-line switch on the demo for a scripted check
  (for example `-theme` or `-page` for screenshots), which CI runs.
- UI texts are `resourcestring`s in English. Whether they are translated, and how, is open (Q-P03).
- Text files use CRLF in the working folder (`.gitattributes` has `* text=auto`); source files are ASCII without
  BOM unless a file needs otherwise.

## 7. Commit, push, CI

- After a green build: commit (one coherent change per commit, IDs in the message), push to `main`.
- Until there is a remote (Q-P01) the work stops at the local commit; say so in the report.
- CI, once set up, runs on a self-hosted Windows runner with the same Lazarus install and builds every push from
  a clean checkout. It calls `build.cmd`, runs the scripted checks and takes screenshots of the demo. The
  screenshots go into the run artifact and onto the `ci-output/main` branch, so the developer can look at the
  result from a phone.
- Claude watches the CI run in the background and reports the result.
- **A red CI run on `main` is fixed first**, before anything else.

## 8. Rules that saved time

- Library repositories are never changed from this repository: Claude writes a spec in `docs\library-changes`,
  and the developer (or a session in that repository) carries it out. This includes Fresnel.
- Never a bare `git stash` (the stash is shared between sessions); use a temporary commit.
- Paths with backslashes and Pascal braces: edit with the Edit tool or a literal string replace, not `sed`/`perl`.
- Report faithfully: if a test fails or a step was skipped, say so with the output.
- End each piece of work with: what changed, the commit and CI result, and what is left for the developer.

## 9. CLAUDE.md to copy

```markdown
# Notes for Claude (and anyone new to the code)

- Free Pascal 3.2.2 and Lazarus 4.8 on Windows, in `C:\lazarus`; neither is on `PATH`. lazbuild needs
  `--pcp=C:\lazarus\config_lazarus`. Fresnel is in
  `C:\Users\JaccoUijlenhoet\Documents\development\lazarus_libraries\fresnel`.
- Requirement IDs (RB-xxx), work packages (WP-x.y) and questions (Q-Pxx) come from the docs in `docs\`.
  Mention them in commits and pull requests.
- `src\model`: no Fresnel or LCL units, and `src\` uses no LCL units directly (build.cmd enforces it; proposed
  until Q-P02 is decided). Everything in `src\model` gets unit tests (FPCUnit).
- New units: add them to `ohsribbon.lpk` and to the test project when testable.
- Unit names: `ohsribbon.<area>.<name>`; tests `test\utest.<area>.<name>`.
- UI texts are resource strings in English. Translation is open (Q-P03).
- Text files use CRLF. Source files stay ASCII (no BOM) unless a file needs otherwise.
- Work in this folder on `main`: no worktrees, no `claude/<topic>` branches unless the developer asks. After a
  change run `build.cmd`; it must end with `BUILD OK, TESTS PASSED` (the demo in `out\` is what the developer
  runs). Then commit, and push to `main` once there is a remote; CI builds every push. A red CI run on `main` is
  fixed first.
- Choices the developer should make: write a decision record in `docs\decisions` (status *Proposed*),
  give a recommendation, and ask. Do not build on a proposal before it is accepted.
- Library changes are specified in `docs\library-changes`; the libraries, Fresnel included, are separate
  repositories - do not change them from this repository.
```

## 10. Setting it up

- [x] Answer Q-P04 (decision 0001).
- [ ] Answer Q-P01, Q-P02 and Q-P03, each as a decision record where it is a real choice.
- [x] Put the requirements and an implementation plan (milestones, work packages with exit checks) in `docs\`,
      and move the open questions from section 0 into the plan.
- [x] Add `docs\decisions\0000-template.md` and a README index.
- [ ] Record the workflow itself as decision records.
- [x] Add `out/` and `lib/` to `.gitignore`.
- [x] Create `src\ohsribbon.lpk`, the test project and the demo.
- [x] Write `build.cmd` with the checks from section 5 and the fixed last line.
- [ ] Create the remote, and add the CI workflow that calls the same `build.cmd`, plus screenshots and an output
      branch.
- [ ] Paste section 9 into `CLAUDE.md`.
