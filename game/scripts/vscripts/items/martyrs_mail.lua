LinkLuaModifier("modifier_item_martyrs_mail_passive", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_passive_aura_effect", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_martyr_active", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_martyrs_mail_martyr_aura", "items/martyrs_mail.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_martyrs_mail_1 = class(ItemBaseClass)

function item_martyrs_mail_1:GetIntrinsicModifierName()
  return "modifier_item_martyrs_mail_passive"
end

function item_martyrs_mail_1:OnSpellStart()
	local hCaster = self:GetCaster()
	local martyr_duration = self:GetSpecialValueFor( "martyr_duration" )

	hCaster:EmitSound( "DOTA_Item.BladeMail.Activate" )
	hCaster:AddNewModifier( hCaster, self, "modifier_item_martyrs_mail_martyr_active", { duration = martyr_duration } )
end

--------------------------------------------------------------------------------

modifier_item_martyrs_mail_passive = class(ModifierBaseClass)

function modifier_item_martyrs_mail_passive:IsHidden()
	return true
end

function modifier_item_martyrs_mail_passive:IsDebuff()
  return false
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
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
end

modifier_item_martyrs_mail_passive.OnRefresh = modifier_item_martyrs_mail_passive.OnCreated

function modifier_item_martyrs_mail_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
  }
end

function modifier_item_martyrs_mail_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_martyrs_mail_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_martyrs_mail_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_martyrs_mail_passive:IsAura()
  return true
end

function modifier_item_martyrs_mail_passive:GetModifierAura()
  return "modifier_item_martyrs_mail_passive_aura_effect"
end

function modifier_item_martyrs_mail_passive:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_martyrs_mail_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_martyrs_mail_passive:GetAuraSearchType()
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
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
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

if IsServer() then
  function modifier_item_martyrs_mail_martyr_active:OnTakeDamage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Don't continue if attacker doesn't exist or if attacker is about to be deleted
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Trigger only for this modifier
    if damaged_unit ~= parent then
      return
    end

    -- Damage before reductions
    local damage = event.original_damage

    -- If damage is negative or 0, don't continue
    if damage <= 0 then
      return
    end

    -- Don't continue if ability doesn't exist
    if not ability or ability:IsNull() then
      return
    end

    local martyr_heal_aoe = ability:GetSpecialValueFor("martyr_heal_aoe")
    local martyr_heal_percent = ability:GetSpecialValueFor("martyr_heal_percent")

    local allies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      parent,
      martyr_heal_aoe,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )
    for _, ally in pairs(allies) do
      if ally and not ally:IsNull() and ally ~= parent then
        ally:Heal(damage * martyr_heal_percent / 100, ability)
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
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = false,
    --[MODIFIER_STATE_FEARED] = false,
  }
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
