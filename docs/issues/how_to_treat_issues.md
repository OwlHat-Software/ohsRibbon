# How to treat issues

Apps that use ohsRibbon put the ohsRibbon bugs they find in this folder, one Markdown file per issue.

## Filing an issue

Name the file `issue_NNNNN_short-description.md`, with the next free number and no status at the end.
For example: `issue_00003_short-description.md`.

Describe:

- **Symptom:** what goes wrong, and in which app.
- **Reproducing it:** the exact steps, and how often it happens.
- **Evidence:** what you measured or read in the code.
- **Likely cause:** say clearly if it is not proven.
- **Suggested fix and workaround:** if you have them.

Keep personal details, such as user names in file paths, out of the file.

## Status

The end of the filename shows the status of an issue, just before `.md`:

| Filename ends in | Meaning |
| --- | --- |
| no status | Not checked yet |
| `_valid_unsolved` | A genuine issue, not fixed yet |
| `_invalid` | Not a genuine issue |
| `_solved` | A genuine issue, now fixed |

For example: `issue_00003_short-description_valid_unsolved.md`.

## Checking an issue

1. Check what the issue says against the ohsRibbon code, and reproduce it if you can. Do not rely on the
   likely cause it gives.
2. Add `_valid_unsolved` or `_invalid` to the filename.
3. Add a `## Checked` section to the file with what you found and how. For an invalid issue, say where
   the problem really is.

When a valid issue is fixed, change `_valid_unsolved` to `_solved`, and add the commit to the file.
