# LAST SKY AI ENGINEER — Change Log

## 2026-10-05 — Foundation initialized
- Created the LAST SKY repository foundation.
- Added the AI Engineer constitution.
- Added project memory.
- Added this change log.
- No engine-specific gameplay code has been introduced yet.
- Next gate: verify the current Godot 4.x version and the safest phone-first editor/MCP workflow before generating the actual game project.

### Test status
Repository structure: PASS
Gameplay build: NOT STARTED
Android export: NOT STARTED
Live Godot MCP connection: NOT STARTED

- 2026-10-05: Added reusable drone controller and connected touch movement plus the first fire loop. Runtime validation in Godot is still pending.

- 2026-10-05: Upgraded mobile input to dual-touch controls: virtual movement joystick, independent right-side aim drag, touch IDs for simultaneous fingers, and larger fire control.

- 2026-10-05: Polished mobile combat feel with dual-touch aiming feedback, centered crosshair, fire cooldown, movement acceleration, and improved Scout Drone combat spacing.

- 2026-10-05: Replaced proximity-based weapon hits with real 3D physics raycast collision and drone collision metadata; added rifle magazine/reserve ammo and reload cycle.

- 2026-10-05: Rebuilt the Scout Drone as a CharacterBody3D enemy with pursuit, hover behavior, attack range/cooldown, player damage, health, hit flash, and destruction sequence.

- 2026-10-05: Added first Loot system: destroyed Scout Drones emit loot drops, collectible pickups add ammo/resources, and pickups expire automatically.
