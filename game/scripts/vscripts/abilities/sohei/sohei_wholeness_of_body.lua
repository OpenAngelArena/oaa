sohei_wholeness_of_body = class( AbilityBaseClass )

LinkLuaModifier("modifier_sohei_wholeness_of_body_buff", "abilities/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE)

function sohei_wholeness_of_body:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasScepter() or self:IsStolen() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
  end
end

function sohei_wholeness_of_body:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget() or caster

  -- Activation sound
  target:EmitSound("Sohei.Guard")

  -- Strong Dispel
  target:Purge(false, true, false, true, true)

  -- Remove debuffs that are removed only with BKB/Spell Immunity/Debuff Immunity
  --caster:RemoveModifierByName("modifier_slark_pounce_leash")
  --caster:RemoveModifierByName("modifier_invoker_deafening_blast_disarm")

  -- Applying the buff
  target:AddNewModifier(caster, self, "modifier_sohei_wholeness_of_body_buff", {duration = self:GetSpecialValueFor("duration")})

  -- Knockback talent
  -- local talent = caster:FindAbilityByName("special_bonus_unique_sohei_6_oaa")
  -- if talent and talent:GetLevel() > 0 then
    -- local position = target:GetAbsOrigin()
    -- local radius = talent:GetSpecialValueFor("value")

    -- local enemies = FindUnitsInRadius(
      -- caster:GetTeamNumber(),
      -- position,
      -- nil,
      -- radius,
      -- DOTA_UNIT_TARGET_TEAM_ENEMY,
      -- bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      -- DOTA_UNIT_TARGET_FLAG_NONE,
      -- FIND_ANY_ORDER,
      -- false
    -- )

    -- -- Check if caster has Momentum Strike learned, if not apply regular knockback
    -- local momentum_strike = caster:FindAbilityByName("sohei_momentum_strike")
    -- if momentum_strike and momentum_strike:GetLevel() > 0 then
      -- -- Knockback parameters
      -- local distance = momentum_strike:GetSpecialValueFor("knockback_distance")
      -- local speed = momentum_strike:GetSpecialValueFor("knockback_speed")
      -- local duration = distance / speed
      -- local collision_radius = momentum_strike:GetSpecialValueFor("collision_radius")

      -- for _, enemy in ipairs(enemies) do
        -- local direction = enemy:GetAbsOrigin() - position
        -- direction.z = 0
        -- direction = direction:Normalized()

        -- -- Apply Momentum Strike Knockback to the enemy
        -- enemy:RemoveModifierByName("modifier_sohei_momentum_strike_knockback")
        -- enemy:AddNewModifier(caster, momentum_strike, "modifier_sohei_momentum_strike_knockback", {
          -- duration = duration,
          -- distance = distance,
          -- speed = speed,
          -- collision_radius = collision_radius,
          -- direction_x = direction.x,
          -- direction_y = direction.y,
        -- })
      -- end
    -- else
      -- local knockback_table = {
        -- should_stun = 0,
        -- center_x = position.x,
        -- center_y = position.y,
        -- center_z = position.z,
        -- duration = talent:GetSpecialValueFor("duration"),
        -- knockback_duration = talent:GetSpecialValueFor("duration"),
        -- knockback_height = 10,
      -- }
      -- for _, enemy in ipairs(enemies) do
        -- knockback_table.knockback_distance = radius - (position - enemy:GetAbsOrigin()):Length2D()
        -- enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      -- end
    -- end
  -- end
end

---------------------------------------------------------------------------------------------------

-- wholeness_of_body modifier
modifier_sohei_wholeness_of_body_buff = class(ModifierBaseClass)

function modifier_sohei_wholeness_of_body_buff:IsHidden()
  return false
end

function modifier_sohei_wholeness_of_body_buff:IsDebuff()
  return false
end

function modifier_sohei_wholeness_of_body_buff:IsPurgable()
  return true
end

function modifier_sohei_wholeness_of_body_buff:GetEffectName()
  return "particles/hero/sohei/guard.vpcf"
end

function modifier_sohei_wholeness_of_body_buff:GetEffectAttachType()
  return PATTACH_CENTER_FOLLOW
end

function modifier_sohei_wholeness_of_body_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.magic_resistance = ability:GetSpecialValueFor("bonus_magic_resistance")
    self.post_heal_base = ability:GetSpecialValueFor("post_heal")
    self.dmg_taken_as_heal = ability:GetSpecialValueFor("damage_taken_as_heal") / 100
  else
    self.magic_resistance = 50
    self.post_heal_base = 75
    self.dmg_taken_as_heal = 25 / 100
  end

  self.post_heal_from_dmg_taken = 0
end

function modifier_sohei_wholeness_of_body_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.magic_resistance = ability:GetSpecialValueFor("bonus_magic_resistance")
    self.post_heal_base = ability:GetSpecialValueFor("post_heal")
    self.dmg_taken_as_heal = ability:GetSpecialValueFor("damage_taken_as_heal") / 100
  else
    self.magic_resistance = 60
    self.post_heal_base = 75
    self.dmg_taken_as_heal = 25 / 100
  end
end

function modifier_sohei_wholeness_of_body_buff:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local total_heal = self.post_heal_base + self.post_heal_from_dmg_taken

    parent:Heal(total_heal, ability)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, total_heal, nil)
  end
end

function modifier_sohei_wholeness_of_body_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_sohei_wholeness_of_body_buff:GetModifierMagicalResistanceBonus()
  return self.magic_resistance or self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

if IsServer() then
  function modifier_sohei_wholeness_of_body_buff:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity has this modifier
    if damaged_unit ~= parent then
      return
    end

    local damage = event.original_damage

    -- Check if damage is somehow 0 or negative
    if damage <= 0 then
      return
    end

    if not self.post_heal_from_dmg_taken then
      self.post_heal_from_dmg_taken = 0
    end

    self.post_heal_from_dmg_taken = self.post_heal_from_dmg_taken + damage * self.dmg_taken_as_heal
  end
end