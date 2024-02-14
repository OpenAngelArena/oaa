LinkLuaModifier("modifier_item_regen_crystal_passive", "items/regen_crystal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_regen_crystal_active", "items/regen_crystal.lua", LUA_MODIFIER_MOTION_NONE)

item_regen_crystal_1 = class(ItemBaseClass)
item_regen_crystal_2 = item_regen_crystal_1
item_regen_crystal_3 = item_regen_crystal_1

function item_regen_crystal_1:GetIntrinsicModifierName()
  return "modifier_item_regen_crystal_passive"
end

function item_regen_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply buff
  caster:AddNewModifier(caster, self, "modifier_item_regen_crystal_active", {duration = self:GetSpecialValueFor("duration")})

  -- Sound
  caster:EmitSound("DOTA_Item.EssenceRing.Cast")
end

--------------------------------------------------------------------------

modifier_item_regen_crystal_passive = class(ModifierBaseClass)

function modifier_item_regen_crystal_passive:IsHidden()
  return true
end

function modifier_item_regen_crystal_passive:IsDebuff()
  return false
end

function modifier_item_regen_crystal_passive:IsPurgable()
  return false
end

function modifier_item_regen_crystal_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_regen_crystal_passive:OnCreated()
  self:OnRefresh()
  self:StartIntervalThink(0.3)
end

function modifier_item_regen_crystal_passive:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.hp = ability:GetSpecialValueFor("bonus_health")
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  self.bonus_hp_regen = max_mana*max_mana_to_hp_regen/100
  if IsServer() then
    if parent:IsHero() then
      parent:CalculateStatBonus(true)
    end
    -- Check only on the server
    if self:IsFirstItemInInventory() then
      self:SetStackCount(2)
    else
      self:SetStackCount(1)
    end
  end
end

function modifier_item_regen_crystal_passive:OnIntervalThink()
  if IsServer() then
    if self:IsFirstItemInInventory() then
      self:SetStackCount(2)
    else
      self:SetStackCount(1)
      return -- no need to continue on the server if not the first item
    end
  elseif self:GetStackCount() ~= 2 then
    return -- no need to continue on the client
  end

  -- Checking if self.bonus_hp_regen is initialized just in case
  if not self.bonus_hp_regen then
    self:OnRefresh()
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  if self.bonus_hp_regen ~= max_mana*max_mana_to_hp_regen/100 then
    self.bonus_hp_regen = max_mana*max_mana_to_hp_regen/100
    if IsServer() and parent:IsHero() then
      parent:CalculateStatBonus(true)
    end
  end
end

function modifier_item_regen_crystal_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
end

function modifier_item_regen_crystal_passive:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_regen_crystal_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_regen_crystal_passive:GetModifierConstantHealthRegen()
  if self:GetStackCount() == 2 then
    return self.bonus_hp_regen
  else
    return 0
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_regen_crystal_active = class(ModifierBaseClass)

function modifier_item_regen_crystal_active:IsHidden()
  return false
end

function modifier_item_regen_crystal_active:IsDebuff()
  return false
end

function modifier_item_regen_crystal_active:IsPurgable()
  return false
end

function modifier_item_regen_crystal_active:OnCreated()
  --local ability = self:GetAbility()
  --if ability and not ability:IsNull() then
    --self.hp_regen = ability:GetSpecialValueFor("active_hp_regen")
    --self.hp_regen_amp = ability:GetSpecialValueFor("active_hp_regen_amp")
  --end
  if IsServer() and self.particle == nil then
    local parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/items/regen_crystal/regen_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
  end

  self.heal_interval = 0.1

  if IsServer() then
    self:OnIntervalThink()
    self:StartIntervalThink(self.heal_interval)
  end
end

function modifier_item_regen_crystal_active:OnRefresh()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
  local parent = self:GetParent()
  self.particle = ParticleManager:CreateParticle("particles/items/regen_crystal/regen_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
  ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
end

function modifier_item_regen_crystal_active:OnIntervalThink()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  -- Calculate heal amount per second
  local max_hp = parent:GetMaxHealth()
  local max_hp_as_heal = ability:GetSpecialValueFor("active_max_hp_as_heal")
  local heal_per_second = max_hp * max_hp_as_heal / 100

  -- Heal amount per interval
  local heal_amount = heal_per_second * self.heal_interval

  parent:Heal(heal_amount, ability)
end

function modifier_item_regen_crystal_active:OnDestroy()
  if IsServer() then
    self:StartIntervalThink(-1)
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, false)
      ParticleManager:ReleaseParticleIndex(self.particle)
      self.particle = nil
    end
  end
end

--function modifier_item_regen_crystal_active:DeclareFunctions()
  --return {
    --MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
  --}
--end

--function modifier_item_regen_crystal_active:GetModifierConstantHealthRegen()
  --return self.hp_regen or self:GetAbility():GetSpecialValueFor("active_hp_regen")
--end

--function modifier_item_regen_crystal_active:GetModifierHPRegenAmplify_Percentage()
  --return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("active_hp_regen_amp")
--end

function modifier_item_regen_crystal_active:GetEffectName()
  return "particles/items5_fx/essence_ring.vpcf"
end

function modifier_item_regen_crystal_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_regen_crystal_active:GetTexture()
  return "custom/regen_crystal"
end
