# Repository Guidelines

## Project Structure & Module Organization
- `game/`: In-game content (Lua in `scripts/vscripts`, NPC data in `scripts/npc`, UI in `panorama`, localization in `resource`).
- `content/`: Source assets (models, particles, sounds, panorama). Built into game files via Dota 2 tools.
- `scripts/`: Node.js utilities and tests in `scripts/test/*.test.js`.
- `docs/`: Design, setup, and contributor documentation.

## Build, Test, and Development Commands
- `nvm use` (Node `v20.11.0`): Match the repo’s Node version (`.nvmrc`).
- `npm test`: Lints JS with semistandard and runs Tape tests, summarized via tap-summary.
- - Note: This outputs a lot of text, and the most useful part is always at the end. Consider using `npm run test > .test_output.log 2>&1; tail -n 200 .test_output.log`.
- `npm run spec`: Runs tests with tap-spec for readable output. Prefer to use `npm test` over this.
- `npm run fetch:dota-kv`: Downloads base Dota KV files (items, heroes, hero KV files) into `scripts/cache/dota_kv/` for offline/consistent testing. The cache directory is gitignored.
- Lint Lua with your editor + `.luacheckrc` (CI validates style). Example local run: `luacheck game/scripts/vscripts`.

## Coding Style & Naming Conventions
- Indentation: 2 spaces; UTF-8; trim trailing whitespace (`.editorconfig`).
- JavaScript: semistandard style; globals set for Dota 2 UI (`GameUI`, `Players`, etc.). Run `npm run semistandard`.
- Lua: follow `.luacheckrc` and existing patterns; prefer snake_case for files and identifiers.
- Tests: name JS tests `*.test.js` under `scripts/test/`.

## Testing Guidelines
- Framework: Tape for JS utilities in `scripts/`.
- Scope: add/extend tests when modifying parsing, KV, or translation helpers.
- Run: `npm test` (CI must pass). Keep fixtures small and colocated under `scripts/test/fixtures/` when needed.

## KV Files & Unit Tests
- Locations: `game/scripts/npc/abilities/`, `game/scripts/npc/items/`, `game/scripts/npc/heroes/`.
- Inheritance: KV entries inherit from `BaseClass` (vanilla or `*_datadriven`/`*_lua`). Tests compare our values to vanilla and allow differences only when the KV comment includes `OAA`. Example: `AbilityCooldown  // OAA: changed`.
- Specials/Values: `AbilitySpecial` and `AbilityValues` must preserve names, order, and base values vs. parent. New keys require an `OAA` comment. Item levels must keep specials consistent across levels.
- Icons: `AbilityTextureName` must be lowercase, no `.png`, and not start with `item_`. Resolved icon must exist in `game/resource/flash3/images/spellicons/` (abilities) or `.../items/` (items). Allowed exception: `item_recipe`.
- IDs/Costs/Recipes: Do not change vanilla `ID`. Non-vanilla items must have `ItemCost`. `ItemRequirements` are validated and must match parent unless commented `OAA`. Only one recipe per result; cost trees must be consistent.
- Script hooks: If `ScriptFile` is set, it must exist under `game/scripts/vscripts/`.
- Heroes: Hero ability slots must match vanilla unless the comment references the original ability. Disallowed talents include `bonus_gold` and `bonus_exp`. If an ability has `DependentOnAbility`, ensure the dependent exists on the hero and max levels align.
- Custom abilities/items: Custom content ends with `_oaa`. Updating KV keys for custom entries generally also requires updating the backing Lua logic referenced by `ScriptFile`. Do not “fix tests” by deleting or arbitrarily adding KV keys—align KV with Lua and with inheritance rules.

## Commit & Pull Request Guidelines
- Commits: concise, present-tense summaries (e.g., "Fix Lua kv links"), reference issues/PRs (e.g., `(#1234)`).
- PRs must include: clear description, linked issue, test updates (if scripts changed), screenshots/GIFs for UI/panorama changes, and notes for localization if strings changed.
- Keep PRs focused; avoid unrelated formatting churn (respect `.editorconfig`).

## Security & Configuration Tips
- Do not commit generated game files or local Steam paths; only edit files in `game/` and `content/`.
- Use the Dota 2 Addon Manager per `docs/setup/install.md` to run locally; avoid hardcoding user-specific paths.
