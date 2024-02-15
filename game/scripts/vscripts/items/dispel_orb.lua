LinkLuaModifier("modifier_item_dispel_orb_passive", "items/dispel_orb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dispel_orb_active", "items/dispel_orb.lua", LUA_MODIFIER_MOTION_NONE)

item_dispel_orb_1 = class(ItemBaseClass)
item_dispel_orb_2 = item_dispel_orb_1
item_dispel_orb_3 = item_dispel_orb_1

function item_dispel_orb_1:GetIntrinsicModifierName()
  return "modifier_item_dispel_orb_passive"
end

function item_dispel_orb_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply modifier that dispels OnIntervalThink
  caster:AddNewModifier(caster, self, "modifier_item_dispel_orb_active", { duration = self:GetSpecialValueFor("duration") })
end

---------------------------------------------------------------------------------------------------

modifier_item_dispel_orb_passive = class(ModifierBaseClass)

function modifier_item_dispel_orb_passive:IsHidden()
  return true
end

function modifier_item_dispel_orb_passive:IsDebuff()
  return false
end

function modifier_item_dispel_orb_passive:IsPurgable()
  return false
end

function modifier_item_dispel_orb_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_dispel_orb_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.3)
  end
end

function modifier_item_dispel_orb_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agi = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.magic_resist = ability:GetSpecialValueFor("magic_resist_while_silenced")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_dispel_orb_passive:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_dispel_orb_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_item_dispel_orb_passive:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_dispel_orb_passive:GetModifierBonusStats_Agility()
  return self.bonus_agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_dispel_orb_passive:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_dispel_orb_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_dispel_orb_passive:GetModifierMagicalResistanceBonus()
  if self:GetStackCount() ~= 2 then
    return 0
  end

  local parent = self:GetParent()
  if parent:IsSilenced() or parent:IsHexed() then
    return self.magic_resist
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_item_dispel_orb_active = class(ModifierBaseClass)

function modifier_item_dispel_orb_active:IsHidden()
  return false
end

function modifier_item_dispel_orb_active:IsDebuff()
  return false
end

function modifier_item_dispel_orb_active:IsPurgable()
  return false
end

function modifier_item_dispel_orb_active:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    if self.particle == nil then
      self.particle = ParticleManager:CreateParticle("particles/items/dispel_orb/dispel_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    end

    local interval = self:GetAbility():GetSpecialValueFor("tick_interval")
    self:OnIntervalThink()
    self:StartIntervalThink(interval)
  end
end

function modifier_item_dispel_orb_active:OnRefresh()
  if IsServer() then
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, true)
      ParticleManager:ReleaseParticleIndex(self.particle)
    end

    local parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/items/dispel_orb/dispel_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
  end
end

function modifier_item_dispel_orb_active:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_item_dispel_orb_active:OnIntervalThink()
  local parent = self:GetParent()

  local modifiers = parent:FindAllModifiers()
  local modifierCount = #modifiers

  parent:Purge(false, true, false, false, false)

  modifiers = parent:FindAllModifiers()
  local modifierCountAfter = #modifiers

  if modifierCountAfter < modifierCount then
    local burstEffect = ParticleManager:CreateParticle( "particles/items/dispel_orb/dispel_steam.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt( burstEffect, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true )
    ParticleManager:ReleaseParticleIndex( burstEffect )
  end
end

function modifier_item_dispel_orb_active:GetTexture()
  return "custom/dispel_orb_3"
end
