LinkLuaModifier("modifier_bubble_witch_bubble_of_protection_thinker", "abilities/bubble_witch/bubble_witch_bubble_of_protection.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bubble_witch_bubble_of_protection_buff", "abilities/bubble_witch/bubble_witch_bubble_of_protection.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip

bubble_witch_bubble_of_protection = bubble_witch_bubble_of_protection or class({})

function bubble_witch_bubble_of_protection:OnSpellStart()
  local caster = self:GetCaster()
  local target_pos = self:GetCursorPosition()

  local radius = self:GetSpecialValueFor("radius")
  local duration = self:GetSpecialValueFor("duration")

  -- Create bubble
  CreateModifierThinker(caster, self, "modifier_bubble_witch_bubble_of_protection_thinker", {duration = duration}, target_pos, caster:GetTeamNumber(), false)

  EmitSoundOnLocationWithCaster(target_pos, "Bubble_Witch.Bubble_Of_Protection.Cast", caster)

  -- Particle
  local healing_pfx = ParticleManager:CreateParticle("particles/hero/bubble_witch/protection_bubble.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(healing_pfx, 0, target_pos)
  ParticleManager:SetParticleControl(healing_pfx, 1, Vector(radius, duration, 0))
  ParticleManager:ReleaseParticleIndex(healing_pfx)

  if caster:HasScepter() then
    -- Knockback enemies
    local enemies = FindUnitsInRadius(
      caster:GetTeamNumber(),
      target_pos,
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_ANY_ORDER,
      false
    )
    local knockback_table = {
      should_stun = 1,
      center_x = target_pos.x,
      center_y = target_pos.y,
      center_z = target_pos.z,
      knockback_distance = radius,
      knockback_height = 10,
      knockback_duration = 0.1,
      duration = 0.1,
    }
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        --knockback_table.knockback_distance = radius - (target_pos - enemy:GetAbsOrigin()):Length2D()
        --knockback_table.knockback_duration = enemy:GetValueChangedByStatusResistance(0.1)
        --knockback_table.duration = knockback_table.knockback_duration

        enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      end
    end
  end
end

function bubble_witch_bubble_of_protection:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

---------------------------------------------------------------------------------------------------
-- Thinker modifier
modifier_bubble_witch_bubble_of_protection_thinker = modifier_bubble_witch_bubble_of_protection_thinker or class({})

function modifier_bubble_witch_bubble_of_protection_thinker:IsHidden()
  return true
end

function modifier_bubble_witch_bubble_of_protection_thinker:IsDebuff()
  return false
end

function modifier_bubble_witch_bubble_of_protection_thinker:IsPurgable()
  return false
end

function modifier_bubble_witch_bubble_of_protection_thinker:OnCreated(keys)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.radius = ability:GetSpecialValueFor("radius")
  else
    self.radius = 225
  end
  if IsServer() then
    self:GetParent():EmitSound("Bubble_Witch.Bubble_Of_Protection.Loop")
  end
end

function modifier_bubble_witch_bubble_of_protection_thinker:OnDestroy()
  if IsServer() then
    self:GetParent():StopSound("Bubble_Witch.Bubble_Of_Protection.Loop")
  end
end

function modifier_bubble_witch_bubble_of_protection_thinker:IsAura()
  return true
end

function modifier_bubble_witch_bubble_of_protection_thinker:GetAuraRadius()
  return self.radius or self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_bubble_witch_bubble_of_protection_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_bubble_witch_bubble_of_protection_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_bubble_witch_bubble_of_protection_thinker:GetModifierAura()
  return "modifier_bubble_witch_bubble_of_protection_buff"
end

---------------------------------------------------------------------------------------------------

modifier_bubble_witch_bubble_of_protection_buff = modifier_bubble_witch_bubble_of_protection_buff or class({})

function modifier_bubble_witch_bubble_of_protection_buff:IsHidden()
  return false
end

function modifier_bubble_witch_bubble_of_protection_buff:IsDebuff()
  return false
end

function modifier_bubble_witch_bubble_of_protection_buff:IsPurgable()
  return false
end

function modifier_bubble_witch_bubble_of_protection_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_reduction = ability:GetSpecialValueFor("damage_reduction")
  else
    self.dmg_reduction = 75
  end

end

function modifier_bubble_witch_bubble_of_protection_buff:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

-- function modifier_bubble_witch_bubble_of_protection_buff:GetAbsoluteNoDamagePhysical()
  -- return 1
-- end

-- function modifier_bubble_witch_bubble_of_protection_buff:GetAbsoluteNoDamageMagical()
  -- return 1
-- end

-- function modifier_bubble_witch_bubble_of_protection_buff:GetAbsoluteNoDamagePure()
  -- return 1
-- end

if IsServer() then
  function modifier_bubble_witch_bubble_of_protection_buff:GetModifierTotal_ConstantBlock(keys)
    if keys.damage <= 0 then
      return 0
    end
    return keys.damage * self.dmg_reduction / 100
  end
end
