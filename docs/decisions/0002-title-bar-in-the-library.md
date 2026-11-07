# 0002 - A title bar component with platform code in the library

Status: Accepted

## Question

The demo drew its own title bar on Windows and used the one of GTK on Linux. Where does a title bar belong?

## Options

| Option | For | Against |
|---|---|---|
| The same title bar in the demo, on both platforms | No platform code in the library | Every program has to write it again |
| A component in the library | Any program using the ribbon can have it | Platform code in the library |
| Title and quick access buttons in one header row | Compact | A different and larger change |

## Recommendation

The first option, as the smaller step.

## Decision

The developer chose the component in the library, 2026-11-07.

## Consequences

- `ohsribbon.ui.titlebar` is the element and knows no platform. It has unit tests.
- `ohsribbon.ui.titlebar.native` has the Windows and GTK3 code. The ribbon uses neither, so a program links this only
  when it asks for the title bar.
- The architecture rule stays as it is: the rule is about LCL and about `src\model`, and platform units are allowed.
