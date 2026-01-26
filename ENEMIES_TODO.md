# Enemy Development Roadmap

This document tracks planned enemy types for Zara. All enemies should use the **CharacterStateMachine** pattern established by the Flowery enemy (`entities/enemies/flower/`).

## Architecture Reference

New enemies should follow this structure:
- Extend `CharacterBody2D`
- Use `CharacterStateMachine` with `State` children
- Integrate `Damageable` component for health/damage
- Use `HurtBox` to receive damage, `HitBox` to deal damage
- Create enemy resource (`.tres`) for stats
- Use `AnimationTree` for state-driven animations

See `entities/enemies/flower/flowery.tscn` as the reference implementation.

---

## Phase 1: Stationary Enemies

Simple enemies that don't patrol - good for learning the pattern.

### Turret
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Stationary enemy that rotates to track player and fires projectiles periodically.

**States:**
- `Idle` - Scanning/waiting for player in range
- `Aim` - Rotating toward player
- `Attack` - Fire projectile, cooldown
- `Hit` - Damage reaction (can be stunned briefly)
- `Dead` - Destruction animation

**Notes:**
- Reuse projectile system from player's ranged attack
- Detection area for player awareness
- Could have variants (fast weak shots vs slow powerful shots)

---

## Phase 2: Ground Enemies

Enemies that patrol and have attack behaviors.

### Charging Enemy
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Patrols normally, charges at player when detected. Has wind-up animation before charge.

**States:**
- `Patrol` - Normal movement with wall/ledge detection
- `Alert` - Player detected, wind-up animation
- `Charge` - Fast movement toward player, stops on wall hit
- `Stunned` - Recovery after hitting wall or player
- `Hit` - Damage reaction with knockback
- `Dead` - Death animation

**Notes:**
- Higher knockback when hitting player during charge
- Vulnerable during Stunned state
- Could damage environment (destructible boxes)

### Shielded Enemy
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Carries a shield that blocks frontal attacks. Must be attacked from behind or above.

**States:**
- `Patrol` - Normal movement, shield facing forward
- `Block` - Blocking incoming attack (no damage taken)
- `Stunned` - Brief vulnerability after blocking heavy attack
- `Hit` - Damage from unblocked direction
- `Dead` - Death animation

**Notes:**
- Separate HurtBox for front (shielded) and back (vulnerable)
- Shield could have durability or be invincible
- Visual/audio feedback when attack is blocked

---

## Phase 3: Ranged Enemies

Enemies that attack from a distance.

### Ranged Enemy (Archer/Spitter)
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Maintains distance from player, fires projectiles. Retreats if player gets too close.

**States:**
- `Patrol` - Normal movement
- `Aim` - Player in range, preparing to fire
- `Attack` - Fire projectile
- `Retreat` - Player too close, moving away
- `Hit` - Damage reaction
- `Dead` - Death animation

**Notes:**
- Projectile could have arc (lobbed) or straight line
- Detection range for attack vs retreat threshold
- Lower health than melee enemies (glass cannon)

---

## Phase 4: Flying Enemies

Aerial enemies with different movement patterns.

### Flying Enemy (Swooper)
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Flies in patrol pattern above ground. Dives at player when detected, returns to patrol height.

**States:**
- `Patrol` - Horizontal flying movement at set height
- `Alert` - Player detected, preparing to dive
- `Dive` - Fast diagonal movement toward player
- `Rise` - Returning to patrol height after dive
- `Hit` - Damage reaction (falls briefly)
- `Dead` - Falls to ground, death animation

**Notes:**
- Ignores gravity during normal states
- Vulnerable during Rise state
- Could drop items when killed mid-air

### Hovering Enemy (Bomber)
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Hovers above player and drops projectiles/bombs downward.

**States:**
- `Patrol` - Horizontal flying movement
- `Track` - Moving to position above player
- `Attack` - Drop bomb/projectile
- `Hit` - Damage reaction
- `Dead` - Death animation

**Notes:**
- Bombs affected by gravity, explode on contact
- Maintains safe height above player
- Could be immune to melee, requiring ranged attacks

---

## Phase 5: Boss Enemies

Complex enemies with multiple attack patterns and phases.

### Mini-Boss Template
- [ ] Design & Implementation
- [ ] Testing & Polish

**Behavior:** Larger enemy with multiple attack patterns that change based on health.

**States:**
- `Idle` - Waiting for player to engage
- `Phase1_Attack1` - First attack pattern
- `Phase1_Attack2` - Second attack pattern
- `Transition` - Health threshold reached, change phase
- `Phase2_Attack1` - More aggressive attack
- `Phase2_Attack2` - New attack pattern
- `Hit` - Damage reaction (shorter than normal enemies)
- `Dead` - Extended death sequence

**Notes:**
- Health bar UI element
- Invincibility during transitions
- Arena lock (player can't leave during fight)
- Unique music/atmosphere

---

## Implementation Checklist

When implementing a new enemy:

1. [ ] Create enemy directory: `entities/enemies/{enemy_name}/`
2. [ ] Create main script extending `CharacterBody2D`
3. [ ] Create state scripts extending `State`
4. [ ] Build scene with proper node hierarchy:
   - CollisionShape2D
   - Sprite2D (or AnimatedSprite2D)
   - AnimationPlayer
   - AnimationTree (StateMachine)
   - CharacterStateMachine with state children
   - Damageable component
   - HurtBox
   - HitBox (for dealing damage)
   - Detection area (if needed)
5. [ ] Create enemy resource in `resources/enemies/`
6. [ ] Set up collision layers properly
7. [ ] Add to test level for tuning
8. [ ] Write unit tests if complex logic involved
9. [ ] Add to world scenes

---

## Completed Enemies

- [x] **Flowery** - Phase 2 reference implementation (Move/Hit/Dead states)
- [x] **Spidey** - BaseEnemy pattern (patrol + speed boost)
- [x] **Blinding Spider** - BaseEnemy pattern (simple patrol)
