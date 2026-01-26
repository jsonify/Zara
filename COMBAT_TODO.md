# Combat System Implementation - Fuel Grenades

## Overview

Implement a resource-based combat system where the player uses **fuel grenades** as their primary weapon. Grenades consume the same fuel used for the jetpack, creating tactical tension between mobility and combat.

### Design Goals
- **Resource tension**: Fuel is shared between jetpack and combat
- **Progression gating**: Requires jetpack unlock + grenade pickup
- **Tactical gameplay**: Players must use grenades sparingly
- **Unified aesthetic**: Combat tied to fuel/energy theme

### Core Mechanics
| Property | Value | Notes |
|----------|-------|-------|
| Fuel cost | 8 per grenade | ~3-4 grenades per full tank |
| Damage | 15 | 2 hits to kill basic enemies (20 HP) |
| Trajectory | Arc (gravity-affected) | Lob mechanic, skill-based aiming |
| Explosion | Small AoE (32px radius) | Can hit multiple enemies |
| Unlock | Jetpack + Grenade Pickup | Found after jetpack area |

---

## Phase 1: Fix Existing Combat Infrastructure

Before building grenades, ensure the current combat systems work properly.

### 1.1 Wire Up Attack Input to States
- [x] In `player.gd`, add state transitions for `attack_input` flag (ALREADY DONE in IDLE.gd/MOVE.gd)
- [x] In `player.gd`, add state transitions for `ranged_input` flag (ALREADY DONE in IDLE.gd/MOVE.gd)
- [x] Verify ATTACK state activates melee HitBox (verified in ATTACK.gd)
- [x] Verify RANGED state spawns projectile (verified in RANGED.gd)
- [ ] Test: Player can attack with J key / left mouse

### 1.2 Standardize Enemy Damage Handling
- [x] Add Damageable component to `base_enemy.tscn`
- [x] Add HurtBox component to `base_enemy.tscn`
- [x] Spidey inherits from base_enemy (gets Damageable automatically)
- [x] enemyx.gd not used in any scene (skipped)
- [x] Replace `queue_free()` calls with proper death handling
- [x] Add death animations to patrol enemies (fade-out effect)
- [x] Ensure all enemies drop gold on death (via Damageable._drop_gold())
- [ ] Test: Enemies take damage and die properly

### 1.3 Verify Collision Layers
- [x] Fixed AttackHitBox collision_mask: 256 → 260 (now detects enemy bodies)
- [x] Confirm enemy HitBox hits player HurtBox (EnemyHitBox mask=512, PlayerHurtBox layer=512)
- [x] Confirm projectiles hit enemies (Projectile mask=260 includes Enemy layer 4)
- [ ] Test: Full collision verification in-game

**Collision Layer Reference:**
| Layer | Value | Name |
|-------|-------|------|
| 3 | 4 | Enemy (CharacterBody2D) |
| 4 | 8 | Projectile |
| 8 | 128 | HitBox |
| 9 | 256 | EnemyHurtBox |
| 10 | 512 | PlayerHurtBox |

**Phase 1 Complete When:** Player can kill enemies with existing melee/ranged attacks, enemies die with animations and drop gold.

---

## Phase 2: Fuel Grenade Core Implementation

Convert the ranged attack into a fuel-based grenade system.

### 2.1 Create Grenade Projectile
- [ ] Duplicate `projectile.tscn` → `grenade.tscn`
- [ ] Create `grenade.gd` extending the projectile or Area2D
- [ ] Implement arc trajectory with gravity
  - [ ] Add `gravity` export variable (default: 400)
  - [ ] Add `initial_velocity` for launch speed
  - [ ] Add `launch_angle` based on player aim/facing
  - [ ] Update `_physics_process` for parabolic motion
- [ ] Rotate sprite to match trajectory angle
- [ ] Set appropriate collision layers (hit enemies + environment)

### 2.2 Implement Explosion
- [ ] Create `explosion.tscn` scene
  - [ ] Area2D with CircleShape2D (radius: 32px)
  - [ ] AnimatedSprite2D or particles for explosion visual
  - [ ] Short lifetime (0.3-0.5s)
