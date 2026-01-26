# Dialogue System Development Roadmap

This document tracks planned improvements to Zara's dialogue system. The current implementation provides basic sequential dialogue - this roadmap expands it into a full-featured conversation system.

## Current Implementation

**What exists:**
- `DialoguePlayer.gd` - Sequential line-by-line dialogue player
- `DialoguePlayer.tscn` - NinePatchRect UI with speaker name and message
- `dialogue/json/powerup_stations.json` - Single dialogue file
- Integration with powerup stations via `dialogue_done` signal
- Player movement disabled during dialogue (`set_player_active` signal)

**Current JSON format:**
```json
[
  {"name": "Computer", "text": "Looking for something fun?"},
  {"name": "Zara", "text": "That's exactly what I'm looking for."}
]
```

---

## Phase 1: Polish & Effects

Enhance the existing system without changing architecture.

### Typewriter Effect
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Text appears character-by-character instead of all at once.

**Implementation:**
- Add `characters_per_second` export variable
- Use Timer or `_process()` to reveal characters
- Allow skipping to full text on input
- Optional sound effect per character

**Changes:**
- `DialoguePlayer.gd` - Add typing logic
- Consider `RichTextLabel` with `visible_characters` property

### Input Indicator
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Visual indicator showing player can advance dialogue.

**Implementation:**
- Animated arrow/icon at bottom of dialogue box
- Appears after text fully displayed
- Bouncing or pulsing animation

### Sound Effects
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Audio feedback for dialogue interactions.

**Sounds needed:**
- Dialogue open/close
- Text advance (blip per character or per line)
- Different voice sounds per character (optional)

---

## Phase 2: Visual Enhancements

Add character portraits and improved presentation.

### Speaker Portraits
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Character portraits displayed alongside dialogue.

**JSON format update:**
```json
{
  "name": "Zara",
  "text": "Hello!",
  "portrait": "zara_happy"
}
```

**Implementation:**
- Add portrait TextureRect to DialoguePlayer.tscn
- Portrait sprite lookup from `assets/portraits/` or resource
- Support multiple expressions per character
- Flip/highlight active speaker in two-person conversations

### Dialogue Box Variants
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Different dialogue box styles for different contexts.

**Variants:**
- Standard NPC dialogue
- System/computer messages (current style)
- Internal thoughts (Zara thinking)
- Important/quest dialogue (highlighted border)

### Name Colors
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Color-coded speaker names for quick identification.

**Implementation:**
- Define color per character in dialogue data or lookup table
- Use BBCode in RichTextLabel: `[color=#ff0000]Zara:[/color]`

---

## Phase 3: Branching Dialogue

Add player choices and non-linear conversations.

### Choice System
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Player can select from multiple response options.

**JSON format update:**
```json
{
  "id": "greeting",
  "name": "Merchant",
  "text": "What can I do for you?",
  "choices": [
    {"text": "Show me your wares", "next": "shop_intro"},
    {"text": "Any news?", "next": "rumors"},
    {"text": "Goodbye", "next": "farewell"}
  ]
}
```

**Implementation:**
- Add choice UI (vertical list of buttons)
- Node-based dialogue structure with IDs
- Jump to specific dialogue nodes based on choice
- Emit signal with chosen option for game logic

### Choice UI
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Visual presentation of dialogue choices.

**Features:**
- Keyboard navigation (up/down to select, confirm to choose)
- Mouse click support
- Highlight on hover/selection
- Consistent styling with dialogue box

### Conditional Dialogue
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Dialogue options/paths based on game state.

**JSON format update:**
```json
{
  "id": "jetpack_offer",
  "name": "Computer",
  "text": "Want this jetpack?",
  "condition": {"type": "item_missing", "item": "jetpack"},
  "else_next": "already_have_jetpack"
}
```

**Conditions to support:**
- `has_item` / `item_missing`
- `has_upgrade`
- `gold_amount` (>=, <)
- `quest_state`
- `flag_set` (arbitrary game flags)

**Implementation:**
- Evaluate conditions against Game autoload
- Skip or redirect dialogue based on conditions
- Could use simple expression evaluator

---

## Phase 4: NPC System

Create dedicated NPC entities with dialogue capabilities.

### NPC Base Class
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Reusable NPC component for characters in the world.

**Features:**
- `npc.gd` extending Area2D or CharacterBody2D
- Export variable for dialogue file path
- Interaction prompt when player nearby
- Optional idle animations

