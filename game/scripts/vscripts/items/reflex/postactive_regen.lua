LinkLuaModifier("modifier_item_postactive_regen", "items/reflex/postactive_regen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_regen_crystal_1 = class(ItemBaseClass)
item_regen_crystal_2 = item_regen_crystal_1
item_regen_crystal_3 = item_regen_crystal_1

function item_regen_crystal_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_regen_crystal_1:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, "modifier_item_postactive_regen", {duration = self:GetSpecialValueFor("duration")})
end

function item_regen_crystal_1:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------
modifier_item_postactive_regen = class(ModifierBaseClass)

function modifier_item_postactive_regen:IsHidden()
  return false
end

function modifier_item_postactive_regen:IsDebuff()
  return false
end

function modifier_item_postactive_regen:IsPurgable()
  return false
end

function modifier_item_postactive_regen:OnCreated()
  local parent = self:GetParent()
  if IsServer() then
    if self.nPreviewFX == nil then
      self.nPreviewFX = ParticleManager:CreateParticle("particles/items/regen_crystal/regen_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(self.nPreviewFX, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    end
  end
  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("active_hp_regen_amp")
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  self.bonus_hp_regen = max_mana*max_mana_to_hp_regen/100
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus()
  end
  self:StartIntervalThink(0.5)
end

function modifier_item_postactive_regen:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("active_hp_regen_amp")
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  self.bonus_hp_regen = max_mana*max_mana_to_hp_regen/100
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus()
  end
end

function modifier_item_postactive_regen:OnIntervalThink()
  local parent = self:GetParent()
  if not self.bonus_hp_regen then
    self:ForceRefresh()
    return
  end

  local ability = self:GetAbility()
  local max_mana_to_hp_regen = 3
  if ability and not ability:IsNull() then
    max_mana_to_hp_regen = ability:GetSpecialValueFor("max_mana_to_hp_regen")
  end
  local max_mana = parent:GetMaxMana()
  if self.bonus_hp_regen ~= max_mana*max_mana_to_hp_regen/100 then
    self:ForceRefresh()
  end
end

function modifier_item_postactive_regen:OnDestroy()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, false)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function modifier_item_postactive_regen:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_postactive_regen:GetModifierConstantHealthRegen()
  return self.bonus_hp_regen
end

function modifier_item_postactive_regen:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("active_hp_regen_amp")
end
