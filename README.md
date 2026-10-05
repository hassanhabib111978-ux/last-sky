# LAST SKY

**SURVIVE THE SWARM**

LAST SKY is a mobile survival shooter built for Android, designed for a global audience.

## Current direction
- Engine: Godot 4.7.2
- Platform: Android first
- Language: English
- Perspective: First-person — the player is the survivor
- Mode: Single-player first; multiplayer-ready architecture later
- Visual target: stylized realistic / cinematic sci-fi
- First playable environment: abandoned, war-damaged Eastern-European city

## Core loop
DROP → EXPLORE → LOOT → EQUIP → SURVIVE → FIGHT / HIDE / ESCAPE → UPGRADE → EXTRACT → REWARD → NEXT RUN

## Current playable foundation
- First-person mobile control layout with dual-touch movement/aim and FIRE control.
- Real 3D raycast weapon hit detection.
- Ammo, reload, health and loot HUD.
- Scout drone combat enemies.
- Wave-based combat pacing.
- Ammo, battery and weapon-parts loot.
- Abandoned city block with buildings, cover, ruined structures, civilian vehicles, utility poles and barriers.
- Drone tactical roles: HUNTER, FLANKER and OVERWATCH.

## Android test build
The repository includes an Android Debug export preset and a GitHub Actions workflow that validates the Godot project and exports a test APK.

## Engineering rule
LAST SKY is built as one connected game system, not as a collection of unrelated demos. Changes follow:

**Inspect → Understand → Plan → Change → Test → Log**

See AI_ENGINEER/ for the project constitution, memory, and change log.

## Build note
Android export is automated from the repository so the project can be tested on a real Android device without requiring a desktop editor.
