# World Scene Organization Roadmap

This document tracks improvements to keep `levels/world.tscn` maintainable as the game grows.

## Current State Analysis

**File:** `levels/world.tscn`
- **Lines:** 53 (scene structure) - reduced from 76 after Phase 1
- **Size:** ~73KB (due to TileMap tile_data - will be addressed in Phase 2)

**Root Cause:** The TileMap stores all tile data as a `PackedInt32Array` directly in the scene file. As the level grows, this data grows exponentially.

### Current Node Structure

```
World (Node2D)
├── TileMap ⚠️ [EMBEDDED - 70KB+ of tile data]
├── UI (instance) ✓
├── player (instance) ✓ [z_index=10, PointLight2D now internal]
├── HealthChangedMananger (instance) ✓
├── WorldBackground (instance) ✓
├── WorldEnvironment (instance) ✓
├── WorldCollectibles (instance) ✓ [includes GoldCoin]
├── WorldPowerups (instance) ✓
├── WorldShops (instance) ✓ [NEW - includes ShopStation]
├── WorldEnemies (instance) ✓ [includes all Flowery instances]
└── PauseMenu (instance) ✓
```

---

## Phase 1: Quick Cleanup ✅ COMPLETED

Fix immediate organizational issues without restructuring.

### Remove Duplicate Flowery
- [x] Implementation

**Issue:** Flowery enemy exists both in `world.tscn` and `WorldEnemies`.

**Fix:** Moved the loose Flowery instance from `world.tscn` to `world_enemies.tscn` as `Flowery2`.

### Move Loose Collectibles
- [x] Implementation

**Issue:** GoldCoin and ShopStation are directly in world.tscn.

**Fix:**
- Moved GoldCoin to `world_collectibles.tscn`
- Created `world_shops.tscn` for shop stations at `collectibles/shop/world_shops.tscn`

### Move PointLight2D to Player Scene
- [x] Implementation

**Issue:** PointLight2D is embedded as a child of the player instance in world.tscn.

**Fix:** Added the PointLight2D directly to `entities/player/player.tscn` so it's part of the player prefab.

### Remove Unnecessary Player Wrapper
- [x] Implementation

**Issue:** "Player" Node2D wrapper only contains the player instance with z_index.

**Fix:** Set z_index=10 on the player instance directly and removed the wrapper node.

---

## Phase 2: TileMap Extraction

Extract the TileMap to reduce world.tscn file size.

### Extract TileMap to Own Scene
- [ ] Implementation
- [ ] Testing

**Goal:** Move the TileMap and its tile data to a separate scene file.

**Steps:**
1. Create `levels/world_tilemap.tscn`
2. Move TileMap node to new scene (preserves tile data)
3. Instance `world_tilemap.tscn` in `world.tscn`
4. Verify collision layers still work

**Result:** `world.tscn` becomes a lightweight orchestration file.

### Consider Multi-Layer TileMaps
- [ ] Evaluation
- [ ] Implementation (if needed)

**Current layers in TileMap:**
- Layer 0: Background
- (Check for additional layers)

**Options:**
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
- [ ] Document conventions
- [ ] Team alignment

**Rules for world.tscn:**
1. **No direct content** - Only instance sub-scenes
2. **No embedded nodes** - All reusable content in separate .tscn files
3. **Organized hierarchy** - Group by category (environment, enemies, collectibles, UI)
4. **Named consistently** - Use `World*` prefix for world sub-scenes

**Checklist before adding to world.tscn:**
- [ ] Is this content already covered by a sub-scene?
- [ ] Should this be a new sub-scene instead?
- [ ] Is this a one-off placement or reusable content?

### Sub-Scene Catalog

**Current sub-scenes:**
| Scene | Purpose | Location |
|-------|---------|----------|
| `world_background.tscn` | Parallax backgrounds | `environment/` |
| `world_environment.tscn` | Static environment objects | `environment/` |
| `world_collectibles.tscn` | Fuel, coins, boxes, gold | `collectibles/` |
| `world_powerups.tscn` | Powerup stations | `collectibles/powerup/` |
| `world_enemies.tscn` | Enemy placements | `entities/enemies/` |
| `world_shops.tscn` | Shop stations | `collectibles/shop/` |

**Proposed additions:**
| Scene | Purpose | Location |
|-------|---------|----------|
| `world_tilemap.tscn` | Level geometry | `levels/` |
| `world_hazards.tscn` | Spikes, pits, etc. | `environment/` |
| `world_triggers.tscn` | Area triggers, checkpoints | `levels/` |

---

## Implementation Checklist

### Phase 1 Tasks (Quick Cleanup) ✅
- [x] Remove duplicate Flowery from world.tscn
- [x] Move GoldCoin to world_collectibles.tscn
- [x] Create world_shops.tscn and move ShopStation
- [x] Move PointLight2D into player.tscn
- [x] Remove Player wrapper node, set z_index on player directly

### Phase 2 Tasks (TileMap Extraction)
- [ ] Create levels/world_tilemap.tscn
- [ ] Move TileMap to new scene (Right-click > Save Branch as Scene)
- [ ] Replace TileMap in world.tscn with instance
- [ ] Test collision detection still works
- [ ] Verify tile editing workflow still works

### Verification
- [ ] Game runs without errors
- [ ] Player spawns correctly
- [ ] All enemies present and functional
- [ ] Collectibles work
- [ ] Shop station accessible
- [ ] Collision detection working
- [ ] Save/load still works

---

## Target Structure

After all phases, `world.tscn` should look like:

```
World (Node2D)
├── WorldTilemap (instance) ← NEW
├── WorldBackground (instance)
├── WorldEnvironment (instance)
├── WorldCollectibles (instance)
├── WorldShops (instance) ← NEW
├── WorldPowerups (instance)
├── WorldEnemies (instance)
├── WorldHazards (instance) ← FUTURE
├── WorldTriggers (instance) ← FUTURE
├── player (instance) ← SIMPLIFIED
├── UI (instance)
├── HealthChangedMananger (instance)
└── PauseMenu (instance)
```

**Benefits:**
- `world.tscn` becomes ~20 lines
- Each sub-scene independently editable
- Clear separation of concerns
- Scalable for future content

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

After extraction:
- Double-click `world_tilemap.tscn` to edit tiles
- `world.tscn` is for placement and orchestration only
- Use "Editable Children" sparingly (creates overrides in parent scene)
