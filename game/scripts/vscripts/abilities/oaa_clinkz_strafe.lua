LinkLuaModifier("modifier_special_bonus_unique_clinkz_strafe_cooldown", "abilities/oaa_clinkz_strafe.lua", LUA_MODIFIER_MOTION_NONE)

clinkz_strafe_oaa = class( AbilityBaseClass )

--------------------------------------------------------------------------------

function clinkz_strafe_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )
  --local attack_speed_bonus_pct = self:GetSpecialValueFor( "attack_speed_bonus_pct" )

  caster:AddNewModifier(caster, self, "modifier_clinkz_strafe", { duration = duration } )

  caster:EmitSound("Hero_Clinkz.Strafe")
end

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
