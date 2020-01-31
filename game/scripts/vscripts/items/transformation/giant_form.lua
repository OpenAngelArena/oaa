item_giant_form = class(TransformationBaseClass)

LinkLuaModifier( "modifier_item_giant_form_grow", "items/transformation/giant_form.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_giant_form:GetIntrinsicModifierName()
  -- we're not modifying the passive benefits at all
  -- ( besides the numbers )
  -- so we can just reuse the normal dragon lance modifier
  return "modifier_item_dragon_lance"
end

function item_giant_form:GetTransformationModifierName()
  return "modifier_item_giant_form_grow"
end

--------------------------------------------------------------------------------

modifier_item_giant_form_grow = class(ModifierBaseClass)

function modifier_item_giant_form_grow:IsHidden()
  return false
end

function modifier_item_giant_form_grow:IsDebuff()
  return false
end

function modifier_item_giant_form_grow:IsPurgable()
  return true
end

function modifier_item_giant_form_grow:GetEffectName()
  return "particles/units/heroes/hero_oracle/oracle_fortune_purge_root_pnt.vpcf"
end

function modifier_item_giant_form_grow:OnCreated( event )
  local spell = self:GetAbility()
  local parent = self:GetParent()

  spell.mod = self

  self.atkRange = spell:GetSpecialValueFor( "giant_attack_range" )
  self.castRange = spell:GetSpecialValueFor( "giant_cast_range" )
  self.atkDmg = spell:GetSpecialValueFor( "giant_damage_bonus" )
  self.atkSpd = spell:GetSpecialValueFor( "giant_atkspd_bonus" )
  self.splashRadius = spell:GetSpecialValueFor( "giant_aoe" )
  self.splashDmg = spell:GetSpecialValueFor( "giant_splash" )
end

modifier_item_giant_form_grow.OnRefresh = modifier_item_giant_form_grow.OnCreated

-- if IsServer() then
  -- function modifier_item_giant_form_grow:CheckState()
    -- if self:GetParent() and self:GetParent():IsRangedAttacker() then
      -- return {
        -- [MODIFIER_STATE_ROOTED] = true,
      -- }
    -- end
    -- return {}
  -- end
-- end

function modifier_item_giant_form_grow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
    MODIFIER_PROPERTY_MODEL_SCALE
  }

  return funcs
end

function modifier_item_giant_form_grow:GetModifierPreAttack_BonusDamage( event )
  local spell = self:GetAbility()

  return self.atkDmg or spell:GetSpecialValueFor( "giant_damage_bonus" )
end

function modifier_item_giant_form_grow:GetModifierFixedAttackRate( event )
  local spell = self:GetAbility()

  return spell:GetSpecialValueFor( "giant_attack_rate" )
end

function modifier_item_giant_form_grow:GetModifierAttackRangeBonus( event )
  local spell = self:GetAbility()
  local parent = self:GetParent()

  if not spell then
    if not self:IsNull() then
      self:Destroy()
    end
    return
  end

  return spell:GetSpecialValueFor( "giant_attack_range" )
end

function modifier_item_giant_form_grow:GetModifierCastRangeBonus( event )
  local spell = self:GetAbility()

  return self.castRange or spell:GetSpecialValueFor( "giant_cast_range" )
end

function modifier_item_giant_form_grow:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_item_giant_form_grow:GetModifierMoveSpeed_Absolute()
  local spell = self:GetAbility()

  if not spell then
    if not self:IsNull() then
      self:Destroy()
    end
    return
  end

  return spell:GetSpecialValueFor("giant_move_speed")
end

function modifier_item_giant_form_grow:GetModifierModelScale()
  return self:GetAbility():GetSpecialValueFor("giant_scale")
end

if IsServer() then
  function modifier_item_giant_form_grow:OnAttackLanded( event )
    local parent = self:GetParent()

    -- i can just use code from greater power treads here!
    -- yaaaaay
    if event.attacker == parent and event.process_procs then
      local target = event.target

      -- make sure the initial target is an appropriate unit to split off of
      -- ( so no wards, items, or towers )
      local parentTeam = parent:GetTeamNumber()
      local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
      local targetType = bit.bor( DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC )
      local targetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

      -- if not, cancel
      if UnitFilter( target, targetTeam, targetType, targetFlags, parentTeam ) ~= UF_SUCCESS then
        return
      end

      local spell = self:GetAbility()
      local targetOrigin = target:GetAbsOrigin()

      -- set the targeting requirements for the actual targets
      targetTeam = spell:GetAbilityTargetTeam()
      targetType = spell:GetAbilityTargetType()
      targetFlags = spell:GetAbilityTargetFlags()

      -- get the radius
      local radius = self.splashRadius or spell:GetSpecialValueFor( "giant_aoe" )

      -- find all appropriate targets around the initial target
      local units = FindUnitsInRadius(
        parentTeam,
        targetOrigin,
        nil,
        radius,
        targetTeam,
        targetType,
        targetFlags,
        FIND_ANY_ORDER,
        false
      )

      -- remove the initial target from the list
      for k, unit in pairs( units ) do
        if unit == target then
          table.remove( units, k )
          break
        end
      end

      -- get the wearer's damage
      local damage = event.original_damage

      -- get the damage modifier
      local damageMod = self.splashDmg or spell:GetSpecialValueFor( "giant_splash" )

      damageMod = damageMod * 0.01

      -- apply the damage modifier
      damage = damage * damageMod

      -- iterate through all targets
      for k, unit in pairs( units ) do
        -- inflict damage
        -- DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION prevents spell amp and spell lifesteal
        ApplyDamage( {
          victim = unit,
          attacker = self:GetCaster(),
          damage = damage,
          damage_type = DAMAGE_TYPE_PHYSICAL,
          damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
          ability = self,
        } )
      end

      -- play the particle
      local part = ParticleManager:CreateParticle( "particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, target )
      ParticleManager:SetParticleControl( part, 3, targetOrigin )
      ParticleManager:ReleaseParticleIndex( part )

      target:EmitSound( "OAA_Item.SiegeMode.Explosion" )
    end
  end
end

--------------------------------------------------------------------------------

item_giant_form_2 = item_giant_form
