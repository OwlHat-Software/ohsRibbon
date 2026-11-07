# FC-06 - Fresnel windows have no title bar on Wayland

Repository: Fresnel. Found while running the demo in WSL. It affects every Fresnel application on Wayland with GTK3.

## Problem

On Wayland, GTK draws the title bar of a window itself, inside the window. `src\gtk3\fresnel.gtk3.pas` draws on the
`GtkWindow` itself and takes all its mouse events, so there is no title bar and the window cannot be moved. The same
program under X11 has one, because the window manager draws it there.

## Change

Give the window one child, a `GtkDrawingArea`:

- The area gets `draw`, `size-allocate` and the mouse events, the pointer grab and the cursor.
- The window keeps the keyboard, focus and the window signals. It ignores mouse events, so they reach its title bar.
- The size of the form is the size of the area, at 0,0, without the title bar.

## Status

Applied in Fresnel as `c8794a66`. Checked under X11 with clicks, hover, keys and resizing, and by hand under Wayland in
WSL. Not checked on a Wayland session of a Linux desktop.
