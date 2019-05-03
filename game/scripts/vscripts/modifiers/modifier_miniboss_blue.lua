require("modifiers/modifier_miniboss_base")
modifier_miniboss_blue = class(modifier_miniboss_base)

function modifier_miniboss_blue:GetTexture()
	return "ancient_apparition_chilling_touch"
end

function modifier_miniboss_blue:GetModifierMoveSpeedBonus_Percentage()
	return 10
end

function modifier_miniboss_blue:GetModifierPercentageCooldown()
	return 20
end

function modifier_miniboss_blue:OnTakeDamage( event )
	local unit = event.unit
	local unitname = unit:GetName()
	if event.attacker==self:GetParent() and unit:FindAbilityByName("boss_regen") then -- on dealing damage to unit
		unit:AddNewModifier(self:GetParent(), nil, "modifier_miniboss_blue_amplifier", { duration = 2.05 })
	end
end

LinkLuaModifier( "modifier_miniboss_blue_amplifier", "modifiers/modifier_miniboss_blue.lua", LUA_MODIFIER_MOTION_NONE )
------------------------------------------------------------------------
modifier_miniboss_blue_amplifier = class(ModifierBaseClass)
------------------------------------------------------------------------
function modifier_miniboss_blue_amplifier:IsHidden() return false end
function modifier_miniboss_blue_amplifier:IsDebuff() return true  end
function modifier_miniboss_blue_amplifier:GetTexture() return "ancient_apparition_chilling_touch" end
