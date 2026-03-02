# Pirate Story RPG (Roblox) — Research

## 1) Vision
A 3D pirate simulation story game with:
- First-person cinematic intro
- Character customization + coin economy
- 30 story levels (target: ~20 days to complete)
- Ship travel, hunger/survival loop, sea-monster hunting
- Dynamic world states: storms, tsunamis, calm days, snow events, summer heat, cinematic sunsets/sunrises, moon phases, cloud layers, ocean readability, distant tree silhouettes

## 2) Platform/Tech Stack
- Engine: Roblox Studio
- Language: Luau
- Editor: VS Code + Rojo sync
- Optional package manager: Wally
- Source control: Git + GitHub
- Data persistence: DataStoreService with session lock pattern
- UI: Roblox GUI
- Logging: server event telemetry

## 3) Visual Pipeline (Roblox-Compatible)
Roblox does not expose a custom full shader pipeline, so we build a "shader-like" look with lighting + post effects.

### Base Lighting
- `Lighting.Technology = Future`
- `Lighting.GlobalShadows = true`
- `Lighting.ShadowSoftness = 0.3`
- `Lighting.Brightness = 2`
- `Lighting.EnvironmentDiffuseScale = 0.35`
- `Lighting.EnvironmentSpecularScale = 0.45`

### Post Effects
- Atmosphere (day haze + storm density variants)
- ColorCorrectionEffect (warm vs cold mood LUT-like shifts)
- BloomEffect (subtle)
- SunRaysEffect (very subtle)
- DepthOfFieldEffect (cutscenes only)

### Sky and Celestial
- Preset skyboxes for: blue day, pink sunset, stormy gray, clear moonlit night
- Moon phase rotation over a multi-day cycle
- Sunrise/sunset color gradients via ColorCorrection + ClockTime interpolation

### Water Direction
- Use Future lighting reflections
- High readability in storms via foam decals/particles
- Weather-state modifiers to wave feel and fog distance

## 4) Security Requirements
- Server-authoritative coins, unlocks, quest completion, and combat outcomes
- Remote validation (types, ranges, cooldowns, state guards)
- DataStore retries with exponential backoff
- Session locking to reduce dupe risk
- Anti-spam guard for remote calls
- Moderation-safe content and licensed-only audio

## 5) Story Premise (Original)
You are a mischievous island kid. You steal a roast chicken from your mother and run, laughing, through your village in first person. In a bright grassy field, your friends join you. Together, you sprint to the harbor, board an old wooden ship, and wave goodbye to family and islanders before sailing into the unknown.

Across 30 levels, your crew grows from reckless kids to sea legends while confronting hunger, monsters, rival crews, and ancient storms. The final relic is **The Heart of Tides**: a sentient core that can calm oceans and reveal hidden routes. Your final choice defines the world ending.
