# Copilot Instructions for Clash of Zombies

## Project Overview

**Clash of Zombies** (Apocaca) is a cooperative multiplayer tower defense game built with Godot 4.6. The gameplay combines village building (like Clash of Clans) with wave-based zombie survival mechanics. Players collaborate to build and defend a village against increasingly difficult zombie waves.

**Platform**: Cross-platform, primarily mobile  
**Engine**: Godot 4.6 with GL Compatibility rendering  
**Language**: GDScript  
**Physics**: Jolt Physics with zero gravity (2.5D gameplay)

## Architecture Overview

### Core Systems

1. **Game State (Autoload)**
   - **File**: `scripts/autoload/game_state.gd`
   - Central singleton managing global game state
   - Tracks: resources (gold/elixir), village grid layout, patrol mechanics, wave progression
   - Constants define grid size (14×14 cells), wall dimensions, building costs, and unit training costs
   - All buildings and units query this singleton for rules and resource management

2. **Village & Buildings**
   - **Main Scene**: `scenes/main.tscn` (contains the playable village)
   - **Building System**: `scripts/building.gd` and `scripts/village.gd`
   - Buildings are placed on a grid defined in `GameState.GRID_SIZE`
   - Each building type (TOWN_HALL, GOLD_MINE, CANNON, BARRACKS, etc.) has specific costs, production rates, and behaviors
   - Walls are created via `scripts/wall_ring.gd` — defines the defensive perimeter

3. **Unit System**
   - **Class**: `class_name Unit` in `scripts/unit.gd`
   - Two allegiances: PLAYER (barbarians) and ENEMY (zombies)
   - Shared logic: targeting, pathfinding, combat
   - **Barbarians**: Trainable from Barracks via `GameState.TRAIN_BARBARIAN_COST`
   - **Zombies**: Spawned in waves, patrol outside the wall at `GameState.PATROL_OUTSET` distance, attack when they breach
   - Movement: CharacterBody3D with waypoint-based patrol for zombies, dynamic targeting for combat

4. **Wave Management**
   - **File**: `scripts/wave_manager.gd`
   - Triggers zombie waves progressively
   - Coordinates enemy spawning and attack timing
   - Signals: `wave_started(wave_index)`, `game_over`

5. **Gameplay Systems**
   - **Camera**: `scripts/camera_rig.gd` — handles 3D camera control and viewport management
   - **HUD**: `scripts/hud.gd` — resource display, building UI, unit training
   - **World Decor**: `scripts/world_decor.gd` — environmental visuals (no external images; built with native Godot primitives)
   - **Cannon AI**: `scripts/cannon_ai.gd` — defensive tower targeting and firing

### Visual Design

- **No external image assets** — all visuals use Godot's native 3D shapes and materials
- Meshes are built procedurally in code (see `Unit._build_zombie_visual()`, `Unit._build_barbarian_visual()`)
- Materials use `StandardMaterial3D` with albedo colors and roughness parameters
- Rendering uses GL Compatibility for mobile support

### Village Grid System

- Fixed 14×14 grid with 2m cell size
- Coordinates are (x, z) in world space; buildings snap to grid cells
- Wall ring surrounds the village; zombie patrol ring is 0.95m beyond the wall
- Patrol waypoints dynamically generated as a circle with 22 points

## Key Code Patterns & Conventions

### GDScript Style

1. **Type Hints**: All functions and variables use type hints
   ```gdscript
   func setup_zombie_patrol() -> void:
   var patrol_waypoints: Array[Vector3] = []
   ```

2. **Exports for Tweaking**: Balancing parameters are `@export` for easy editor tuning
   ```gdscript
   @export var attack_damage: int = 18
   @export var attack_cooldown: float = 0.85
   ```

3. **Signal Naming**: Use present tense or past tense consistently
   - `signal resources_changed` (action-based)
   - `signal wave_started(wave_index: int)` (event-based)

### Architecture Conventions

1. **Autoload for Global State**: `GameState` is the single source of truth for:
   - Resource counts and limits
   - Building rules (costs, production)
   - Gameplay constants (grid, walls, patrol radius)
   - Wave progression
   - Enemy/ally registries

2. **Modular Building**: Each system (Unit, Building, Wave, Camera, HUD) is a separate script
   - No monolithic game manager; instead, systems communicate via signals
   - Units emit signals when health changes; other systems listen

3. **Allegiance-Based Logic**: The `Unit` class handles both allies and enemies
   - Branching logic uses `if allegiance == Allegiance.PLAYER` rather than separate classes
   - Simplifies shared mechanics (combat, pathfinding)

4. **3D World Setup**
   - Y-axis is up (standard Godot 3D)
   - X-Z plane is the terrain plane
   - Gravity is disabled (`3d/default_gravity=0.0` in project.godot)
   - Units and buildings occupy the X-Z plane; height (Y) is cosmetic

### Resource Management

- Gold and Elixir are the two resources
- Storage buildings increase resource limits (`STORAGE_GOLD_BONUS`, `STORAGE_ELIXIR_BONUS`)
- Production is per-building-type; tracked centrally in `GameState.PRODUCTION`
- Building placement deducts resources immediately; failure rolls back

## Running the Project

### Godot Executable Path
```
/home/jimmimimix/Downloads/Godot_v4.6.1-stable_linux.x86_64
```

### Opening in Godot

```bash
/home/jimmimimix/Downloads/Godot_v4.6.1-stable_linux.x86_64 --path /home/jimmimimix/gitlab/ClashOfZombies
```

Or use VS Code with the Godot Tools extension (configured in `.vscode/settings.json`).

### Playing/Testing

1. Open `scenes/main.tscn` (the main level scene)
2. Press **Play** in the Godot editor or hit F5
3. Test gameplay: place buildings, train units, survive waves

### Common Development Tasks

- **Add a new building type**: Add to `VillageBuilding.BuildingType` enum, set costs/production in `GameState`, and create visual representation
- **Adjust unit balance**: Modify `@export` parameters on `Unit` class or wave timing in `WaveManager`
- **Change grid layout**: Modify `GRID_SIZE` and `CELL_SIZE` in `GameState`

## Existing AI Assistant Config

The project includes a `.continue/rules/godot-rule.md` file (for Continue extension). Key principle:
- Maximize modularity; separate files as much as possible
- Use native Godot shapes for visuals, no external images

This should be reflected in any new code written.

## Notes for Collaboration

- Multiplayer features are not yet implemented; the architecture is designed to support them
- Game is in active development; constants in `GameState` are tuning parameters and may change frequently
- Code is primarily in French comments/signals; maintain this convention for consistency
