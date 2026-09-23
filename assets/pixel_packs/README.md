# Pixel art packs

Free pixel-art asset packs, cleaned for use in this project. Each folder keeps the
original author's internal structure so sheet groupings and naming stay intact.

What was stripped during import: promo/social images, mockups, animated GIF previews,
`.aseprite` source files, editor backup files (`*.png~`), and `-export` scratch
duplicates. Intentional recolor variants (Black/White/Green outlines) were kept.
The project's canvas texture filter is set to **Nearest** so this art stays crisp.

Sprites are spritesheets — slice them in Godot via `SpriteFrames` (AnimatedSprite2D)
or `AtlasTexture` regions. Note frame sizes vary between packs, so check each sheet's
dimensions before setting a grid.

| Folder            | Source pack                              | Contents                                             | License / notes                     |
|-------------------|------------------------------------------|------------------------------------------------------|-------------------------------------|
| `high_forest/`    | Legacy-Fantasy – High Forest 2.3         | Forest tileset, trees, HUD, player + mob animations  | (no license file shipped)           |
| `pixel_crawler/`  | Pixel Crawler – Free Pack 2.11           | Dungeon tilesets, props, crafting stations, entities | `pixel_crawler/Terms.txt`           |
| `action_city/`    | Action Pack – CITY                       | City asset sheet + character action sheets           | `action_city/Autor_note.txt`        |
| `vania_village/`  | Legacy Vania Pack – Village 0.4          | Village tileset + skeleton mob                        | `vania_village/Rate This Pack.txt`  |

Check each pack's license file before shipping/redistributing.

## Generated resources

Ready-to-use Godot resources were generated next to the source art (Godot 4.6):

- **SpriteFrames** (`<entity>.tres`) — one per character/mob/animated-prop, with each
  animation sliced into frames. Drop onto an `AnimatedSprite2D`. Loop is on for
  everything except death/dead anims; default speed 10 fps (tune per anim).
  Entities: hero, boar, small_bee, snail (High Forest); knight, wizzard, rogue,
  peasant_a, tavern_a/b, 4× skeleton, 4× orc, body_a (42 directional anims) (Pixel
  Crawler); plus animated station props (bonfire, anvil, furnace, grill, …).
- **TileSets** (`<atlas>.tileset.tres`) — 16×16 tiles, one per tile/prop atlas. Empty
  cells are skipped. Assign to a `TileMapLayer`. Covers the terrain tilesets, building
  atlases, and prop atlases across all four packs.

### Frame sizes are per-animation, not uniform
Frame boxes differ between animations (e.g. Pixel Crawler enemies: idle 32×32 but
run 64×64; the High Forest hero: run 80×80 but idle 64×80). This is how the packs were
drawn — sprites stay centered on an `AnimatedSprite2D`, so it plays fine.

### ⚠️ Double-check these (auto-slice was ambiguous)
Frame width couldn't be derived cleanly, so these were best-guessed — open them and
verify the frame count looks right, adjusting the region if not:
- **Station props** (Pixel Crawler): `Sawmill/sawmill`, `Anvil/anvil`, `Furnace/furnace`,
  `Alchemy/alchemy`, and the `bonfire` fire/smoke anims — big/irregular sheets, low
  priority for a platformer.
- **Orc – Warrior** `death` (576×80 → guessed 72×80 ×8).
- Hero `idle`/`attack_01` were verified correct (64×80); noted here only because they
  tripped the same heuristic.

### Not auto-generated (need manual handling)
- **Action City character** (`Full-Sheet.png` 2889×72, `Shot-Sheet.png` 32×17): packed
  multi-animation sheets with no clean grid — slice by hand in the SpriteFrames editor.
- **Single sprites** (trees, weapons, backgrounds, HUD, standalone props): use directly
  as a `Sprite2D` texture; no resource needed.
