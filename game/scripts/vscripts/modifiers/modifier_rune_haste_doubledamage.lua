modifier_rune_haste_doubledamage = modifier_rune_haste_doubledamage or class({})

function modifier_rune_haste_doubledamage
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.bonus_damage_pct = 100
end

function modifier_rune_haste_doubledamage:GetBaseDamageOutgoing_Percentage
	return self.bonus_damage_pct
	end

function modifier_rune_haste_doubledamage:GetModifierMovespeed_Absolute()
	return 550
	end

function modifier_rune_haste_doubledamage:GetTexture()
	return "rune_haste"
	end

function modifier_rune_haste_doubledamage:GetEffectName()
	return "particles/generic_gameplay/rune_haste.vpcf"
	end