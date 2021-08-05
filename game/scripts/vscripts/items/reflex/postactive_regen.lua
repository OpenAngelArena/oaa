LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_regen_crystal_stacking_stats", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_regen_crystal_non_stacking_stats", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_regen_crystal_active", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE)

item_regen_crystal_1 = class(ItemBaseClass)
item_regen_crystal_2 = item_regen_crystal_1
item_regen_crystal_3 = item_regen_crystal_1

function item_regen_crystal_1:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_regen_crystal_1:GetIntrinsicModifierNames()
  return {
    "modifier_item_regen_crystal_stacking_stats",
    "modifier_item_regen_crystal_non_stacking_stats"
  }
end

function item_regen_crystal_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply buff
  caster:AddNewModifier(caster, self, "modifier_item_regen_crystal_active", {duration = self:GetSpecialValueFor("duration")})

  -- Sound
  caster:EmitSound("DOTA_Item.EssenceRing.Cast")
end

function item_regen_crystal_1:ProcsMagicStick()
  return false
end

--------------------------------------------------------------------------
-- Parts of Regen Crystal that should stack with other items

modifier_item_regen_crystal_stacking_stats = class(ModifierBaseClass)

function modifier_item_regen_crystal_stacking_stats:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_regen_crystal_stacking_stats:IsHidden()
  return true
end
function modifier_item_regen_crystal_stacking_stats:IsDebuff()
  return false
end
function modifier_item_regen_crystal_stacking_stats:IsPurgable()
  return false
end

function modifier_item_regen_crystal_stacking_stats:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.hp = ability:GetSpecialValueFor("bonus_health")
  end
end

modifier_item_regen_crystal_stacking_stats.OnRefresh = modifier_item_regen_crystal_stacking_stats.OnCreated

function modifier_item_regen_crystal_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
  }
end

function modifier_item_regen_crystal_stacking_stats:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_regen_crystal_stacking_stats:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

---------------------------------------------------------------------------------------------------
-- Parts of Regen Crystal that should NOT stack with other Regen Crystals

modifier_item_regen_crystal_non_stacking_stats = class(ModifierBaseClass)

function modifier_item_regen_crystal_non_stacking_stats:IsHidden()
  return true
end

function modifier_item_regen_crystal_non_stacking_stats:IsDebuff()
  return false
end

function modifier_item_regen_crystal_non_stacking_stats:IsPurgable()
  return false
end

function modifier_item_regen_crystal_non_stacking_stats:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  self.bonus_hp_regen = max_mana*max_mana_to_hp_regen/100
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
  self:StartIntervalThink(0.5)
end

function modifier_item_regen_crystal_non_stacking_stats:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  self.bonus_hp_regen = max_mana*max_mana_to_hp_regen/100
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_item_regen_crystal_non_stacking_stats:OnIntervalThink()
  local parent = self:GetParent()
  if not self.bonus_hp_regen then
    self:OnRefresh()
    return
  end

  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  if self.bonus_hp_regen ~= max_mana*max_mana_to_hp_regen/100 then
    self:OnRefresh()
  end
end

function modifier_item_regen_crystal_non_stacking_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
end

function modifier_item_regen_crystal_non_stacking_stats:GetModifierConstantHealthRegen()
  return self.bonus_hp_regen
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
  local parent = self:GetParent()
  if IsServer() then
    if self.nPreviewFX == nil then
      self.nPreviewFX = ParticleManager:CreateParticle("particles/items/regen_crystal/regen_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(self.nPreviewFX, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    end
  end
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("active_hp_regen")
    self.hp_regen_amp = ability:GetSpecialValueFor("active_hp_regen_amp")
  end
end

function modifier_item_regen_crystal_active:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("active_hp_regen")
    self.hp_regen_amp = ability:GetSpecialValueFor("active_hp_regen_amp")
  end
end

function modifier_item_regen_crystal_active:OnDestroy()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function modifier_item_regen_crystal_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_regen_crystal_active:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("active_hp_regen")
end

function modifier_item_regen_crystal_active:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("active_hp_regen_amp")
end

function modifier_item_regen_crystal_active:GetEffectName()
  return "particles/items5_fx/essence_ring.vpcf"
end

function modifier_item_regen_crystal_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_regen_crystal_active:GetTexture()
  return "custom/regen_crystal_1"
end
