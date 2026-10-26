-- A tiny stand-in for the engine, for running the brain outside the game.
-- It fakes just enough of game, me, brain and unit handles to drive the
-- hooks through a simple match. It is not the real simulation: builds
-- finish after a fixed delay, orders always succeed, and nothing fights.

local mock = {}

local tick, timers, timer_id, events = 0, {}, 0, {}
local slots, next_slot = {}, 1
local orders_given = {}

-- Unit types ----------------------------------------------------------------
local R = {}
local function rec(t) R[t.name] = t; return t end
rec { name = "armcom", commander = true, builder = true, canmove = true, canattack = true, bmcode = 1 }
rec { name = "armmex", extractsmetal = 1, buildcostmetal = 50, bmcode = 0 }
rec { name = "armsolar", energymake = 20, buildcostmetal = 145, bmcode = 0 }
rec { name = "armwin", windgenerator = 1, buildcostmetal = 40, bmcode = 0 }
rec { name = "armmakr", makesmetal = 1, buildcostmetal = 1, bmcode = 0 }
rec { name = "armlab", builder = true, bmcode = 0, buildcostmetal = 600 }
rec { name = "armpw", canmove = true, canattack = true, buildcostmetal = 45 }
rec { name = "armrock", canmove = true, canattack = true, buildcostmetal = 90 }
rec { name = "armham", canmove = true, canattack = true, buildcostmetal = 120 }
rec { name = "armjeth", canmove = true, canattack = true, buildcostmetal = 70 }
rec { name = "armck", builder = true, canmove = true, bmcode = 1, buildcostmetal = 110 }
rec { name = "armpt", canmove = true, canattack = true, minwaterdepth = 10, buildcostmetal = 60 }

local LISTS = {
    armcom = { R.armmex, R.armsolar, R.armwin, R.armmakr, R.armlab },
    armlab = { R.armck, R.armpw, R.armrock, R.armham, R.armjeth },
}
mock.records = R

-- Handles ---------------------------------------------------------------------
local Unit = {}
Unit.__index = Unit

