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

- 2026-10-05: Expanded first Loot loop to three resource types (AMMO, BATTERY, PARTS), added resource HUD counters, randomized drone drops, and animated pickups.

- 2026-10-05: Created the first procedural Abandoned City combat block with buildings, cover walls, alley-like lanes, collision, and simple emissive window storytelling.

- 2026-10-05: Reworked city buildings into partially ruined structures with broken upper sections, missing windows, facade debris, and rubble while preserving collision.

- 2026-10-05: Pushed the abandoned city visual language toward contemporary Eastern-European war-torn urban damage: fractured facade slabs, heavier rubble, irregular damage, and dense improvised cover while keeping the setting fictional and non-factional.


## 2026-10-05 — City environment expansion + core movement loop
- Added low-cost abandoned civilian vehicles, including damaged/scorched variants.
- Added utility poles and simple street infrastructure for stronger Eastern-European war-torn urban atmosphere.
- Added concrete barriers/checkpoint-style cover as static gameplay geometry.
- Restored the player physics/update loop for keyboard and mobile joystick movement, weapon cooldown/reload timing, and HUD refresh helpers.
- Kept the environment primitive and mobile-conscious for now; final art assets and runtime profiling remain pending.
- Runtime testing in Godot has not yet been performed in this session.
