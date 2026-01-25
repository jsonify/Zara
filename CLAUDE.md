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

- **Game** (`global/game.gd`): Player stats (HP, gold, fuel_level, jetpack, dash, slide abilities), inventory system, and purchased upgrades
- **SignalBus** (`global/signal_bus.gd`): Central health change signals for UI
- **Events** (`global/events.gd`): Game event signals (thrust, jetpack, etc.)
- **Utils** (`global/utils.gd`): Save/load game data + UI utilities

### Unified State Machine Pattern

Both player and enemy use a unified state machine pattern (`entities/base/`):

- **UnifiedState** (`entities/base/UnifiedState.gd`): Base state class with `state_process()`, `on_enter()`, `on_exit()`. Supports both return-value and `next_state` property transitions.
- **UnifiedStateMachine** (`entities/base/UnifiedStateMachine.gd`): Manages state transitions, handles both transition patterns.
- **State** (`entities/State.gd`): Backward-compatible alias extending UnifiedState for enemies.

**Player states** (`entities/player/`): Flow: `IDLE` ↔ `MOVE` ↔ `FALL` ↔ `JUMP`, with `DASH`/`SLIDE`/`THRUST`/`ATTACK`/`RANGED`/`HIT`/`DEATH` as special states.

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
- `collectibles/` - Fuel pickups, gold coins, destructible boxes, powerup stations, shop stations
- `resources/` - Enemy stat resources (enemy_resource_base.gd), shop item resources (shop_item_resource.gd)

## Input Actions

- `left`/`right`: Movement
- `jump`: Space/W
- `dash`: Z
- `climb`/`slide`: X/B
- `thrust`: Right Mouse Button
- `attack`: J/Left Mouse Button (melee)
- `ranged`: K (projectile)
- `pause`: Escape (pause menu)
- `save`: Cmd+J
- `use_item`: Q (use health potion or fuel canister)
- `take`: E (interact with shop stations)

## Save System

Binary file at `user://savegame.bin` containing JSON (HP, gold, fuel, abilities, inventory, purchased upgrades). See `Utils.saveGame()` and `Utils.loadGame()`.

## Currency/Shop System

Players earn gold from killing enemies and collecting gold coins. Gold can be spent at shop stations.

### Shop Items
- **Consumables**: Health Potion (10 HP, 15g), Fuel Canister (10 fuel, 10g)
- **Upgrades**: Fuel Tank Upgrade (+10 max fuel, 50g) - permanent, one-time purchase

### Key Files
- `collectibles/gold/gold_coin.gd` - Gold pickup collectible
- `collectibles/shop/shop_station.gd` - Interactive shop station
- `ui/shop_menu.gd` - Shop UI with item purchasing
- `resources/shop_item_resource.gd` - Shop item resource class
- `resources/shop_items/` - Item definitions (.tres files)

### Inventory Functions (Game autoload)
- `Game.add_item(item_id, count)` - Add items to inventory
- `Game.remove_item(item_id, count)` - Remove items from inventory
- `Game.has_item(item_id, count)` - Check if player has items
- `Game.use_item(item_id)` - Use a consumable item
- `Game.has_upgrade(upgrade_key)` - Check if upgrade purchased
- `Game.add_upgrade(upgrade_key)` - Add and apply upgrade

## Testing

Unit tests use the [GUT](https://gut.readthedocs.io/) (Godot Unit Testing) framework.

### Running Tests

**Command line:**
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd
```

**In Godot Editor:** Use the GUT panel at the bottom of the editor and click "Run All".

### Test Conventions

- Test files go in `test/unit/` with prefix `test_` (e.g., `test_inventory.gd`)
- Test functions must start with `test_`
- Extend `GutTest` for all test classes
- Use `before_each()`/`after_each()` to save and restore global state (Game, Events, etc.)
- Use `watch_signals()` and `assert_signal_emitted_with_parameters()` to verify signal emissions

### When to Write Tests

- When modifying core systems (inventory, damage, state machines)
- When adding new functionality to global autoloads (Game, Events, Utils)
- When fixing bugs (write a failing test first, then fix)

### Existing Test Coverage

- `test/unit/test_inventory.gd` - Inventory system (add/remove/use items, upgrades)
- `test/unit/test_damage_system.gd` - Damage system (Damageable, HitBox, HurtBox components)

## Conventions

- Heavy signal usage for decoupled communication
- `@onready` for node reference caching
- `@export` variables for inspector-tunable parameters
- State classes inherit from `UnifiedState` base (or `State` for backward compatibility)
- Enemy stats defined as resources (`.tres` files in `resources/`)
- World scene uses instanced sub-scenes for organization (`environment/world_*.tscn`, `collectibles/world_*.tscn`, etc.)

## TODO

### Code Cleanup
- [x] Consolidate player implementations - removed unused `hero.gd` and `hero.tscn`; `player.gd` is the active implementation
- [x] Remove deprecated code in `environment/scratch/` - deleted scratch directory and test scenes
- [x] Standardize naming conventions - renamed `playerHP` to `player_hp`, `Raycasts` to `raycasts`

### Architecture Improvements
- [x] Break up `world.tscn` into smaller instanced scenes - migrated to use `world_background.tscn`, `world_environment.tscn`, `world_collectibles.tscn`, `world_powerups.tscn`, `world_enemies.tscn`; fixed signal connections in base scenes
- [x] Unify player and enemy state machines - created `UnifiedState` and `UnifiedStateMachine` base classes in `entities/base/`
- [x] Add player attack/combat states - added `ATTACK` (melee), `RANGED` (projectile), and `HIT` (damage reaction) states with projectile system

### Features to Expand
- [ ] Expand dialogue system - currently only `powerup_stations.json` exists
- [x] Implement gold currency usage - shop system with consumables and upgrades
- [ ] Add more enemy types using the `CharacterStateMachine` pattern

### Testing
- [ ] Add physics-based integration tests for damage system (HitBox/HurtBox collision detection with scene instantiation)

### Polish
- [x] Add death/respawn system - DEATH state with fade animation, respawn at spawn point with HP reset
- [x] Add pause menu - Escape key toggles pause with Resume/Main Menu/Quit options
- [x] Move save file to user:// instead of res:// for exported builds
