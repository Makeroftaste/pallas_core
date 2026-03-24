local options = {
	Name = "Rogue (Combat)",

	Widgets = {
		{ type = "text", text = "=== General ===" },
		{ type = "slider", uid = "RogueEvisCP", text = "Eviscerate at CP", default = 3, min = 1, max = 5 },
	},
}

local function DoCombat()
	if Me:IsCastingOrChanneling() then
		return
	end

	local target = Combat.BestTarget
	if not target then
		return
	end

	if not Me:InMeleeRange(target) then
		return
	end

	if not Me:IsAutoAttacking() and Me:StartAttack(target) then
		return
	end

	if Spell:IsGCDActive() then
		return
	end

	local evis_cp = PallasSettings.RogueEvisCP or 3
	if Me.ComboPoints >= evis_cp and Spell.Eviscerate:CastEx(target) then
		return
	end

	if Spell.SinisterStrike:CastEx(target) then
		return
	end
end

local behaviors = {
	[BehaviorType.Combat] = DoCombat,
}

return { Options = options, Behaviors = behaviors }
