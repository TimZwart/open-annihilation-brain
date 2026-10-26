---@meta
-- Editor-only type stubs for the OABrain Lua API (lua-language-server).
-- Not part of the package. Source: docs/brains/oabrain-standard.md,
-- sections 5 to 8. Fields not listed here may still exist.

---@alias OAPosition { x: integer|fixed, z: integer|fixed }
---@alias OATarget OAUnit|OAPosition
---@alias OADifficulty "easy"|"medium"|"hard"
---@alias OARefusal "dead"|"not_own"|"over_limit"|"not_seen"|"not_buildable"|"by_engine"

---@class fixed
---@operator add(fixed|number): fixed
---@operator sub(fixed|number): fixed
---@operator mul(fixed|number): fixed
---@operator div(fixed|number): fixed
---@operator unm: fixed
local fixed_value = {}
---@return integer
function fixed_value:raw() end
---@return number
function fixed_value:tonumber() end
---@return integer
function fixed_value:floor() end
---@return integer
function fixed_value:ceil() end
---@return integer
function fixed_value:round() end
---@return string
function fixed_value:text() end

---@class f32
local f32_value = {}
---@return number
function f32_value:tonumber() end
---@return integer
function f32_value:tofixed() end

---A unit type record. Keys are the unit's FBI fields in lower case
---(buildcostmetal, extractsmetal, energymake, canmove, builder, bmcode, ...).
---@class OAUnitRecord
---@field name string
---@field unitname string
---@field commander boolean?
---@field builder boolean?
---@field canmove boolean?
---@field canattack boolean?
---@field canfly boolean?
---@field bmcode integer?
---@field category string[]?
---@field [string] any
local record = {}
---@param key string
function record:get(key) end
---@param key string
---@return fixed
function record:fixed(key) end
---@return string[]
function record:keys() end
---@return integer
function record:index() end

---A handle to one unit. `id` and `slot` always read. Seen fields need
---sight (or full awareness); own fields read only our live units.
---@class OAUnit
---@field id integer
---@field slot integer
---@field alive boolean?
---@field owner integer?
---@field type_index integer?
---@field type_name string?
---@field type OAUnitRecord?
---@field x integer|fixed?
---@field y integer|fixed?
---@field z integer|fixed?
---@field position { x: fixed, y: fixed, z: fixed }?
---@field heading integer?
---@field health number?
---@field health_percent number?
---@field max_health number?
---@field build_remaining number?
---@field finished boolean?
---@field building boolean?
---@field armed boolean?
---@field mobile boolean?
---@field active boolean?
---@field cloaked boolean?
---@field squad integer?
---@field kills integer?
---@field orders { kind: any, target: any, x: any, y: any, z: any, parameter_1: any, parameter_2: any }[]?
local unit = {}
---@return any kind, any target, boolean idle
function unit:head_order() end
---@param position OAPosition
---@param weapon? 1|2|3
---@return boolean
function unit:reaches(position, weapon) end
---@param position OAPosition
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:move(position, queued) end
---@param position OAPosition
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:patrol(position, queued) end
---@param target OAUnit
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:attack(target, queued) end
---@param position OAPosition
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:attack_ground(position, queued) end
---@param position OAPosition
---@return boolean ok, OARefusal? reason
function unit:attack_point(position) end
---@param target OATarget
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:dgun(target, queued) end
---@param target OAUnit
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:guard(target, queued) end
---@param target OAUnit
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:repair(target, queued) end
---@param target OAUnit
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:help(target, queued) end
---@param target OATarget
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:reclaim(target, queued) end
---@param target OAUnit
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:capture(target, queued) end
---@param target OAUnit
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:load(target, queued) end
---@param position OAPosition
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:unload(position, queued) end
---@param type OAUnitRecord|string|integer
---@param position OAPosition
---@param facing? 0|1|2|3
---@param queued? boolean
---@return boolean ok, OARefusal? reason
function unit:build(type, position, facing, queued) end
---@param type OAUnitRecord|string|integer
---@param count? integer 1 to 1000
---@return boolean ok, OARefusal? reason
function unit:queue(type, count) end
---@param type OAUnitRecord|string|integer
---@param delta integer -1000 to 1000, not 0
---@return boolean ok, OARefusal? reason
function unit:requeue(type, delta) end
---@return boolean ok, OARefusal? reason
function unit:stop() end
---@param flag boolean
---@return boolean ok, OARefusal? reason
function unit:on(flag) end
---@param flag boolean
---@return boolean ok, OARefusal? reason
function unit:cloak(flag) end
---@return boolean ok, OARefusal? reason
function unit:self_destruct() end
---@param stance { move: "hold"|"manoeuvre"|"roam"?, fire: "hold"|"return"|"at_will"? }
---@return boolean ok, OARefusal? reason
function unit:stance(stance) end