local function push(name, ...) events[#events + 1] = { name, table.pack(...) } end

local function spawn(record, owner, x, z, builder, finished)
    local u = setmetatable({
        id = next_slot * 1000 + 1, slot = next_slot, owner = owner, alive = true,
        type = record, type_name = record.name, type_index = next_slot,
        x = x, y = 0, z = z, finished = finished, queue_ = {}, busy = nil,
    }, Unit)
    slots[next_slot], next_slot = u, next_slot + 1
    if owner == 0 then
        push("onUnitCreated", u, builder)
        if finished then push("onUnitFinished", u, builder) end
    end
    return u
end
mock.spawn = spawn

function Unit:head_order()
    if self.busy ~= nil then return self.busy.kind, nil, false end
    return nil
end

local function order(self, kind, data)
    if not self.alive then return false, "dead" end
    if self.owner ~= 0 then return false, "not_own" end
    orders_given[#orders_given + 1] = { unit = self, kind = kind, data = data }
    return true
end

function Unit:build(record, position, facing)
    assert(math.type(position.x) == "integer" and math.type(position.z) == "integer",
        "build position must be whole world units")
    assert(facing == nil or (facing >= 0 and facing <= 3), "facing 0 to 3")
    local ok, why = order(self, "build", record)
    if ok then self.busy = { kind = "build", record = record, at = position, done = tick + 60 } end
    return ok, why
end

function Unit:queue(record, count)
    assert(self.type.bmcode == 0 and self.type.builder, "queue on a non-factory")
    local ok, why = order(self, "queue", record)
    if ok then self.busy = { kind = "queue", record = record, done = tick + 45 } end
    return ok, why
end

function Unit:attack(target) self.busy = { kind = "attack", done = tick + 300 }; return order(self, "attack", target) end
function Unit:move(position)
    assert(position.x ~= nil and position.z ~= nil, "move needs a position")
    self.busy = { kind = "move", done = tick + 300 }
    return order(self, "move", position)
end
function Unit:stop() self.busy = nil; return order(self, "stop") end

-- Globals ---------------------------------------------------------------------
local spots = {}
for _, c in ipairs { { 10, 10 }, { 11, 10 }, { 14, 8 }, { 8, 15 }, { 50, 50 }, { 20, 12 } } do
    spots[#spots + 1] = { cx = c[1], cz = c[2] }
end

local map = {
    name = "Mock Flats", width = 64, world_width = 1024, world_height = 1024,
    sea_level = 0, wind_min = 0, wind_max = 20,
}
function map:metal_spots() return spots end
function map:starts()
    return { { index = 1, x = 160, z = 160 }, { index = 2, x = 860, z = 860 } }
end

function mock.install(options)
    game = {
        mode = "skirmish", difficulty = options.difficulty or "medium", in_match = true,
        map = map, expansions = {},
        build_list = function(record) return LISTS[record.name] or {} end,
    }
    function game:has_expansion() return false end

    me = {
        player = 0, level = options.difficulty or "medium", difficulty = options.difficulty or "medium",
        options = options.options or { wave = "small", verbose = false },
        name = "Mock", tick = 0, seen = {}, metal = 100, metal_storage = 1000,
        energy = 500, energy_storage = 1000,
    }
    function me:allied(p) return p == 0 end
    function me:players()
        return {
            { player = 0, allied = false, alive = true, start_x = 160, start_z = 160 },
            { player = 1, allied = false, alive = true, start_x = 860, start_z = 860 },
        }
    end
    function me:each_unit(fn)
        local list = {}
        for _, u in pairs(slots) do if u.owner == 0 and u.alive then list[#list + 1] = u end end
        table.sort(list, function(a, b) return a.slot < b.slot end)
        for _, u in ipairs(list) do fn(u) end
    end
    function me:sees(x, z) return false end

    brain = {}
    brain.random = math.random
    function brain.every(n, fn) timer_id = timer_id + 1; timers[timer_id] = { due = tick + n, every = n, fn = fn }; return timer_id end
    function brain.after(n, fn) timer_id = timer_id + 1; timers[timer_id] = { due = tick + n, fn = fn }; return timer_id end
    function brain.cancel(id) local had = timers[id] ~= nil; timers[id] = nil; return had end
    function brain.distance(a, b)
        if a.x == nil or b.x == nil then return nil end
        local dx, dz = a.x - b.x, a.z - b.z
        return math.floor(math.sqrt(dx * dx + dz * dz))
    end
    function brain.place(record, near, radius, facing)
        assert(radius > 0, "place expects a radius in world units")
        local x, z = math.floor(near.x), math.floor(near.z)
        return x // 16, z // 16, x, z
    end
    function brain.say() return false, "no_chat" end
end

-- The loop --------------------------------------------------------------------
local function step(hooks)
    tick = tick + 1
    me.tick = tick
    -- finish orders
    for _, u in pairs(slots) do
        if u.alive and u.busy ~= nil and tick >= u.busy.done then
            local b = u.busy
            u.busy = nil
            if b.kind == "build" then
                spawn(b.record, 0, b.at.x, b.at.z, u, true)
            elseif b.kind == "queue" then
                spawn(b.record, 0, u.x, u.z + 32, u, true)
            end
            push("onUnitIdle", u)
        end
    end
    local queued = events
    events = {}
    for _, e in ipairs(queued) do
        local fn = hooks[e[1]]
        if fn then fn(table.unpack(e[2], 1, e[2].n)) end
    end
    local due = {}
    for id, t in pairs(timers) do if t.due <= tick then due[#due + 1] = id end end
    table.sort(due)
    for _, id in ipairs(due) do
        local t = timers[id]
        if t then
            t.fn()
            if t.every then t.due = t.due + t.every else timers[id] = nil end
        end
    end
    if hooks.onTick then hooks.onTick(tick) end
end

function mock.run(hooks, ticks)
    for _ = 1, ticks do step(hooks) end
end

function mock.reveal_enemy(x, z)
    local u = spawn(R.armpw, 1, x, z, nil, true)
    me.seen[#me.seen + 1] = u
    return u
end

function mock.orders() return orders_given end
function mock.units(owner)
    local list = {}
    for _, u in pairs(slots) do if u.owner == owner and u.alive then list[#list + 1] = u end end
    return list
end

return mock
