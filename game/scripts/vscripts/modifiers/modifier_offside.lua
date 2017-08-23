LinkLuaModifier('modifier_onside_buff', 'modifiers/modifier_onside_buff.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_offside_buff', 'modifiers/modifier_onside_buff.lua', LUA_MODIFIER_MOTION_NONE)

modifier_offside = class(ModifierBaseClass)
modifier_onside_buff = class(ModifierBaseClass)
modifier_offside_buff = class(ModifierBaseClass)

function modifier_offside:OnCreated()
  self:StartIntervalThink(1)
end
--------------------------------------------------------------------
--aura
function modifier_offside:IsAura()
  return true
end

function modifier_offside:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_offside:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_offside:GetAuraRadius()
  return 2500
end

function modifier_offside:GetModifierAura()
  return "modifier_onside_buff"
end
--------------------------------------------------------------------
--% health damage
function modifier_offside:GetTexture()
	return "custom/modifier_offside"
end

function modifier_offside:IsDebuff()
	return true
end

function modifier_offside:OnIntervalThink()
		i = GetAttacker(i)
		DebugPrint("GetAttacker(i)")
	playerHero = self:GetCaster()
	h = self:GetParent():GetMaxHealth()
	local stackCount = self:GetElapsedTime()
	attacker = self:GetCaster():HasModifier("modifier_offside_buff") or nil
	
	if self:GetCaster():HasModifier("modifier_offside_buff") then
		attacker = self:GetCaster():HasModifier("modifier_offside_buff")
	end

	local damageTable = {
	victim = self:GetParent(),
	attacker = attacker or playerHero,
	damage = (h * ((0.02 * (stackCount-10)^2)/100)),
	damage_type = DAMAGE_TYPE_PURE,
	}

	if stackCount >= 10 then
		return ApplyDamage(damageTable)
	end
--
	local particleTable = {
    	[1]  = "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_spiral_b.vpcf",
    	[10] = "particles/items2_fx/mekanism.vpcf",
    	[13] = "particles/units/heroes/hero_phantom_lancer/phantom_lancer_doppleganger_illlmove.vpcf",
	    [16] = "particles/items2_fx/mekanism.vpcf",
    	[19]= "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
    	[22]= "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_guided_missle_explosion_smoke.vpcf",
    	[25]= "particles/items2_fx/mekanism.vpcf",
    	[28]= "particles/econ/items/tinker/boots_of_travel/teleport_end_bots_flare.vpcf",
  	}

  	if particleTable[stackCount] ~= nil and self:GetCaster() then
    	local part = ParticleManager:CreateParticle(particleTable[stackCount], PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
    	ParticleManager:SetParticleControlEnt(part, 1, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, "attach_origin", self:GetCaster():GetAbsOrigin(), true)
    	ParticleManager:ReleaseParticleIndex(part)
  	end
end

