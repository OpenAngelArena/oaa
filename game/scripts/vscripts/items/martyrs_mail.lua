LinkLuaModifier( "modifier_item_martyrs_mail_passive", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_martyrs_mail_martyr_active", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_martyrs_mail_martyr_aura", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_martyrs_mail = class({})

function item_martyrs_mail:GetIntrinsicModifierName()
	return "modifier_item_martyrs_mail_passive"
end

function item_martyrs_mail:OnSpellStart()
	local hCaster = self:GetCaster()
	local martyr_duration = self:GetSpecialValueFor( "martyr_duration" )

	EmitSoundOn( "DOTA_Item.BladeMail.Activate", hCaster )
	hCaster:AddNewModifier( hCaster, self, "modifier_item_martyrs_mail_martyr_active", { duration = martyr_duration } )
end

--------------------------------------------------------------------------------

item_martyrs_mail_2 = class({})

function item_martyrs_mail_2:GetIntrinsicModifierName()
	return "modifier_item_martyrs_mail_passive"
end

function item_martyrs_mail_2:OnSpellStart()
	local hCaster = self:GetCaster()
	local martyr_duration = self:GetSpecialValueFor( "martyr_duration" )

	EmitSoundOn( "DOTA_Item.BladeMail.Activate", hCaster )
	hCaster:AddNewModifier( hCaster, self, "modifier_item_martyrs_mail_martyr_active", { duration = martyr_duration } )
end

--------------------------------------------------------------------------------

modifier_item_martyrs_mail_passive = class({})

function modifier_item_martyrs_mail_passive:IsHidden()
	return true
end

function modifier_item_martyrs_mail_passive:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_passive:OnCreated()
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
	self.bonus_armor = self:GetAbility():GetSpecialValueFor( "bonus_armor" )
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor( "bonus_intellect" )
end

function modifier_item_martyrs_mail_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
	return funcs
end

function modifier_item_martyrs_mail_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end


function modifier_item_martyrs_mail_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_martyrs_mail_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

--------------------------------------------------------------------------------

modifier_item_martyrs_mail_martyr_active = class({})

function modifier_item_martyrs_mail_martyr_active:IsAura()
	return true
end

function modifier_item_martyrs_mail_martyr_active:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_martyr_active:GetModifierAura()
	return "modifier_item_martyrs_mail_martyr_aura"
end

function modifier_item_martyrs_mail_martyr_active:GetAuraEntityReject( hEntity )
	return self:GetCaster() == hEntity
end

function modifier_item_martyrs_mail_martyr_active:GetAuraRadius()
	return self.martyr_heal_aoe
end

function modifier_item_martyrs_mail_martyr_active:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_martyrs_mail_martyr_active:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_martyrs_mail_martyr_active:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end

function modifier_item_martyrs_mail_martyr_active:OnCreated()
	self.martyr_heal_aoe = self:GetAbility():GetSpecialValueFor( "martyr_heal_aoe" )
end

function modifier_item_martyrs_mail_martyr_active:OnTakeDamage( kv )
	if IsServer() then
		local hCaster = self:GetParent()

		if kv.unit == hCaster then
			local damageTable = {
				victim = kv.attacker,
				attacker = hCaster,
				damage = kv.damage,
				damage_type = kv.damage_type
			}

			ApplyDamage( damageTable )
			EmitSoundOn( "DOTA_Item.BladeMail.Damage", kv.attacker )

			local martyr_heal_aoe = self:GetAbility():GetSpecialValueFor( "martyr_heal_aoe" )
			local martyr_heal_percent = self:GetAbility():GetSpecialValueFor( "martyr_heal_percent" )

			local allies = FindUnitsInRadius( hCaster:GetTeamNumber(), hCaster:GetOrigin(), hCaster, martyr_heal_aoe, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
			if #allies > 1 then
				for _,ally in pairs(allies) do
					if ally ~= hCaster then
						ally:Heal( kv.damage * martyr_heal_percent / 100, hCaster )
					end
				end
			end
		end
	end
end

function modifier_item_martyrs_mail_martyr_active:GetEffectName()
	return "particles/items_fx/blademail.vpcf"
end

function modifier_item_martyrs_mail_martyr_active:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------

modifier_item_martyrs_mail_martyr_aura = class({})

function modifier_item_martyrs_mail_martyr_aura:GetEffectName()
	return "particles/world_shrine/radiant_shrine_active_ray.vpcf"
end

function modifier_item_martyrs_mail_martyr_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------
