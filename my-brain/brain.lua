-- Entry script. It must return one table of hooks; a missing hook is
-- skipped, so delete the ones you do not need.
--
-- Globals: `game` (the match, read-only), `me` (this seat), `brain`
-- (random, timers, chat, sites), and `units`, `weapons`, `features`.
-- Orders given in a hook take effect on the next tick.
--
-- Do not call this table `brain`: that would shadow the global `brain`.
local firstStep = true
local commander = nil
local futureIdleEnergyBalance = 25
local futureIdleMetalBalance = 1
local amountOfVehiclePlants = 0
local ownPlayerInfo = nil
local targetPlayerInfo = nil
local energyFactor = 1
local wavefactor = 1

local lastcellx = 0
local lastcellz = 0
local xbuilddirection = 1
local zbuilddirection = 1
local tanks = 0

local metal_spots = nil

local decisionalreadyplannedforcommander = false

local function debugPrint(text)
    brain.say(text)
    print(text)
end

local function square ( x )
    return x * x
end

local worldpostocellpos = function (x, z)
    return {x=x:floor()//16, z=z:floor()//16}
end

local function cellpostoworldposwhenplacingbuilding (cx, cz, building_name)
    local building_record = units[building_name]
    return {x=cx*16+building_record.footprintx*8, z=cz*16+building_record.footprintz*8}
end

local function buildMetalExtractorWith(builder)
    local buildlist = game.build_list(builder.type)
    local building_name = nil
    debugPrint("side_name is " .. me.side_name)
    if(me.side_name == "ARM") then
        building_name = "ARMMEX"
    end
    if (me.side_name == "CORE") then
        building_name = "CORMEX"
    end
    local buildercellpos = worldpostocellpos(builder.position.x, builder.position.z)
    table.sort(metal_spots, function (a, b) return square(a.cx - buildercellpos.x) + square(a.cz - buildercellpos.z) < square(b.cx - buildercellpos.x) + square(b.cz - buildercellpos.z) end)
    local the_spot = nil
    for _, spot in ipairs(metal_spots) do
        if(brain.site(building_name, spot.cx, spot.cz)) then
            the_spot = spot
            break
        end
    end
    if the_spot ~= nil then
        local _, _, xplaced, zplaced = brain.place(building_name, cellpostoworldposwhenplacingbuilding(the_spot.cx, the_spot.cz, building_name), 200)
        return builder:build(building_name, {x=xplaced, z=zplaced})
    else
        debugPrint("Could not find a place to build " .. building_name)
        return false
    end
end


local function buildThingWithCom(armthingname, corethingname)
    local buildlist = game.build_list(commander.type)
    local building_name = nil
    if(commander.type.unitname == "ARMCOM") then
        building_name = armthingname
    end
    if (commander.type.unitname == "CORCOM") then
        building_name = corethingname
    end
    local building_record = nil
    for _, buildable in ipairs(buildlist) do
        if(buildable.unitname == building_name) then
            building_record = buildable
        end
    end
    if (building_record ~= nil) then
        local loopcounter = 0
        local placeInCellsX = nil
        local placeInCellsZ = nil
        repeat
            if loopcounter > 100 then
                debugPrint("Could not find a place to build " .. building_name)
                return false
            end
            placeInCellsX = lastcellx+(ownPlayerInfo.start_x:floor() - 10)//16 
            placeInCellsZ = lastcellz+(ownPlayerInfo.start_z:floor() - 10)//16
            if xbuilddirection > 0 and game.map.width - placeInCellsX < 10 then
                xbuilddirection = -1
            end
            if xbuilddirection < 0 and placeInCellsX < 10 then
                xbuilddirection = 1
            end
            if zbuilddirection > 0 and game.map:height() - placeInCellsZ < 10 then
                zbuilddirection = -1
            end
            if zbuilddirection < 0 and placeInCellsZ < 10 then
                zbuilddirection = 1
            end
            if loopcounter % 2 == 0 then
                lastcellx = lastcellx + xbuilddirection * 4 -- allow some spacing, not guaranteed because we have to use .place to get the final build place
            else
                lastcellz = lastcellz + zbuilddirection * 4 
            end
            loopcounter = loopcounter + 1
            local resultFromSite = brain.site(building_record, placeInCellsX, placeInCellsZ)
        until resultFromSite
        local _, _, xplaced, zplaced = brain.place(building_record, cellpostoworldposwhenplacingbuilding(placeInCellsX, placeInCellsZ, building_name), 200)
        return commander:build(building_record, {x=xplaced, z=zplaced})
    else
        return false
    end
end

local function buildSolar()
    if buildThingWithCom("ARMSOLAR", "CORSOLAR") then
        futureIdleEnergyBalance = futureIdleEnergyBalance + 20 -- this is the energy production of a solar
    end
end

local function buildMetalMaker()
    local retval = buildThingWithCom("ARMMAKR", "CORMAKR")
    if retval then
        futureIdleEnergyBalance = futureIdleEnergyBalance - 60 -- this is the energy cost of a metal maker
        futureIdleMetalBalance = futureIdleMetalBalance + 1 -- this is the metal production of a metal maker
    end
    return retval
end

local function buildThingWithVehiclePlant(vehicle_plant, armthingname, corethingname)
    local buildlist = game.build_list(vehicle_plant.type)
    local unit_name = nil
    if(vehicle_plant.type.unitname == "ARMVP") then
        unit_name = armthingname
    end
    if (vehicle_plant.type.unitname == "CORVP") then
        unit_name = corethingname
    end
    local unit_record = nil
    for _, buildable in ipairs(buildlist) do
        if(buildable.unitname == unit_name) then
            unit_record = buildable
        end
    end
    vehicle_plant:queue(unit_record)
end

local function buildVehiclePlant()
    if buildThingWithCom("ARMVP", "CORVP") then
        amountOfVehiclePlants = amountOfVehiclePlants + 1
    end
end

local function buildTank(vehicle_plant)
    buildThingWithVehiclePlant(vehicle_plant,"ARMFLASH", "CORGATOR") 
end

local function step()
    if firstStep then
        debugPrint("Hello world!")
        firstStep = false
        if commander == nil then 
            commander = me:units()[1] -- outside of campaign scenarios and odd mods / mutators commander is going to be the only unit at the start. we assume death commander is game ends setting for now -- we also assume a two player game because otherwise a commander could die and a new unit of ours could occupy its place in the 'slots' list
        end
        for _, playerInfo in ipairs(me:players()) do
            if playerInfo.player == me.player then
                ownPlayerInfo = playerInfo
            else
                if not playerInfo.allied and playerInfo.alive then 
                    targetPlayerInfo = playerInfo
                end
            end
        end
        metal_spots = game.map:metal_spots()
        if metal_spots == nil then
            debugPrint("No metal spots found on map, this is weird. Likely a bug.")
        end
        buildSolar()
    end
end

local function onComIdleAndEnergyBalanceUpdated()
    if not commander.alive then
        return -- we don't want to build anything before the first step has run, because we need to know the target player info and metal spots
    end
    decisionalreadyplannedforcommander = false
    local energydifference = me.energy_produced:tonumber() - me.energy_requested:tonumber() -- on easy the amount of energy produced is two times lower, for example so we need to ask the game for it.
    local metaldifference = me.metal_produced:tonumber() - me.metal_requested:tonumber()
    if metaldifference > 5 and amountOfVehiclePlants == 0 then
        buildVehiclePlant()
        energyFactor = 1.1
    elseif metaldifference > 5 * ( 1 + amountOfVehiclePlants) and energydifference > 10 then
        buildVehiclePlant()
    else
        local started_building_metal_producer = false
        if energydifference > 4 * energyFactor then
            local mex_build_started = buildMetalExtractorWith(commander)
            started_building_metal_producer = mex_build_started
            if not mex_build_started and energydifference > 60 * energyFactor then -- at this point this is the actual engergy balance because the builder is idle and we waited 60 ticks for the energy balance to update. if we are still above 60 then we can build a metal maker
                debugPrint("building maker bc energydifference is " .. energydifference)
                started_building_metal_producer = buildMetalMaker()
            end
        end
        if not started_building_metal_producer then
            debugPrint("building solar bc energydifference is " .. energydifference)
            buildSolar()
        end
    end
end

local function onVehiclePlantIdleAndEnergyBalanceUpdated(vehicle_plant)
    if(vehicle_plant.alive == false) then
        return
    end
    local energydifference = me.energy_produced:tonumber() - me.energy_requested:tonumber() -- on easy the amount of energy produced is two times lower, for example so we need to ask the game for it.
    local metaldifference = me.metal_produced:tonumber() - me.metal_requested:tonumber()
    if metaldifference > 5 and energydifference > 10 then
        buildTank(vehicle_plant)
    else
        debugPrint("not building tank bc energydifference is " .. energydifference .. " and metaldifference is " .. metaldifference)
        brain.after(300, function() onVehiclePlantIdleAndEnergyBalanceUpdated(vehicle_plant) end) -- wait a second to see if the energy balance changes before we build something
    end
end

local stepfunctionRunning = false
local hooks = {}


-- Before the first tick. Return true, or a string the player sees as the
-- reason this brain does not fit the game.
function hooks.fits(game)
    return true
end

-- Before the first tick, and again after a saved game loads. `saved` is
-- what save() returned, or nil.
function hooks.start(game, me, saved)
    -- these guards are there for if start is called more than once other than from a saved game. conversations with llms insist this may happen
    if not stepfunctionRunning then
        stepfunctionRunning = true
        brain.every(30, step)
    end
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
    if not unit.alive then
        return
    end
    if unit.type.unitname == "ARMVP" or unit.type.unitname == "CORVP" then
        brain.after(60, function() onVehiclePlantIdleAndEnergyBalanceUpdated(unit) end) -- wait a second to see if the energy balance changes before we build something
    end
    if builder.type.unitname == "ARMVP" or builder.type.unitname == "CORVP" then
        brain.after(60, function() onVehiclePlantIdleAndEnergyBalanceUpdated(builder) end) -- wait a second to see if the energy balance changes before we build something
    end
    if unit.type.unitname == "ARMFLASH" or unit.type.unitname == "CORGATOR" then
        tanks = tanks + 1
        if tanks > 10 * wavefactor then
            wavefactor = wavefactor * 1.3
            -- attack with tanks
            for _, tank in ipairs(me:units()) do
                if (tank.type.unitname == "ARMFLASH" or tank.type.unitname == "CORGATOR") and tank.finished then
                    local targetx = nil
                    local targetz = nil
                    if targetPlayerInfo.start_x == nil then -- this can be made more intelligent, this is if there are random start positions
                        for _, otherunit in ipairs(me.seen) do
                            if otherunit.owner == targetPlayerInfo.player then
                                targetx = otherunit.position.x
                                targetz = otherunit.position.z
                                break
                            end
                        end
                        if targetx == nil then
                            debugPrint("could not find a target for tanks, attacking the edge of the map")
                            local farthestdistance = 0
                            local farthest_starting_point = {x=ownPlayerInfo.start_x, z=ownPlayerInfo.start_z}
                            local startx = ownPlayerInfo.start_x
                            local startz = ownPlayerInfo.start_z
                            for _, start in ipairs(game.map:starts()) do
                                local distance = square((startx - start.x)) + square((startz - start.z))
                                if distance:tonumber() > farthestdistance then
                                    farthestdistance = distance
                                    farthest_starting_point = {x=start.x, z=start.z}
                                end
                            end
                            targetx = farthest_starting_point.x
                            targetz = farthest_starting_point.z
                        end
                    else
                        targetx = targetPlayerInfo.start_x
                        targetz = targetPlayerInfo.start_z
                    end
                    local x = targetx + math.random(-100, 100)
                    local z = targetz + math.random(-100, 100)
                    tank:move({x=x, z=z})
                end
            end
        end
    end
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
    if not unit.alive then
        return
    end
    if unit == commander and not decisionalreadyplannedforcommander then
        decisionalreadyplannedforcommander = true
        brain.after(60, onComIdleAndEnergyBalanceUpdated) -- wait a second to see if the energy balance changes before we build something
    end
    -- vehicle_plants do not become idle
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
    if player == targetPlayerInfo.player then
        debugPrint("Target player defeated, selecting new target")
        for _, playerInfo in ipairs(me:players()) do
            if playerInfo ~= targetPlayerInfo and playerInfo.alive and not playerInfo.allied then
                targetPlayerInfo = playerInfo
                break
            end
        end
    end
end

-- to is "all", "allies", "enemies" or "me".
function hooks.onChat(from, text, to)
end

-- The end of every turn. 30 ticks is one second.
function hooks.onTick(tick)
end

return hooks
