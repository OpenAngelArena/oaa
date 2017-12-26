LinkLuaModifier( "modifier_item_far_sight", "items/sight.lua", LUA_MODIFIER_MOTION_NONE )

item_far_sight = class(ItemBaseClass)

function item_far_sight:GetIntrinsicModifierName()
  return "modifier_item_far_sight"
end

function item_far_sight:OnSpellStart()

	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	if IsServer() then
		AddFOWViewer(caster:GetTeam(),target,self:GetSpecialValueFor("reveal_radius"),self:GetSpecialValueFor("reveal_duration"),false)
	end
	--particle effect at cast location
	 --if IsServer() then
	--	SpawnEntiy()
		--particle = ParticleManager:CreateParticle("particles/test_particle/dungeon_broodmother_debuff_explode_ring.vpcf", PATTACH_ABSORIGIN, caster)
	--end
end


modifier_item_far_sight = class(ModifierBaseClass)


function modifier_item_far_sight:IsHidden()
  return true
end
function modifier_item_far_sight:IsDebuff()
  return false
end
function modifier_item_far_sight:IsPurgable()
  return false
end


 function modifier_item_far_sight:DeclareFunctions()
    local funcs  = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
    }
  return funcs
end


function modifier_item_far_sight:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_far_sight:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_str")
end
function modifier_item_far_sight:GetModifierBonusStats_Agility()
  return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_far_sight:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_far_sight:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end