---@class OAMap
---@field name string
---@field path string?
---@field width integer cells
---@field world_width integer
---@field world_height integer
---@field sea_level integer
---@field tide f32
---@field wind_min number
---@field wind_max number
---@field surface_metal number
local map = {}
---@return integer speed, integer direction
function map:wind() end
---@param cx? integer
---@param cz? integer
---@return integer?
function map:height(cx, cz) end
---@return integer? low, integer? high
function map:heights(cx, cz) end
---@return integer
function map:ground(x, z) end
---@return integer
function map:metal(cx, cz) end
---@return boolean
function map:metal_feature(cx, cz) end
---@return { cx: integer, cz: integer }[]
function map:metal_spots() end
---@return { cx: integer, cz: integer }[]?
function map:geo_spots() end
---@return { index: integer, x: integer, z: integer, cx: integer, cz: integer }[]?
function map:starts() end
---@return { name: string, handle: integer, footprint_x: integer, footprint_z: integer }[]
function map:classes() end
---@return 0|1|3
function map:passable(class, cx, cz) end
function map:anchor(class, position) end
---@param a OATarget
---@param b OATarget
---@return boolean?
function map:reachable(a, b, class) end
---@param a OATarget
---@param b OATarget
---@param options? { points: boolean? }
---@return { length: integer, cells: integer, points: OAPosition[]? }?
function map:route(a, b, class, options) end

---@class OAGame
---@field base any
---@field expansions string[]
---@field engine string
---@field mode "skirmish"|"campaign"|"network"
---@field starts "fixed"|"random"|nil
---@field difficulty OADifficulty
---@field in_match boolean
---@field mod { id: string, name: string, version: string, sides: any, hacks: any, limits: any }
---@field mutators { id: string, version: string, options: table }[]
---@field map OAMap?
---@field ai_profile table?
---@field build_list_cap integer
---@field units table? full awareness only
game = {}
---@param id string
---@return boolean
function game:has_expansion(id) end
---@param id string
---@return table?
function game:hack(id) end
---@param type OAUnitRecord|string|integer
---@return OAUnitRecord[]
function game.build_list(type) end
function game.ai_profiles() end
---@param text string
function game.parse_profile(text) end

---@class OAPlayerRow
---@field player integer
---@field name string
---@field side integer
---@field team integer
---@field allied boolean
---@field computer boolean
---@field alive boolean
---@field start integer?
---@field start_x integer?
---@field start_z integer?
---@field allies integer[]

---@class OAContact
---@field x any
---@field y any
---@field z any
---@field position any
---@field sonar boolean
---@field radar boolean
---@field current boolean

---@class OAMe
---@field player integer 0 to 9
---@field level string
---@field difficulty OADifficulty
---@field options table<string, any>
---@field name string
---@field side integer
---@field side_name string
---@field team integer
---@field energy f32
---@field metal f32
---@field energy_storage f32
---@field metal_storage f32
---@field energy_produced f32
---@field metal_produced f32
---@field energy_requested f32
---@field metal_requested f32
---@field energy_surplus number
---@field metal_surplus number
---@field tick integer
---@field full_awareness boolean
---@field seen OAUnit[]
---@field seen_tick integer
---@field radar OAContact[]
---@field radar_tick integer
me = {}
---@return boolean
function me:allied(player) end
---@return integer[]
function me:allies() end
---@return OAPlayerRow[]
function me:players() end
---@return OAUnit[]
function me:units() end
---@param fn fun(unit: OAUnit)
function me:each_unit(fn) end
---@return integer
function me:unit_count() end
function me:squad(n) end
function me:squad_size(n) end
function me:squad_member(n, i) end
---@return boolean
function me:assign(unit, squad) end
---@return boolean
function me:sees(x, z, y) end
---@return boolean
function me:sees_unit(u) end

brain = {}
---@param n integer
---@return integer 1 to n, from the brain's own seeded stream
function brain.random(n) end
---@param ticks integer
---@param fn fun()
---@return integer id
function brain.after(ticks, fn) end
---@param ticks integer
---@param fn fun()
---@return integer id
function brain.every(ticks, fn) end
---@param id integer
---@return boolean
function brain.cancel(id) end
---@param text string
---@param to? "all"|"allies"|"enemies"|integer
---@return boolean ok, string? reason
function brain.say(text, to) end
---@param a OATarget
---@param b OATarget
---@return integer|fixed?
function brain.distance(a, b) end
---@param a OATarget
---@param b OATarget
---@return integer?
function brain.direction(a, b) end
---@param type OAUnitRecord|string|integer
---@param cx integer
---@param cz integer
---@param facing? 0|1|2|3
---@param check? "site"|"yard"
---@return boolean?
function brain.site(type, cx, cz, facing, check) end
---@param type OAUnitRecord|string|integer
---@param near OAPosition
---@param radius integer world units
---@param facing? 0|1|2|3
---@return integer? cx, integer? cz, integer|fixed? x, integer|fixed? z
function brain.place(type, near, radius, facing) end
---@return integer? build_priority, integer? metal, integer? energy
function brain.strengths(type) end
---@param scope? "match"
---@return table<string, integer>
function brain.order_counts(scope) end
---@param distances integer[]
---@return integer[]
function brain.float_heap_order(distances) end

---@type OAUnitRecord[]
units = {}
weapons = {}
features = {}
geometry = {}
