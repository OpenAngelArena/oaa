sohei_wholeness_of_body = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_wholeness_of_body_buff", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function sohei_wholeness_of_body:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget() or caster
  -- Activation sound
  target:EmitSound("Sohei.Guard")
  -- Strong Dispel
  target:Purge(false, true, false, true, true)
  -- Applying the buff
  target:AddNewModifier(caster, self, "modifier_sohei_wholeness_of_body_buff", {duration = self:GetSpecialValueFor("duration")})
  -- Knockback talent
  local talent = caster:FindAbilityByName("special_bonus_sohei_wholeness_knockback")
  if talent and talent:GetLevel() > 0 then
    local position = target:GetAbsOrigin()
    local radius = talent:GetSpecialValueFor("value")

    local enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      position,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    -- Check if caster has Momentum Strike learned, if not apply regular knockback
    local momentum_strike = caster:FindAbilityByName("sohei_momentum_strike")
    if momentum_strike and momentum_strike:GetLevel() > 0 then
      -- Knockback parameters
      local distance = momentum_strike:GetSpecialValueFor("knockback_distance")
      local speed = momentum_strike:GetSpecialValueFor("knockback_speed")
      local duration = distance / speed
      local collision_radius = momentum_strike:GetSpecialValueFor("collision_radius")

      for _, enemy in ipairs(enemies) do
        local direction = enemy:GetAbsOrigin() - position
        direction.z = 0
        direction = direction:Normalized()

        -- Apply Momentum Strike Knockback to the enemy
        enemy:RemoveModifierByName("modifier_sohei_momentum_strike_knockback")
        enemy:AddNewModifier(caster, momentum_strike, "modifier_sohei_momentum_strike_knockback", {
          duration = duration,
          distance = distance,
          speed = speed,
          collision_radius = collision_radius,
          direction_x = direction.x,
          direction_y = direction.y,
        })
      end
    else
      for _, enemy in ipairs(enemies) do
        local modifierKnockback = {
          center_x = position.x,
          center_y = position.y,
          center_z = position.z,
          duration = talent:GetSpecialValueFor("duration"),
          knockback_duration = talent:GetSpecialValueFor("duration"),
          knockback_distance = radius - (position - enemy:GetAbsOrigin()):Length2D(),
        }
        enemy:AddNewModifier(caster, self, "modifier_knockback", modifierKnockback )
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

-- wholeness_of_body modifier
modifier_sohei_wholeness_of_body_buff = class(ModifierBaseClass)

function modifier_sohei_wholeness_of_body_buff:IsDebuff()
  return false
end

function modifier_sohei_wholeness_of_body_buff:IsHidden()
  return false
end

function modifier_sohei_wholeness_of_body_buff:IsPurgable()
  return true
end

function modifier_sohei_wholeness_of_body_buff:GetEffectName()
  return "particles/hero/sohei/guard.vpcf"
end

function modifier_sohei_wholeness_of_body_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_wholeness_of_body_buff:OnCreated()
  local ability = self:GetAbility()
  self.magic_resistance = ability:GetTalentSpecialValueFor("bonus_magic_resistance")
  self.damageheal = ability:GetTalentSpecialValueFor("damage_taken_heal") / 100
  self.endHeal = 0
end

function modifier_sohei_wholeness_of_body_buff:OnRefresh()
  local ability = self:GetAbility()
  self.magic_resistance = ability:GetTalentSpecialValueFor("bonus_magic_resistance")
  self.damageheal = ability:GetTalentSpecialValueFor("damage_taken_heal") / 100
end

function modifier_sohei_wholeness_of_body_buff:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local heal_amount = self.endHeal + ability:GetTalentSpecialValueFor("post_heal")

    parent:Heal(heal_amount, ability)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal_amount, nil)
  end
end

function modifier_sohei_wholeness_of_body_buff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }

  return funcs
end

function modifier_sohei_wholeness_of_body_buff:GetModifierMagicalResistanceBonus()
  return self.magic_resistance
end

function modifier_sohei_wholeness_of_body_buff:OnTakeDamage( params )
  if params.unit == self:GetParent() then
    self.endHeal = self.endHeal + params.original_damage * self.damageheal
  end
end
