# Open Annihilation brain: scaffold

A starting point for an OABrain (an AI script for Open Annihilation),
laid out per the [OABrain standard](https://github.com/open-annihilation/open-annihilation/blob/main/docs/brains/oabrain-standard.md)
and the [brain.lua chapter](https://mods.coreprime.net/en/packaging/brain-lua/).

## Layout

```text
my-brain/                 the package: only these files may be in it
  oabrain.yaml            manifest: id, levels, options, entry
  brain.lua               entry: returns the hooks table, forwards events to modules
  README.md               shown with the package, not loaded
  lua/                    modules, loaded with require "name"
    state.lua             shared state, and what save() keeps
    util.lua              record/handle helpers, unit roles, logging
    roster.lua            tracks our own units (commander, factories, ...)
    intel.lua             enemy starts, nearest enemy, attack targets
    economy.lua           commander build plan per difficulty
    production.lua        keeps factories busy
    army.lua              gathers waves and sends them
types/oabrain.lua         editor type stubs for lua-language-server
.luarc.json               editor config (Lua 5.4, sandboxed libs off)
test/                     offline mock engine and smoke test
tools/                    pack, check and install scripts (PowerShell)
```

Anything else inside `my-brain/` makes `oa-tool brain pack` refuse the
package. Extra Lua goes under `lua/` with lower-case names. Data tables
go under `data/`, and networks go under `nets/`.

## How the scaffold works

`brain.lua` keeps a list of modules. For each engine hook
(`onUnitFinished`, `onUnitIdle`, `onUnitDestroyed`, ...), it installs a
handler only if some module defines it. The handler calls each module in
list order. Modules can also define:

- `start(saved)`: reset module state.
- `think(tick)`: runs every 15 ticks (half a second) from a `brain.every` timer.
- `report()`: lines for the console's AI report.

To add behaviour, write `lua/<name>.lua` returning a table of those
functions and add `require("<name>")` to `MODULES` in `brain.lua`.

Rules from the standard to keep in mind:

- Orders take effect on the next tick. A refusal returns `false`; it does not raise.
- Budget: 2,000,000 instructions per tick, banked up to 30 ticks, and 250 ms of real time. An error stops the brain, and the built-in AI takes the seat.
- `save()` must return plain data. Store unit ids, never handles. Timers are not saved. `start` runs again on load.
- Use `brain.random`, not `os`/`io`, which aren't available. Every machine in a network game must make the same decisions.
- Don't name the hooks table `brain`. That shadows the API global.

## Workflow

```bash
lua test/run.lua
```

This runs the brain in a mock match with no game needed. It needs a Lua 5.4
interpreter on PATH.

```powershell
.\tools\check.ps1
```

This seats the brain against your `Games\totala` data on a stand-in map, without ticking.

```powershell
.\tools\pack.ps1
```

This writes `dist\<id>-<version>.oabrain`.

```powershell
.\tools\install.ps1
```

This copies the folder to `Documents\Open Annihilation\Brains\<id>`.

**Note:** the installed Open Annihilation is 0.8.5, and its `oa-tool` has
no `brain` command yet. `check.ps1` and `pack.ps1` stop with a message
until you update the game.

## Things to verify in game

The mock can't confirm these, so they are flagged in the code:

- `economy.lua`: converting a metal spot's cell to world units assumes cells count from 0. `brain.place` searches near the point, so being off by one cell should still work.
- `economy.lua`: "cheapest by metal" picks the wind generator over solar. That's poor on low-wind maps.
- `army.lua`: waves `move` to an enemy start when no enemy is in sight, so they don't stop to fight on the way.
- Before releasing, set `id`, `name` and `author` in `oabrain.yaml`, and add a `LICENSE`.
