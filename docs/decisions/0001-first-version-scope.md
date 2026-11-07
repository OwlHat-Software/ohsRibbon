# 0001 - Scope, look and targets of the first version

Status: Accepted

## Question

What does the first version of ohsRibbon include, what does it look like, and which targets does it build for?

## Options

| Option | For | Against |
|---|---|---|
| Core ribbon | Smallest; complete sooner | No adaptive resizing, galleries, contextual tabs or KeyTips |
| Core plus adaptive | Closer to real ribbon behaviour | Still no galleries, contextual tabs or KeyTips |
| Full ribbon | The complete feature set | Largest scope; split over milestones |

Look: neutral light and dark, Fresnel theme only, or Office-like colours.
Targets: i386-win32 only, or i386-win32 and x86_64-win64.

## Recommendation

Core ribbon; neutral light and dark; i386-win32 first.

## Decision

The developer chose on 2026-11-07: **full ribbon**, **neutral light and dark**, **i386-win32 and x86_64-win64**.

## Consequences

- Answers Q-P04. Both targets are built by `build.cmd`.
- No Microsoft icons, assets or colour palette are used.
- The Alt key does not reach Fresnel on Win32, so KeyTips need FC-01 (see `docs\library-changes`).
