# World Scene Organization Roadmap

This document tracks improvements to keep `levels/world.tscn` maintainable as the game grows.

## Current State Analysis

**File:** `levels/world.tscn`
- **Lines:** ~56 (scene structure)
- **Size:** ~3KB (lightweight orchestration file after Phase 2 extraction)

**TileMap Data:** Extracted to `levels/world_tilemap.tscn` (~71KB)

### Current Node Structure

```
World (Node2D)
├── TileMap (instance) ✓ [Extracted to world_tilemap.tscn]
├── UI (instance) ✓
├── player (instance) ✓ [z_index=10, PointLight2D now internal]
├── HealthChangedMananger (instance) ✓
├── WorldBackground (instance) ✓
├── WorldEnvironment (instance) ✓
├── WorldCollectibles (instance) ✓ [fuel, boxes - context-independent]
├── WorldPowerups (instance) ✓
├── WorldEnemies (instance) ✓ [template enemy]
├── PauseMenu (instance) ✓
├── Flowery (instance) ← Level-specific placement
├── GoldCoin (instance) ← Level-specific placement
└── ShopStation (instance) ← Level-specific placement
```

---

## Organization Philosophy

### What Goes in Sub-Scenes

Sub-scenes are best for content that is **context-independent** - things that don't need to see the TileMap/platforms to be edited:

- **Backgrounds** (`world_background.tscn`) - Parallax layers, sky
- **Static environment** (`world_environment.tscn`) - Decorations, trees, props
- **Reusable prefabs** (`player.tscn`, `flowery.tscn`) - Complex entities
- **UI elements** - HUD, menus
- **TileMap** (Phase 2) - Large data that benefits from isolation

### What Stays in world.tscn

Level-specific placements that **require visual context** to position correctly:

- **Enemy spawn points** - Need to see platforms to place strategically
- **Collectible locations** - Need to see level geometry
- **Shop/NPC locations** - Need to see accessible areas
- **Triggers and checkpoints** - Need to align with level layout

**Key insight:** If you need to see the TileMap while placing something, it belongs in `world.tscn`.

---

## Phase 1: Quick Cleanup ✅ COMPLETED

Fix immediate organizational issues without restructuring.

### Move PointLight2D to Player Scene
- [x] Implementation

**Issue:** PointLight2D was embedded as a child of the player instance in world.tscn.

**Fix:** Added the PointLight2D directly to `entities/player/player.tscn` so it's part of the player prefab.

### Remove Unnecessary Player Wrapper
- [x] Implementation

**Issue:** "Player" Node2D wrapper only contained the player instance with z_index.

**Fix:** Set z_index=10 on the player instance directly and removed the wrapper node.

### Consolidate Duplicate Enemy
- [x] Implementation

**Issue:** Flowery enemy existed in both `world.tscn` and `WorldEnemies`.

**Fix:** Kept only one Flowery in `WorldEnemies` as a template. Level-specific enemy placements stay in `world.tscn` for visual editing context.

---

## Phase 2: TileMap Extraction ✅ COMPLETED

Extract the TileMap to reduce world.tscn file size.

### Extract TileMap to Own Scene
- [x] Implementation
- [x] Testing

**Goal:** Move the TileMap and its tile data to a separate scene file.

**Steps:**
1. ✅ Created `levels/world_tilemap.tscn`
2. ✅ Moved TileMap node and all tile data to new scene
3. ✅ Replaced TileMap in `world.tscn` with instance reference
4. ✅ Verified scene structure is correct

**Result:** `world.tscn` reduced from 73KB to 3KB - now a lightweight orchestration file.

### Consider Multi-Layer TileMaps
- [x] Evaluation - Single layer currently sufficient
- [ ] Implementation (if needed in future)

**Current layers in TileMap:**
- Layer 0: Background (contains tile data)
- Layer 1: FMain (contains tile data)

**Decision:** Keeping both layers in a single TileMap for now. Multi-layer extraction can be revisited if level complexity increases.

**Options (if needed later):**
- Keep single TileMap with multiple layers (current approach)
- Split into separate TileMaps per layer (Background, Platforms, Foreground)
- Each layer could be its own scene for independent editing

---

## Phase 3: Level Chunking (For Large Worlds)

If the world continues to grow, consider area-based organization.

### Area-Based Scene Structure
- [ ] Planning
- [ ] Implementation

**Concept:** Split the world into distinct areas, each with its own scenes.

