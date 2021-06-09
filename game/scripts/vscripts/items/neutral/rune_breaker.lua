LinkLuaModifier("modifier_item_rune_breaker_passive", "items/neutral/rune_breaker.lua", LUA_MODIFIER_MOTION_NONE)

item_rune_breaker = class(ItemBaseClass)

function item_rune_breaker:GetCastRange(location, target)
  return 400
end

function item_rune_breaker:GetIntrinsicModifierName()
  return "modifier_item_rune_breaker_passive"
end

function item_rune_breaker:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Don't do anything if target has Linken's effect
  if target:TriggerSpellAbsorb(self) then
    return
  end

  -- Basic Dispel
  local RemovePositiveBuffs = true
  local RemoveDebuffs = false
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false

  target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

  -- Particle
  --local particle_name = ""
  --local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, target)
	--ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
	--ParticleManager:ReleaseParticleIndex(particle)

  -- Sound
  --caster:EmitSound("")
end

---------------------------------------------------------------------------------------------------

modifier_item_rune_breaker_passive = class(ModifierBaseClass)

function modifier_item_rune_breaker_passive:IsHidden()
  return true
end
function modifier_item_rune_breaker_passive:IsDebuff()
  return false
end
function modifier_item_rune_breaker_passive:IsPurgable()
  return false
end

function modifier_item_rune_breaker_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.dmg = ability:GetSpecialValueFor("bonus_damage_during_duels")
  end

  if IsServer() then
    self:StartIntervalThink(0)
  end
end

function modifier_item_rune_breaker_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.dmg = ability:GetSpecialValueFor("bonus_damage_during_duels")
  end
end

function modifier_item_rune_breaker_passive:OnIntervalThink()
  if Duels:IsActive() then
    self:SetStackCount(1)
  else
    self:SetStackCount(2)
  end
end

function modifier_item_rune_breaker_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_item_rune_breaker_passive:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_rune_breaker_passive:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_rune_breaker_passive:GetModifierBaseDamageOutgoing_Percentage()
  if self:GetStackCount() == 1 then
    return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage_during_duels")
  end

  return 0
end
