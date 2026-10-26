-- State shared between modules.
--
-- Handle tables are rebuilt from the map on every start, so they never
-- need saving. Only `persist` goes into a saved game; keep it plain data
-- (numbers, strings, booleans, tables of those). Store unit ids, never
-- unit handles.

local state = {}

local SAVE_VERSION = 1

function state.reset(saved)
    state.commander = nil   -- handle of our commander, or nil
    state.units = {}        -- [id] = handle, every own live unit
    state.roles = {}        -- [id] = role string, see util.role
    state.factories = {}    -- [id] = handle, finished factories
    state.army = {}         -- [id] = handle, combat units waiting for a wave
    state.sent = {}         -- [id] = true, combat units already sent

    state.persist = {
        waves = 0,          -- attack waves sent so far
    }
    if type(saved) == "table" and saved.version == SAVE_VERSION
        and type(saved.persist) == "table" then
        for key, value in pairs(saved.persist) do
            if state.persist[key] ~= nil then state.persist[key] = value end
        end
    end
end

function state.save()
    return { version = SAVE_VERSION, persist = state.persist }
end

-- How many own live units have this role.
function state.count(role)
    local count = 0
    for id in pairs(state.units) do
        if state.roles[id] == role then count = count + 1 end
    end
    return count
end

return state
