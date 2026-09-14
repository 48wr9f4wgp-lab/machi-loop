# MACHI LOOP icon pipeline

The canonical icon master is `assets/app/machi-loop-icon.svg`.
Godot uses the SVG directly via `application/config/icon`.
CI rasterizes the same master into cache-busted 192px and 512px PNGs for the iPhone/PWA shell, preventing drift between Godot and Home Screen branding.