**Scene structure:**
```
NPC (Area2D)
├── Sprite2D
├── CollisionShape2D
├── InteractionArea (Area2D)
├── InteractionPrompt (Label/Sprite)
└── DialoguePlayer (or reference to singleton)
```

### Dialogue Singleton
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Global dialogue manager instead of per-object DialoguePlayer.

**Benefits:**
- Single UI instance
- Easier to manage dialogue state
- NPCs just call `DialogueManager.start("npc_name", "dialogue_id")`
- Centralized dialogue loading and caching

**Implementation:**
- New autoload: `global/dialogue_manager.gd`
- Move UI to persistent CanvasLayer
- NPCs trigger dialogue via manager

### NPC States
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** NPCs remember conversation state.

**Features:**
- Track which dialogues have been seen
- Different greetings for first vs repeat visits
- State persisted in save file
- "New dialogue" indicator for NPCs with unseen content

---

## Phase 5: Quest Integration

Connect dialogue to game progression.

### Quest Triggers
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Dialogue can start, advance, or complete quests.

**JSON format update:**
```json
{
  "name": "Elder",
  "text": "Please find my lost amulet!",
  "actions": [
    {"type": "start_quest", "quest_id": "lost_amulet"},
    {"type": "add_marker", "location": "cave_entrance"}
  ]
}
```

**Action types:**
- `start_quest` / `complete_quest`
- `give_item` / `take_item`
- `give_gold` / `take_gold`
- `unlock_ability`
- `set_flag`
- `teleport_player`

### Quest-Aware Dialogue
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** NPCs respond differently based on quest progress.

**Implementation:**
- Quest state conditions in dialogue
- Different dialogue trees per quest stage
- Automatic dialogue switching when quest updates

### Dialogue Events
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Dialogue triggers world events.

**Examples:**
- Door opens after conversation
- Enemy spawns
- Cutscene triggers
- Music changes

**Implementation:**
- Action system from quest triggers
- Events autoload integration
- Signal emissions for custom handling

---

## Phase 6: Advanced Features

Optional enhancements for richer storytelling.

### Cutscene Integration
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Dialogue combined with camera movement and scripted events.

**Features:**
- Camera pan to speaker
- Character movement during dialogue
- Timed pauses
- Fade in/out

### Localization Support
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Multi-language dialogue support.

**Implementation:**
- Use Godot's built-in translation system
- Dialogue keys instead of raw text
- CSV or PO file format for translations

### Dialogue Editor Tool
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Visual editor for creating dialogue trees.

**Options:**
- Godot plugin with GraphEdit
- External tool (Yarn Spinner, Twine) with import
- Simple in-editor JSON editor

### Voice Acting Support
- [ ] Design & Implementation
- [ ] Testing & Polish

**Description:** Audio clips for dialogue lines.

**JSON format:**
```json
{
  "name": "Zara",
  "text": "Let's go!",
  "audio": "res://audio/dialogue/zara_lets_go.ogg"
}
```

---

## Implementation Checklist

When enhancing the dialogue system:

1. [ ] Update `DialoguePlayer.gd` or create new manager
2. [ ] Update `DialoguePlayer.tscn` UI as needed
3. [ ] Define/update JSON schema for new features
4. [ ] Create sample dialogue files for testing
5. [ ] Update powerup station integration if needed
6. [ ] Add new NPCs using the system
7. [ ] Update save system if dialogue state needs persistence
8. [ ] Document new features in CLAUDE.md

---

## Dialogue File Organization

Proposed structure for dialogue files:

```
dialogue/
├── json/
│   ├── powerup_stations.json    (existing)
│   ├── npcs/
│   │   ├── merchant.json
│   │   ├── elder.json
│   │   └── guard.json
│   ├── quests/
│   │   ├── main_quest.json
│   │   └── side_quests.json
│   └── system/
│       ├── tutorials.json
│       └── hints.json
├── DialoguePlayer.gd
├── DialoguePlayer.tscn
└── DialogueManager.gd          (Phase 4)
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `dialogue/DialoguePlayer.gd` | Current dialogue display logic |
| `dialogue/DialoguePlayer.tscn` | Dialogue UI scene |
| `dialogue/json/powerup_stations.json` | Sample dialogue data |
| `collectibles/powerups/powerup_station_jetpack.gd` | Example integration |
| `entities/player/player.gd` | Player dialogue state handling |

---

## Completed Features

- [x] Basic sequential dialogue playback
- [x] Speaker name display
- [x] Player movement disable during dialogue
- [x] Signal-based completion notification
- [x] JSON-based dialogue data
