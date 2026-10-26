-- Entry script. It must return one table of hooks; a missing hook is
-- skipped, so delete the ones you do not need.
--
-- Globals: `game` (the match, read-only), `me` (this seat), `brain`
-- (random, timers, chat, sites), and `units`, `weapons`, `features`.
-- Orders given in a hook take effect on the next tick.
--
-- Do not call this table `brain`: that would shadow the global `brain`.

local hooks = {}

-- Before the first tick. Return true, or a string the player sees as the
-- reason this brain does not fit the game.
function hooks.fits(game)
    return true
end

-- Before the first tick, and again after a saved game loads. `saved` is
-- what save() returned, or nil.
function hooks.start(game, me, saved)
end

-- Return plain data to keep in a saved game (no unit handles, functions
-- or metatables), or nothing.
function hooks.save()
end

-- Return text for the console's AI report, at most 64 KiB.
function hooks.report()
end

-- Own units ---------------------------------------------------------------

function hooks.onUnitCreated(unit, builder)
end

function hooks.onUnitFinished(unit, builder)
end

-- kind is "weapon", "paralyze", "heal" or "environment".
function hooks.onUnitDamaged(unit, attacker, amount, kind)
end

-- Also fires for allies' deaths and seen enemies' deaths.
function hooks.onUnitDestroyed(unit, killer, wreck)
end

function hooks.onUnitGiven(unit, old, from, to)
end

function hooks.onUnitIdle(unit)
end

-- result is "done" or "failed".
function hooks.onCommandDone(unit, order, result)
end

function hooks.onUnitLoaded(unit, carrier)
end

function hooks.onUnitUnloaded(unit, carrier)
end

function hooks.onPathFailed(unit)
end

-- Sight and radar ---------------------------------------------------------

function hooks.onUnitSeen(unit)
end

function hooks.onUnitLost(unit)
end

function hooks.onRadarContact(contact)
end

function hooks.onRadarLost(contact)
end

-- Players -----------------------------------------------------------------

function hooks.onAllianceChanged(player, allied)
end

function hooks.onPlayerDefeated(player)
end

-- to is "all", "allies", "enemies" or "me".
function hooks.onChat(from, text, to)
end

-- The end of every turn. 30 ticks is one second.
function hooks.onTick(tick)
end

return hooks
