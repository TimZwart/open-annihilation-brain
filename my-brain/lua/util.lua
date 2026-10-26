-- Small helpers for reading unit records and handles.

local util = {}

-- A value as a Lua number. Records and handles hold integers, fixed counts
-- and f32 values; the last two are userdata with :tonumber(). Anything
-- else reads as 0.
function util.number(value)
    if type(value) == "number" then return value end
    if type(value) == "userdata" and type(value.tonumber) == "function" then
        return value:tonumber()
    end
    return 0
end

function util.num(record, key)
    return util.number(record[key])
end

-- A position in whole world units, the form orders and brain.place take.
function util.pos(x, z)
    return { x = math.floor(util.number(x)), z = math.floor(util.number(z)) }
end

function util.positive(record, key)
    return util.num(record, key) > 0
end

function util.land(record)
    return util.num(record, "minwaterdepth") <= 0
end

-- What a unit type is for. Returns one of:
-- "commander", "extractor", "converter", "energy", "factory",
-- "constructor", "combat", or "other".
function util.role(record)
    if record == nil then return "other" end
    if record.commander == true then return "commander" end
    if util.positive(record, "extractsmetal") then return "extractor" end
    -- Metal makers spend energy; keep them apart from energy buildings.
    if util.positive(record, "makesmetal") then return "converter" end
    if util.positive(record, "energymake") or util.positive(record, "windgenerator")
        or util.positive(record, "tidalgenerator") then
        return "energy"
    end
    if record.builder == true then
        -- bmcode 0 is a building; a builder that cannot move is a factory.
        if record.bmcode == 0 then return "factory" end
        return "constructor"
    end
    if record.canmove == true and record.canattack == true then return "combat" end
    return "other"
end

function util.land_combat(record)
    return util.role(record) == "combat" and record.canfly ~= true and util.land(record)
end

-- The cheapest record in a list by metal cost, or nil.
function util.cheapest(list)
    local best, best_cost
    for index = 1, #list do
        local cost = util.num(list[index], "buildcostmetal")
        if best_cost == nil or cost < best_cost then best, best_cost = list[index], cost end
    end
    return best
end

-- True when the unit has no orders, or only an idle one.
function util.free(unit)
    local kind, _, idle = unit:head_order()
    return kind == nil or idle == true
end

function util.alive(unit)
    return unit ~= nil and unit.alive == true
end

function util.enemy(unit)
    return unit.owner ~= nil and unit.owner ~= me.player and me:allied(unit.owner) ~= true
end

function util.size(set)
    local count = 0
    for _ in pairs(set) do count = count + 1 end
    return count
end

-- The nearest entry of `list` to `origin`, or nil. Entries may be unit
-- handles or {x =, z =} positions.
function util.nearest(origin, list)
    local best, best_distance
    for index = 1, #list do
        local distance = brain.distance(origin, list[index])
        if distance ~= nil and (best_distance == nil or distance < best_distance) then
            best, best_distance = list[index], distance
        end
    end
    return best, best_distance
end

-- Debug output goes to <data>/logs/brains/seat-<n>.log when the verbose
-- option is on. print keeps at most 256 lines, so keep this quiet.
function util.log(fmt, ...)
    if me.options.verbose == true then print(string.format(fmt, ...)) end
end

return util