**Proposed structure:**
```
levels/
├── world.tscn (main orchestrator)
├── world.gd
├── world.tres (TileSet)
├── areas/
│   ├── area_start/
│   │   ├── area_start.tscn (area root)
│   │   ├── area_start_tilemap.tscn
│   │   ├── area_start_enemies.tscn
│   │   └── area_start_collectibles.tscn
│   ├── area_cave/
│   │   ├── area_cave.tscn
│   │   └── ...
│   └── area_forest/
│       └── ...
```

**Benefits:**
- Edit areas independently
- Smaller file sizes per scene
- Easier collaboration
- Potential for runtime loading/unloading

### Runtime Area Loading
- [ ] Planning
- [ ] Implementation

**Concept:** Load/unload areas as player moves through the world.

**Implementation:**
- Area trigger zones detect player entry/exit
- Load adjacent areas, unload distant ones
- Maintain seamless transitions

**Note:** Only needed for very large worlds. May be overkill for current scope.

---

## Phase 4: Workflow Improvements

Establish conventions to prevent future bloat.

### World Scene Guidelines
- [x] Document conventions

**Rules for world.tscn:**
1. **Level-specific placements** - Enemies, collectibles, NPCs that need visual context
2. **Instance sub-scenes** - For context-independent content (backgrounds, UI, TileMap)
3. **Keep prefabs separate** - Complex entities (player, enemy types) as their own scenes
4. **Named consistently** - Use `World*` prefix for world sub-scenes

**Decision tree for new content:**
- Does it need to see the TileMap to position? → Add to `world.tscn`
- Is it context-independent? → Add to appropriate sub-scene
- Is it a complex reusable entity? → Create a prefab scene

### Sub-Scene Catalog

**Current sub-scenes:**
| Scene | Purpose | Location |
|-------|---------|----------|
| `world_tilemap.tscn` | Level geometry (TileMap) | `levels/` |
| `world_background.tscn` | Parallax backgrounds | `environment/` |
| `world_environment.tscn` | Static environment objects | `environment/` |
| `world_collectibles.tscn` | Fuel, boxes (templates) | `collectibles/` |
| `world_powerups.tscn` | Powerup stations | `collectibles/powerup/` |
| `world_enemies.tscn` | Enemy templates | `entities/enemies/` |

**Proposed additions:**
| Scene | Purpose | Location |
|-------|---------|----------|
| `world_hazards.tscn` | Spikes, pits, etc. | `environment/` |

---

## Implementation Checklist

### Phase 1 Tasks (Quick Cleanup) ✅
- [x] Move PointLight2D into player.tscn
- [x] Remove Player wrapper node, set z_index on player directly
- [x] Consolidate duplicate enemies (keep level-specific in world.tscn)

### Phase 2 Tasks (TileMap Extraction) ✅
- [x] Create levels/world_tilemap.tscn
- [x] Move TileMap to new scene
- [x] Replace TileMap in world.tscn with instance
- [x] Verify scene structure is correct

### Verification (Phase 2)
- [x] Scene files created correctly
- [x] TileMap instance reference working
- [ ] Game runs without errors (requires Godot runtime test)
- [ ] Player spawns correctly (requires Godot runtime test)
- [ ] Collision detection working (requires Godot runtime test)

---

## Target Structure

After Phase 2, `world.tscn` should look like:

```
World (Node2D)
├── WorldTilemap (instance) ← Extracted (Phase 2)
├── WorldBackground (instance)
├── WorldEnvironment (instance)
├── WorldCollectibles (instance) [templates]
├── WorldPowerups (instance)
├── WorldEnemies (instance) [templates]
├── player (instance)
├── UI (instance)
├── HealthChangedMananger (instance)
├── PauseMenu (instance)
├── [Level-specific enemy placements]
├── [Level-specific collectibles]
└── [Level-specific shops/NPCs]
```

**Benefits:**
- TileMap data isolated (smaller diffs, cleaner world.tscn)
- Level-specific content editable with full visual context
- Prefabs remain reusable
- Clear separation between templates and placements

---

## Notes

### Godot TileMap Considerations

- TileMap tile_data is stored as `PackedInt32Array` in the scene file
- Each tile placement adds entries to this array
- Large tilemaps = large scene files (unavoidable without chunking)
- Extracting to sub-scene doesn't reduce total data, but improves organization

### Git Workflow

- Large tilemap changes create large diffs
- Consider `.gitattributes` to treat .tscn as binary for tilemap scenes
- Or use Godot's scene format compression (project settings)

### Editor Workflow

After TileMap extraction:
- Double-click `world_tilemap.tscn` to edit tiles
- Edit enemy/collectible placements in `world.tscn` with full level context
- Use "Editable Children" sparingly (creates overrides in parent scene)
