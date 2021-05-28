LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_passive", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_passive_aura", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_passive_aura_effect", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_martyr_active", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_martyr_aura", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_martyrs_mail = class(ItemBaseClass)

function item_martyrs_mail:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_martyrs_mail:GetIntrinsicModifierNames()
  return {
    "modifier_item_martyrs_mail_passive",
    "modifier_item_martyrs_mail_passive_aura",
  }
end

function item_martyrs_mail:OnSpellStart()
	local hCaster = self:GetCaster()
	local martyr_duration = self:GetSpecialValueFor( "martyr_duration" )

	hCaster:EmitSound( "DOTA_Item.BladeMail.Activate" )
	hCaster:AddNewModifier( hCaster, self, "modifier_item_martyrs_mail_martyr_active", { duration = martyr_duration } )
end

function item_martyrs_mail:ProcsMagicStick()
  return false
end

item_martyrs_mail_2 = class(item_martyrs_mail)
item_martyrs_mail_3 = class(item_martyrs_mail)
item_martyrs_mail_4 = class(item_martyrs_mail)

--------------------------------------------------------------------------------

modifier_item_martyrs_mail_passive = class(ModifierBaseClass)

function modifier_item_martyrs_mail_passive:IsHidden()
	return true
end

function modifier_item_martyrs_mail_passive:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_martyrs_mail_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor( "bonus_damage" )
    self.bonus_armor = ability:GetSpecialValueFor( "bonus_armor" )
    self.bonus_intellect = ability:GetSpecialValueFor( "bonus_intellect" )
  end
end

modifier_item_martyrs_mail_passive.OnRefresh = modifier_item_martyrs_mail_passive.OnCreated

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

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_passive_aura = class(ModifierBaseClass)

function modifier_item_martyrs_mail_passive_aura:IsHidden()
  return true
end

function modifier_item_martyrs_mail_passive_aura:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_passive_aura:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_passive_aura:OnCreated()
  self.aura_radius = 1200
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
end

modifier_item_martyrs_mail_passive_aura.OnRefresh = modifier_item_martyrs_mail_passive_aura.OnCreated

function modifier_item_martyrs_mail_passive_aura:IsAura()
  return true
end

function modifier_item_martyrs_mail_passive_aura:GetModifierAura()
  return "modifier_item_martyrs_mail_passive_aura_effect"
end

function modifier_item_martyrs_mail_passive_aura:GetAuraRadius()
  return self.aura_radius
end

function modifier_item_martyrs_mail_passive_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_martyrs_mail_passive_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_martyr_active = class(ModifierBaseClass)

function modifier_item_martyrs_mail_martyr_active:IsHidden()
  return false
end

function modifier_item_martyrs_mail_martyr_active:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_martyr_active:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_martyr_active:IsAura()
  return true
end

function modifier_item_martyrs_mail_martyr_active:GetModifierAura()
  return "modifier_item_martyrs_mail_martyr_aura"
end

function modifier_item_martyrs_mail_martyr_active:GetAuraEntityReject( hEntity )
  return self:GetCaster() == hEntity
end

function modifier_item_martyrs_mail_martyr_active:GetAuraRadius()
  return self.martyr_heal_aoe or 900
end

function modifier_item_martyrs_mail_martyr_active:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_martyrs_mail_martyr_active:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_item_martyrs_mail_martyr_active:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
  return funcs
end

function modifier_item_martyrs_mail_martyr_active:OnCreated()
  local ability = self:GetAbility()
  local radius = 900
  if ability and not ability:IsNull() then
    radius = ability:GetSpecialValueFor("martyr_heal_aoe")
  end

  self.martyr_heal_aoe = radius
end

modifier_item_martyrs_mail_martyr_active.OnRefresh = modifier_item_martyrs_mail_martyr_active.OnCreated

function modifier_item_martyrs_mail_martyr_active:OnTakeDamage( kv )
	if IsServer() then
		local hCaster = self:GetParent()
    -- local shouldNotReflect = kv.attacker == hCaster or -- Prevent reflecting self-damage
    --   bit.band(kv.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION -- Prevent reflecting damage with no-reflect flag

    -- if shouldNotReflect then
    --   return
    -- end

		if kv.unit == hCaster then
			-- local damageTable = {
			-- 	victim = kv.attacker,
			-- 	attacker = hCaster,
			-- 	damage = kv.original_damage,
			-- 	damage_flag = bit.bor(kv.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS),
			-- 	damage_type = kv.damage_type
			-- }

			-- ApplyDamage( damageTable )
			-- EmitSoundOnClient( "DOTA_Item.BladeMail.Damage", kv.attacker:GetPlayerOwner() )

			local martyr_heal_aoe = self:GetAbility():GetSpecialValueFor( "martyr_heal_aoe" )
			local martyr_heal_percent = self:GetAbility():GetSpecialValueFor( "martyr_heal_percent" )

			local allies = FindUnitsInRadius( hCaster:GetTeamNumber(), hCaster:GetOrigin(), hCaster, martyr_heal_aoe, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false )
			if #allies > 1 then
				for _,ally in pairs(allies) do
					if ally ~= hCaster then
						ally:Heal( kv.original_damage * martyr_heal_percent / 100, hCaster )
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

function modifier_item_martyrs_mail_martyr_active:GetTexture()
  return "custom/martyrs_mail_4"
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_martyr_aura = class(ModifierBaseClass)

function modifier_item_martyrs_mail_martyr_aura:IsHidden()
  return false
end

function modifier_item_martyrs_mail_martyr_aura:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_martyr_aura:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_martyr_aura:GetEffectName()
	return "particles/world_shrine/radiant_shrine_active_ray.vpcf"
end

function modifier_item_martyrs_mail_martyr_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_martyrs_mail_martyr_aura:GetTexture()
  return "custom/martyrs_mail_4"
end

---------------------------------------------------------------------------------------------------

modifier_item_martyrs_mail_passive_aura_effect = class(ModifierBaseClass)

function modifier_item_martyrs_mail_passive_aura_effect:IsHidden()
  return false
end

function modifier_item_martyrs_mail_passive_aura_effect:IsDebuff()
  return false
end

function modifier_item_martyrs_mail_passive_aura_effect:IsPurgable()
  return false
end

function modifier_item_martyrs_mail_passive_aura_effect:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_item_martyrs_mail_passive_aura_effect:OnCreated()
  self.attack_speed = 100
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("aura_attack_speed")
  end
end

modifier_item_martyrs_mail_passive_aura_effect.OnRefresh = modifier_item_martyrs_mail_passive_aura_effect.OnCreated

function modifier_item_martyrs_mail_passive_aura_effect:CheckState()
  local state = {
    [MODIFIER_STATE_PASSIVES_DISABLED] = false,
    --[MODIFIER_STATE_FEARED] = false,
  }

  return state
end

function modifier_item_martyrs_mail_passive_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_martyrs_mail_passive_aura_effect:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("aura_attack_speed")
end

--function modifier_item_martyrs_mail_passive_aura_effect:GetEffectName()
	--return "particles/world_shrine/radiant_shrine_active_ray.vpcf"
--end

--function modifier_item_martyrs_mail_passive_aura_effect:GetEffectAttachType()
	--return PATTACH_ABSORIGIN_FOLLOW
--end

function modifier_item_martyrs_mail_passive_aura_effect:GetTexture()
  return "custom/martyrs_mail_4"
end
