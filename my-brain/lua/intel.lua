-- What we know about the other players: start positions, and the nearest
-- thing worth attacking.

local state = require("state")
local util = require("util")

local intel = {}

local CLEAR_RADIUS = 600  -- a start with no enemy this close, in sight, is empty

local goals = {}          -- list of {x =, z =, player =}: places enemies may be
local cleared = {}        -- goal index -> true once seen empty

function intel.start()
    goals, cleared, state.home = {}, {}, nil
    local players = me:players()
    for index = 1, #players do
        local row = players[index]
        if row.start_x ~= nil then
            if row.player == me.player then
                state.home = util.pos(row.start_x, row.start_z)
            elseif row.allied ~= true and row.alive ~= false then
                local goal = util.pos(row.start_x, row.start_z)
                goal.player = row.player
                goals[#goals + 1] = goal
            end
        end
    end
    -- Random starts hide the others' positions: try every start but ours.
    if #goals == 0 and game.map ~= nil then
        local starts = game.map:starts() or {}
        for index = 1, #starts do
            local goal = util.pos(starts[index].x, starts[index].z)
            if state.home == nil or goal.x ~= state.home.x or goal.z ~= state.home.z then
                goals[#goals + 1] = goal
            end
        end
    end
end

function intel.onPlayerDefeated(player)
    for index = 1, #goals do
        if goals[index].player == player then cleared[index] = true end
    end
end

-- The nearest live enemy unit we can see, and its distance, or nil.
function intel.nearest_enemy(origin)
    local list, seen = {}, me.seen
    for index = 1, #seen do
        local unit = seen[index]
        if unit.alive == true and util.enemy(unit) then list[#list + 1] = unit end
    end
    return util.nearest(origin, list)
end

-- The nearest enemy start we have not yet seen empty, or nil.
function intel.nearest_goal(origin)
    local open = {}
    for index = 1, #goals do
        if not cleared[index] then open[#open + 1] = goals[index] end
    end
    return util.nearest(origin, open)
end

-- Where to send an attack from `origin`: a unit handle, a position, or nil.
-- TODO: weigh targets (factories, extractors, weak units) instead of distance.
function intel.target(origin)
    return intel.nearest_enemy(origin) or intel.nearest_goal(origin)
end

function intel.think()
    for index = 1, #goals do
        local goal = goals[index]
        if not cleared[index] and me:sees(goal.x, goal.z) then
            local enemy, distance = intel.nearest_enemy(goal)
            if enemy == nil or distance > CLEAR_RADIUS then cleared[index] = true end
        end
    end
end

function intel.report()
    local open = 0
    for index = 1, #goals do if not cleared[index] then open = open + 1 end end
    return { string.format("intel: %d of %d enemy starts open, %d units seen", open, #goals, #me.seen) }
end

return intel
