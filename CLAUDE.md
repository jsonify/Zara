# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Zara** is a 2D platformer game built with Godot 4.5. The game features state machine-driven player and enemy controllers, a component-based damage system, and progression mechanics including abilities like dash, slide, and jetpack.

## Running the Project

Open in Godot 4.5 and run the main scene:
- **Main scene**: `res://levels/world.tscn`
- **Main menu**: `res://ui/main.tscn`

## Architecture

### Global Autoloads

Four singletons manage game-wide state (defined in project.godot):

- **Game** (`global/game.gd`): Player stats (HP, gold, fuel_level, jetpack, dash, slide abilities)
- **SignalBus** (`global/signal_bus.gd`): Central health change signals for UI
- **Events** (`global/events.gd`): Game event signals (thrust, jetpack, etc.)
- **Utils** (`global/utils.gd`): Save/load game data + UI utilities

### State Machine Pattern

**Player states** (`entities/player/`): States return next state from `update(delta)`. Flow: `IDLE` ↔ `MOVE` ↔ `FALL` ↔ `JUMP`, with `DASH`/`SLIDE`/`THRUST` as special states.

**Enemy states** (`entities/CharacterStateMachine.gd`): AnimationTree-based transitions with `on_enter()`/`on_exit()` callbacks. Used by flower enemy and extensible for new enemies.

### Damage System

- **HitBox** (`overlaps/HitBox.gd`): Attached to attackers, delivers damage
- **Damageable** (`entities/enemies/damageable.gd`): Component receiving damage, emits `on_hit()` signal
- **HurtBox** (`overlaps/hurt_box.gd`): Triggers damage reception

### Collision Layers

1. Environment (platforms, walls)
2. Player
3. Enemy
4. Projectile
5. Power Up
6. Raycasts (player wall detection)
7. Player Detection (enemy awareness)
8. HitBox (attack areas)
9. EnemyHurtBox
10. PlayerHurtBox

## Key Directories

- `entities/player/` - Player controller and state scripts
- `entities/enemies/` - Enemy implementations (base_enemy.gd for patrol, enemyx.gd for chasing, flower/ for state-machine enemy)
- `overlaps/` - HitBox/HurtBox damage components
- `collectibles/` - Fuel pickups, destructible boxes, powerup stations
- `resources/` - Enemy stat resources (enemy_resource_base.gd)

## Input Actions

- `left`/`right`: Movement
- `jump`: Space/W
- `dash`: Z
- `climb`/`slide`: X/B
- `thrust`: Right Mouse Button
- `save`: Cmd+J

## Save System

Binary file at `res://savegame.bin` containing JSON (HP, gold, fuel, abilities). See `Utils.save_game()` and `Utils.load_game()`.

## Conventions

- Heavy signal usage for decoupled communication
- `@onready` for node reference caching
- `@export` variables for inspector-tunable parameters
- State classes inherit from `state.gd` base
- Enemy stats defined as resources (`.tres` files in `resources/`)

## TODO

### Code Cleanup
- [ ] Consolidate player implementations - both `player.gd` and `hero.gd` exist, clarify which is active
- [ ] Remove deprecated code in `environment/scratch/`
- [ ] Standardize naming conventions (mix of camelCase and snake_case in some files)

### Architecture Improvements
- [ ] Break up `world.tscn` (77KB) into smaller instanced scenes for better maintainability
- [ ] Unify player and enemy state machines to use same base pattern
- [ ] Add player attack/combat states

### Features to Expand
- [ ] Expand dialogue system - currently only `powerup_stations.json` exists
- [ ] Implement gold currency usage (tracked but not spent)
- [ ] Add more enemy types using the `CharacterStateMachine` pattern

### Polish
- [ ] Add death/respawn system
- [ ] Add pause menu
- [ ] Move save file to user:// instead of res:// for exported builds