- [ ] Create `explosion.gd` script
  - [ ] On spawn, detect all Damageable nodes in radius
  - [ ] Apply damage to each (with knockback from center)
  - [ ] Play explosion animation
  - [ ] Queue free after animation
- [ ] Grenade spawns explosion on:
  - [ ] Enemy collision
  - [ ] Environment collision
  - [ ] Lifetime expiry (optional: dud or still explodes?)

### 2.3 Fuel Cost Integration
- [ ] Add `grenade_fuel_cost` constant to `Game.gd` (default: 8)
- [ ] In RANGED state, check `Game.fuel_level >= Game.grenade_fuel_cost`
- [ ] Deduct fuel on grenade throw
- [ ] Add visual/audio feedback when out of fuel (can't throw)
- [ ] Test: Throwing grenades depletes fuel properly

### 2.4 Update RANGED State for Grenades
- [ ] Modify `RANGED.gd` to spawn grenade instead of projectile
- [ ] Calculate launch direction based on player facing
- [ ] Add slight upward angle for arc (30-45 degrees)
- [ ] Adjust cooldown if needed (0.5s feels right)
- [ ] Add throw animation (or reuse ranged animation)

**Phase 2 Complete When:** Player can throw grenades that arc through the air, explode on contact, damage enemies in a radius, and consume fuel.

---

## Phase 3: Unlock & Progression System

Gate the grenade ability behind progression.

### 3.1 Grenade Unlock Pickup
- [ ] Create `grenade_pickup.tscn` (similar to jetpack powerup)
- [ ] Create `grenade_pickup.gd` script
  - [ ] On player contact, grant grenade ability
  - [ ] Show unlock message/UI feedback
  - [ ] Disable/remove pickup after collection
- [ ] Add `has_grenades` boolean to `Game.gd`
- [ ] Add grenade unlock to save/load system in `Utils.gd`

### 3.2 Gate Grenade Usage
- [ ] In RANGED state, check `Game.has_grenades` before allowing throw
- [ ] In RANGED state, check `Game.jetpack` is unlocked (design requirement)
- [ ] Show feedback if player tries to throw without unlock
- [ ] Optional: Different feedback for "no grenades" vs "no fuel"

### 3.3 Place Grenade Pickup in World
- [ ] Identify location in world (after jetpack area)
- [ ] Instance grenade pickup in `world_powerups.tscn`
- [ ] Add any necessary platforming/puzzle to reach it
- [ ] Test: Full progression flow (jetpack → grenade pickup → combat)

**Phase 3 Complete When:** Grenades are locked until player collects pickup, save/load preserves unlock state.

---

## Phase 4: Visual & Audio Polish

Make the grenades feel impactful.

### 4.1 Grenade Visuals
- [ ] Create/source grenade sprite (fuel canister aesthetic)
- [ ] Add rotation during flight
- [ ] Add trail effect (particles or line)
- [ ] Grenade should visually "tumble" in arc

### 4.2 Explosion Visuals
- [ ] Create explosion animation (orange/fuel colored)
- [ ] Add screen shake on explosion (subtle, 2-3px)
- [ ] Add particle burst effect
- [ ] Flash/highlight damaged enemies briefly

### 4.3 Audio
- [ ] Grenade throw sound
- [ ] Grenade explosion sound
- [ ] "Out of fuel" error sound (when trying to throw empty)
- [ ] Optional: Grenade bounce sound if it hits ground without exploding

### 4.4 UI Feedback
- [ ] Show fuel cost when aiming/throwing
- [ ] Flash fuel bar when grenade thrown
- [ ] Optional: Grenade count or "ready" indicator
- [ ] Optional: Aim trajectory preview (advanced)

**Phase 4 Complete When:** Grenades look and sound satisfying, player has clear feedback on fuel state.

---

## Phase 5: Balance & Tuning

Playtest and adjust values.

### 5.1 Fuel Economy
- [ ] Playtest fuel cost (8) - adjust if too cheap/expensive
- [ ] Consider fuel pickup frequency in levels
- [ ] Balance jetpack vs grenade fuel usage
- [ ] Document final fuel economy values

### 5.2 Damage & Enemy Health
- [ ] Playtest grenade damage (15) vs enemy HP (20)
- [ ] Adjust explosion radius if needed
- [ ] Consider enemy armor/resistance for variety
- [ ] Test AoE damage on grouped enemies

### 5.3 Trajectory & Feel
- [ ] Tune gravity for satisfying arc
- [ ] Tune launch velocity for range
- [ ] Playtest throwing while jumping/moving
- [ ] Ensure grenades feel skill-based but not frustrating

### 5.4 Difficulty Curve
- [ ] Ensure player has enough fuel for first combat encounters
- [ ] Place fuel pickups appropriately near combat areas
- [ ] Test full level playthrough with new combat system

**Phase 5 Complete When:** Combat feels balanced, challenging but fair, fuel creates meaningful decisions.

---

## Phase 6: Testing & Integration

Ensure reliability and prevent regressions.

### 6.1 Unit Tests
- [ ] Test grenade fuel cost deduction
- [ ] Test grenade unlock state in Game.gd
- [ ] Test explosion damage application
- [ ] Test save/load of grenade unlock

### 6.2 Integration Tests
- [ ] Test grenade-enemy collision in scene
- [ ] Test grenade-environment collision
- [ ] Test AoE hitting multiple enemies
- [ ] Test grenade with moving enemies

### 6.3 Edge Cases
- [ ] Grenade thrown at point-blank range
- [ ] Grenade thrown while falling/jumping
- [ ] Multiple grenades in flight simultaneously
- [ ] Grenade hitting player (should it? probably not)
- [ ] Throwing grenade with exactly enough fuel (edge)
- [ ] Enemy dies mid-explosion

### 6.4 Save System
- [ ] Verify grenade unlock persists across saves
- [ ] Test loading save without grenade unlock
- [ ] Test loading save with grenade unlock

**Phase 6 Complete When:** All tests pass, no known edge case bugs.

---

## Future Considerations (Out of Scope)

Ideas to potentially add later, not part of initial implementation:

- [ ] Grenade variants (incendiary, cluster, sticky)
- [ ] Charged throw for longer range
- [ ] Grenade crafting from fuel + materials
- [ ] Enemy grenades / grenade-throwing enemies
- [ ] Destructible environment with grenades
- [ ] Aim trajectory preview line
- [ ] Grenade upgrades in shop (damage, radius, efficiency)

---

## Files to Create/Modify

### New Files
- `entities/projectiles/grenade.tscn`
- `entities/projectiles/grenade.gd`
- `effects/explosion.tscn`
- `effects/explosion.gd`
- `collectibles/powerups/grenade_pickup.tscn`
- `collectibles/powerups/grenade_pickup.gd`
- `test/unit/test_grenade_system.gd`

### Modified Files
- `global/game.gd` - Add `has_grenades`, `grenade_fuel_cost`
- `global/utils.gd` - Add grenade to save/load
- `entities/player/RANGED.gd` - Spawn grenade, check fuel/unlock
- `entities/player/ATTACK.tscn` - Fixed collision mask (Phase 1) ✓
- `entities/enemies/base_enemy.tscn` - Added Damageable + HurtBox (Phase 1) ✓
- `entities/enemies/base_enemy.gd` - Added damage/death handling (Phase 1) ✓
- `entities/enemies/spidey.gd` - Removed old queue_free() (Phase 1) ✓
- `entities/enemies/blinding_spider.gd` - Added is_dead check (Phase 1) ✓
- `levels/world_powerups.tscn` - Place grenade pickup

---

## Progress Tracker

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1: Fix Infrastructure | In Progress | Code complete, needs testing |
| Phase 2: Grenade Core | Not Started | |
| Phase 3: Unlock System | Not Started | |
| Phase 4: Polish | Not Started | |
| Phase 5: Balance | Not Started | |
| Phase 6: Testing | Not Started | |

**Last Updated:** 2026-01-25
