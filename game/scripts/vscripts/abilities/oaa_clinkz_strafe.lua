--LinkLuaModifier("modifier_special_bonus_unique_clinkz_strafe_cooldown", "abilities/oaa_clinkz_strafe.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_clinkz_strafe_oaa", "abilities/oaa_clinkz_strafe.lua", LUA_MODIFIER_MOTION_NONE)

clinkz_strafe_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

function clinkz_strafe_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
    --self:SetLevel(0)
  end
end

function clinkz_strafe_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  caster:AddNewModifier(caster, self, "modifier_clinkz_strafe_oaa", { duration = duration } )

  caster:EmitSound("Hero_Clinkz.Strafe")
end

function clinkz_strafe_oaa:IsStealable()
  return true
end

--[[
function clinkz_strafe_oaa:GetCooldown( level )
  local caster = self:GetCaster()
  local base_cd = self.BaseClass.GetCooldown( self, level )
  if IsServer() then
    local talent = caster:FindAbilityByName("special_bonus_clinkz_strafe_cooldown")
    if talent and talent:GetLevel() > 0 then
      if not caster:HasModifier("modifier_special_bonus_unique_clinkz_strafe_cooldown") then
        caster:AddNewModifier(caster, talent, "modifier_special_bonus_unique_clinkz_strafe_cooldown", {})
      end
      return base_cd - math.abs(talent:GetSpecialValueFor("value"))
    else
      caster:RemoveModifierByName("modifier_special_bonus_unique_clinkz_strafe_cooldown")
    end
  else
    if caster:HasModifier("modifier_special_bonus_unique_clinkz_strafe_cooldown") and caster.special_bonus_unique_clinkz_strafe_cd then
      return base_cd - math.abs(caster.special_bonus_unique_clinkz_strafe_cd)
    end
  end

  return base_cd
end

---------------------------------------------------------------------------------------------------

-- Modifier on caster used for talent that improves Strafe cooldown
modifier_special_bonus_unique_clinkz_strafe_cooldown = class(ModifierBaseClass)

function modifier_special_bonus_unique_clinkz_strafe_cooldown:IsHidden()
  return true
end

function modifier_special_bonus_unique_clinkz_strafe_cooldown:IsPurgable()
  return false
end

function modifier_special_bonus_unique_clinkz_strafe_cooldown:RemoveOnDeath()
  return false
end

function modifier_special_bonus_unique_clinkz_strafe_cooldown:OnCreated()
  if not IsServer() then
    local parent = self:GetParent()
    local talent = self:GetAbility()
    parent.special_bonus_unique_clinkz_strafe_cd = talent:GetSpecialValueFor("value")
  end
end

function modifier_special_bonus_unique_clinkz_strafe_cooldown:OnDestroy()
  local parent = self:GetParent()
  if parent and parent.special_bonus_unique_clinkz_strafe_cd then
    parent.special_bonus_unique_clinkz_strafe_cd = nil
  end
end
]]

---------------------------------------------------------------------------------------------------

modifier_clinkz_strafe_oaa = class(ModifierBaseClass)

function modifier_clinkz_strafe_oaa:IsHidden()
  return false
end

function modifier_clinkz_strafe_oaa:IsPurgable()
  return true
end

function modifier_clinkz_strafe_oaa:IsDebuff()
  return false
end

function modifier_clinkz_strafe_oaa:OnCreated(event)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_evasion = ability:GetSpecialValueFor("bonus_evasion")
    self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed") --or ability:GetSpecialValueFor("attack_speed_bonus_pct")
  else
    self.bonus_evasion = 25
    self.bonus_attack_speed = 200
  end
end

function modifier_clinkz_strafe_oaa:OnRefresh(event)
  self:OnCreated(event)
end

function modifier_clinkz_strafe_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_clinkz_strafe_oaa:GetModifierAttackSpeedBonus_Constant()
  return self.bonus_attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_clinkz_strafe_oaa:GetModifierEvasion_Constant()
  return self.bonus_evasion or self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_clinkz_strafe_oaa:GetEffectName()
  return "particles/units/heroes/hero_clinkz/clinkz_strafe_fire.vpcf"
end

function modifier_clinkz_strafe_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
