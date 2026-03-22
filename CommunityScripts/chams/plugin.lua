local settings = require("settings")

local Plugin = {}
Plugin.name = "Chams"
Plugin.description = "Highlights nearby entities with outline glow."
Plugin.author = "Community"

local DEFAULTS = {
    enabled = true,
    show_hostile = true,
    show_friendly = false,
    show_neutral = false,
    show_players = false,
    show_rares = true,
    show_quest = true,
    max_range = 40,
    max_highlights = 5,
}

local cfg = {}

function Plugin.onEnable()
    cfg = settings.load("chams", DEFAULTS)
end

function Plugin.onDisable()
    for i = 0, 4 do
        game.outline_clear(i)
    end
    settings.save("chams", cfg)
end

local function dist_sq(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function classify_entity(entity, quest_creatures)
    local u = entity.unit
    if not u or u.is_dead then return nil end

    if u.is_player then return "players" end

    local cls = u.classification
    if cls == "rare" or cls == "rareelite" then return "rares" end

    if quest_creatures and entity.entry_id and quest_creatures[entity.entry_id] then
        return "quest"
    end

    local reaction = game.unit_reaction(entity.obj_ptr)
    if not reaction then return nil end

    if reaction <= 3 then return "hostile" end
    if reaction == 4 then return "neutral" end
    if reaction >= 5 then return "friendly" end

    return nil
end

local TYPE_SETTINGS = {
    hostile  = "show_hostile",
    neutral  = "show_neutral",
    friendly = "show_friendly",
    players  = "show_players",
    rares    = "show_rares",
    quest    = "show_quest",
}

function Plugin.onTick()
    if not cfg.enabled then
        for i = 0, 4 do game.outline_clear(i) end
        return
    end

    local player = game.local_player()
    if not player or not player.position then
        return
    end

    local pos = player.position
    local max_dist_sq = cfg.max_range * cfg.max_range

    local quest_creatures = nil
    if cfg.show_quest then
        local qt = game.quest_targets()
        if qt then quest_creatures = qt.creatures end
    end

    local candidates = {}
    for _, entity in ipairs(game.objects("Unit")) do
        if entity.position then
            local d2 = dist_sq(pos, entity.position)
            if d2 <= max_dist_sq then
                local etype = classify_entity(entity, quest_creatures)
                if etype and cfg[TYPE_SETTINGS[etype]] then
                    candidates[#candidates + 1] = { obj_ptr = entity.obj_ptr, dist2 = d2 }
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.dist2 < b.dist2 end)

    local n = math.min(#candidates, cfg.max_highlights)
    for i = 1, n do
        local slot = 5 - i
        game.outline_write(candidates[i].obj_ptr, slot)
    end

    local lowest_used = 5 - n
    for slot = lowest_used - 1, 0, -1 do
        game.outline_clear(slot)
    end
end

function Plugin.onDraw()
end

return Plugin
