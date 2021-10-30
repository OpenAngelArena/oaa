LinkLuaModifier("modifier_item_blood_sword_passive", "items/neutral/blood_sword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_blood_sword_lifesteal", "items/neutral/blood_sword.lua", LUA_MODIFIER_MOTION_NONE)

item_blood_sword = class(ItemBaseClass)

function item_blood_sword:GetCastRange(location, target)
  return self:GetCaster():GetAttackRange()
end

function item_blood_sword:GetIntrinsicModifierName()
  return "modifier_item_blood_sword_passive"
end

function item_blood_sword:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Add a lifesteal buff before the instant attack
  caster:AddNewModifier(caster, self, "modifier_item_blood_sword_lifesteal", {})

  -- Instant attack
  caster:PerformAttack(target, true, true, true, false, false, false, true)

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/items3_fx/iron_talon_active.vpcf", PATTACH_ABSORIGIN, target)
  ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  -- Sound
  caster:EmitSound("DOTA_Item.IronTalon.Activate")
end

function item_blood_sword:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_blood_sword_passive = class(ModifierBaseClass)

function modifier_item_blood_sword_passive:IsHidden()
  return true
end
function modifier_item_blood_sword_passive:IsDebuff()
  return false
end
function modifier_item_blood_sword_passive:IsPurgable()
  return false
end

function modifier_item_blood_sword_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
    self.attack_range_melee = ability:GetSpecialValueFor("bonus_attack_range_melee")
  end
end

function modifier_item_blood_sword_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
    self.attack_range_melee = ability:GetSpecialValueFor("bonus_attack_range_melee")
  end
end

function modifier_item_blood_sword_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
  }
end

function modifier_item_blood_sword_passive:GetModifierPreAttack_BonusDamage()
  return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_blood_sword_passive:GetModifierAttackRangeBonus()
  if not self:GetParent():IsRangedAttacker() then
    return self.attack_range_melee or self:GetAbility():GetSpecialValueFor("bonus_attack_range_melee")
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_item_blood_sword_lifesteal = class(ModifierBaseClass)

function modifier_item_blood_sword_lifesteal:IsHidden()
  return true
end

function modifier_item_blood_sword_lifesteal:IsDebuff()
  return false
end

function modifier_item_blood_sword_lifesteal:IsPurgable()
  return false
end

function modifier_item_blood_sword_lifesteal:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_item_blood_sword_lifesteal:OnAttackLanded(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local attacker = event.attacker
  local damage = event.damage

  if attacker ~= parent or damage < 0 then
    return
  end

  if not attacker or attacker:IsNull() or not ability or ability:IsNull() then
    return
  end

  local parent_team = parent:GetTeamNumber()
  local target = event.unit

  local ufResult = UnitFilter(
    target,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    parent_team
  )

  local lifesteal_percent = ability:GetSpecialValueFor("active_lifesteal_percent")

  --print(tostring(ufResult)) -- It returns 15, Wtf?
  -- Maybe DOTA_UNIT_TARGET_TEAM_BOTH is bugging it out lmao

  if (ufResult == UF_SUCCESS or ufResult == UF_FAIL_DEAD) and lifesteal_percent > 0 and parent:IsAlive() then
    parent:Heal(damage * lifesteal_percent * 0.01, ability)

    local part = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(part, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(part)
  end

  self:Destroy()
end
