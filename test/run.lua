-- Runs the brain against test/mock.lua. From the project folder:
--   lua test/run.lua
-- Any Lua 5.4 works; the game is not needed.

package.path = "test/?.lua;my-brain/lua/?.lua;" .. package.path
math.randomseed(1)

local mock = require("mock")
mock.install { difficulty = "medium", options = { wave = "small", verbose = false } }

local function check(cond, message)
    if not cond then error("FAILED: " .. message, 2) end
    print("ok   " .. message)
end

local function is_plain(value, depth)
    depth = depth or 0
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then return true end
    if kind ~= "table" or getmetatable(value) ~= nil or depth > 64 then return false end
    for k, v in pairs(value) do
        if (type(k) ~= "string" and math.type(k) ~= "integer") or not is_plain(v, depth + 1) then
            return false
        end
    end
    return true
end

local hooks = dofile("my-brain/brain.lua")
check(type(hooks) == "table", "brain.lua returns a table of hooks")
check(hooks.fits(game) == true, "fits returns true")

mock.spawn(mock.records.armcom, 0, 160, 160, nil, true)
hooks.start(game, me, nil)
mock.run(hooks, 1500)

local own = mock.units(0)
local count = {}
for _, u in ipairs(own) do count[u.type_name] = (count[u.type_name] or 0) + 1 end
check((count.armmex or 0) >= 3, "commander built extractors (" .. (count.armmex or 0) .. ")")
check((count.armwin or 0) >= 1, "commander built energy (" .. (count.armwin or 0) .. ")")
check((count.armmakr or 0) == 0, "no metal makers counted as energy")
check((count.armlab or 0) >= 1, "commander built a factory")
check((count.armpw or 0) + (count.armjeth or 0) + (count.armrock or 0) >= 4, "factory made combat units")
check((count.armck or 0) == 0, "factory skipped constructors")

local enemy = mock.reveal_enemy(800, 800)
mock.run(hooks, 120)
local attacked = 0
for _, o in ipairs(mock.orders()) do
    if o.kind == "attack" and o.data == enemy then attacked = attacked + 1 end
end
check(attacked >= 4, "a wave attacked the seen enemy (" .. attacked .. " orders)")

local saved = hooks.save()
check(is_plain(saved), "save returns plain data")
check(saved.persist.waves >= 1, "save keeps the wave count (" .. saved.persist.waves .. ")")

hooks.start(game, me, saved)
check(hooks.save().persist.waves == saved.persist.waves, "start restores saved data")
mock.run(hooks, 300)

local report = hooks.report()
check(type(report) == "string" and #report < 65536, "report returns text")
print("\n" .. report)
