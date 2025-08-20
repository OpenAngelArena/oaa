bubble_witch_magic_bubble = bubble_witch_magic_bubble or class({})

LinkLuaModifier("modifier_bubble_witch_magic_bubble_buff", "abilities/bubble_witch/bubble_witch_magic_bubble.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip

function bubble_witch_magic_bubble:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  local applies_basic_dispel = self:GetSpecialValueFor("applies_basic_dispel")
  if applies_basic_dispel > 0 then
    -- Basic Dispel for allies
    target:Purge(false, true, false, false, false)
  end

  -- Remove previous instance
  target:RemoveModifierByName("modifier_bubble_witch_magic_bubble_buff")

  -- Buff
  target:AddNewModifier(caster, self, "modifier_bubble_witch_magic_bubble_buff", {duration = self:GetSpecialValueFor("duration")})

  -- Bubble Form Sound
  target:EmitSound("Bubble_Witch.Magic_Bubble.Target")
end

---------------------------------------------------------------------------------------------------

modifier_bubble_witch_magic_bubble_buff = modifier_bubble_witch_magic_bubble_buff or class({})

function modifier_bubble_witch_magic_bubble_buff:IsHidden()
  return false
end

function modifier_bubble_witch_magic_bubble_buff:IsDebuff()
  return false
end

function modifier_bubble_witch_magic_bubble_buff:IsPurgable()
  return true
end

function modifier_bubble_witch_magic_bubble_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_slow = ability:GetSpecialValueFor("move_speed_reduction")
    self.turn_speed_slow = ability:GetSpecialValueFor("turn_speed_reduction")
    self.base_dmg = ability:GetSpecialValueFor("base_dmg")
    self.dmg_taken_as_explode_dmg = ability:GetSpecialValueFor("damage_taken_as_explode_damage")
    self.radius = ability:GetSpecialValueFor("explode_dmg_radius")
    self.dmg_cap = ability:GetSpecialValueFor("explode_damage_cap")
  end
  self.explode_dmg_from_dmg_taken = 0
end

modifier_bubble_witch_magic_bubble_buff.OnRefresh = modifier_bubble_witch_magic_bubble_buff.OnCreated

function modifier_bubble_witch_magic_bubble_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_bubble_witch_magic_bubble_buff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.move_speed_slow)
end

function modifier_bubble_witch_magic_bubble_buff:GetModifierTurnRate_Percentage()
  return 0 - math.abs(self.turn_speed_slow)
end

function modifier_bubble_witch_magic_bubble_buff:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING] = true
  }
end

if IsServer() then
  function modifier_bubble_witch_magic_bubble_buff:OnTakeDamage(event)
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

    if not self.explode_dmg_from_dmg_taken then
      self.explode_dmg_from_dmg_taken = 0
    end

    self.explode_dmg_from_dmg_taken = self.explode_dmg_from_dmg_taken + damage * self.dmg_taken_as_explode_dmg * 0.01
  end

  function modifier_bubble_witch_magic_bubble_buff:OnDestroy()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local parent_pos = parent:GetAbsOrigin()

    local enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      parent_pos,
      nil,
      self.radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_ANY_ORDER,
      false
    )

    local total_dmg = math.min(self.base_dmg + self.explode_dmg_from_dmg_taken, self.dmg_cap)
    if total_dmg > 0 then
      local damage_table = {
        attacker = caster,
        damage = total_dmg,
        damage_type = ability:GetAbilityDamageType(),
        ability = ability,
      }

      for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() then
          damage_table.victim = enemy
          ApplyDamage(damage_table)
        end
      end
    end

    -- Bubble pop particle
    -- local pfx = ParticleManager:CreateParticle("particles/neutral_fx/frogmen_water_bubble_explosion.vpcf", PATTACH_WORLDORIGIN, parent)
    -- ParticleManager:SetParticleControl(pfx, 0, parent_pos)
    -- ParticleManager:ReleaseParticleIndex(pfx)

    -- Bubble pop sound
    -- if parent:IsAlive() then
      -- parent:EmitSound("Bubble_Witch.Bubble.Pop")
    -- else
      -- EmitSoundOnLocationWithCaster(parent_pos, "Bubble_Witch.Bubble.Pop", caster)
    -- end
  end
end

function modifier_bubble_witch_magic_bubble_buff:GetEffectName()
  return "particles/econ/taunts/snapfire/snapfire_taunt_bubble.vpcf"
end

function modifier_bubble_witch_magic_bubble_buff:GetEffectAttachType()
  return PATTACH_ROOTBONE_FOLLOW
end
