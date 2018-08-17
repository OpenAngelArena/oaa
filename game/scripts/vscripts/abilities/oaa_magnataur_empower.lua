magnataur_empower_oaa = class( AbilityBaseClass )

LinkLuaModifier("modifier_magnataur_empower_oaa_buff", "abilities/oaa_magnataur_empower.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

if IsServer() then
  function magnataur_empower_oaa:OnSpellStart( level )
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    -- Invalid target
    if target == nil then
      return
    end

    caster:EmitSound("Hero_Magnataur.Empower.Cast")
    target:EmitSound("Hero_Magnataur.Empower.Target")

    local duration = self:GetTalentSpecialValueFor("empower_duration")

    -- Add modifier or increate duration
    local modif = target:FindModifierByNameAndCaster("modifier_magnataur_empower_oaa_buff", caster)
    if modif ~= nil then
      target:RemoveModifierByNameAndCaster("modifier_magnataur_empower_oaa_buff", caster)
    end
    target:AddNewModifier(caster, self, "modifier_magnataur_empower_oaa_buff", {
      duration = duration
    })
  end
end

--------------------------------------------------------------------------------

modifier_magnataur_empower_oaa_buff = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_magnataur_empower_oaa_buff:IsHidden()
  return false
end

function modifier_magnataur_empower_oaa_buff:IsPurgable()
  return true
end

function modifier_magnataur_empower_oaa_buff:IsDebuff()
  return false
end

function modifier_magnataur_empower_oaa_buff:DestroyOnExpire()
  return true
end

--------------------------------------------------------------------------------

function modifier_magnataur_empower_oaa_buff:OnCreated(data)
  local ability = self:GetAbility()
  self.cleveInfo = {
      startRadius = ability:GetTalentSpecialValueFor("cleave_starting_width"),
      endRadius = ability:GetTalentSpecialValueFor("cleave_ending_width"),
      length = ability:GetTalentSpecialValueFor("cleave_distance")
    }
  self.cleaveDamageMult = ability:GetTalentSpecialValueFor("cleave_damage_pct") / 100.0
  self.damagePct = ability:GetTalentSpecialValueFor("bonus_damage_pct")
end

--------------------------------------------------------------------------------

function modifier_magnataur_empower_oaa_buff:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  MODIFIER_PROPERTY_TOOLTIP
  }
end

if IsServer() then
  function modifier_magnataur_empower_oaa_buff:GetModifierBaseDamageOutgoing_Percentage( event )
    if event.attacked ~= nil and self:GetParent() ~= event.attacker then
      return
    end
    return self.damagePct
  end
else -- IsClient(), for tooltips
  function modifier_magnataur_empower_oaa_buff:GetModifierBaseDamageOutgoing_Percentage( event )
    return self.damagePct
  end

  function modifier_magnataur_empower_oaa_buff:OnTooltip( event )
    return self.cleaveDamageMult * 100
  end
end

if IsServer() then
  function modifier_magnataur_empower_oaa_buff:OnAttackLanded( event )
    if self:GetParent() ~= event.attacker then
      return
    end
    if self:GetParent():IsRangedAttacker() then
      return
    end
    local ability = self:GetAbility()

    ability:PerformCleaveOnAttack(
      event,
      self.cleaveInfo,
      self.cleaveDamageMult,
      nil,
      nil,
      "particles/units/heroes/hero_magnataur/magnataur_empower_cleave_effect.vpcf",
      "particles/units/heroes/hero_magnataur/magnataur_empower_cleave_hit.vpcf"
    )
  end
end
