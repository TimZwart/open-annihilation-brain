# Open Annihilation brain

An empty OABrain (an AI script for Open Annihilation), laid out per the
[OABrain standard](https://github.com/open-annihilation/open-annihilation/blob/main/docs/brains/oabrain-standard.md)
and the [brain.lua chapter](https://mods.coreprime.net/en/packaging/brain-lua/).

## Layout

```text
my-brain/                 the package: only these files may be in it
  oabrain.yaml            manifest: id, levels, options, entry
  brain.lua               entry: returns the table of hooks (all empty)
  README.md               shown with the package, not loaded
types/oabrain.lua         editor type stubs for lua-language-server
.luarc.json               editor config (Lua 5.4, sandboxed libs off)
tools/                    pack, check and install scripts (PowerShell)
```

Anything else inside `my-brain/` makes `oa-tool brain pack` refuse the
package. Extra Lua goes in `my-brain/lua/<name>.lua` and loads with
`require("<name>")`. Data tables go under `data/`, and networks go under
`nets/`.

Rules from the standard to keep in mind:

- Orders take effect on the next tick. A refusal returns `false`; it does not raise.
- Budget: 2,000,000 instructions per tick, banked up to 30 ticks, and 250 ms of real time. An error stops the brain, and the built-in AI takes the seat.
- `save()` must return plain data. Store unit ids, never handles. Timers are not saved. `start` runs again on load.
- Use `brain.random`, not `os`/`io`, which aren't available. Every machine in a network game must make the same decisions.
- Don't name the hooks table `brain`. That shadows the API global.

## Workflow

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

**Note:** Open Annihilation 0.8.5's `oa-tool` has no `brain` command yet.
`check.ps1` and `pack.ps1` stop with a message until you update the game.
