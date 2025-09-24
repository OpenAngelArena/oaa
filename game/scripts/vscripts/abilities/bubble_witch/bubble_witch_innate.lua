LinkLuaModifier("modifier_bubble_witch_innate_oaa", "abilities/bubble_witch/bubble_witch_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bubble_witch_innate_buff_oaa", "abilities/bubble_witch/bubble_witch_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bubble_witch_innate_immune_oaa", "abilities/bubble_witch/bubble_witch_innate.lua", LUA_MODIFIER_MOTION_NONE)

bubble_witch_innate = bubble_witch_innate or class({})

function bubble_witch_innate:GetIntrinsicModifierName()
  return "modifier_bubble_witch_innate_oaa"
end

---------------------------------------------------------------------------------------------------
modifier_bubble_witch_innate_oaa = modifier_bubble_witch_innate_oaa or class({})

function modifier_bubble_witch_innate_oaa:IsHidden()
  return true
end

function modifier_bubble_witch_innate_oaa:IsDebuff()
  return false
end

function modifier_bubble_witch_innate_oaa:IsPurgable()
  return false
end

function modifier_bubble_witch_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_bubble_witch_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_MODIFIER_ADDED,
  }
end

if IsServer() then
  function modifier_bubble_witch_innate_oaa:OnModifierAdded(event)
    local parent = self:GetParent()
    local unit = event.unit
    local mod = event.added_buff

    -- If owner is affected by break, do nothing
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return
    end

    -- Buffs are usually not applied to enemies
    if unit:GetTeamNumber() ~= parent:GetTeamNumber() then
      return
    end

    local caster = mod:GetCaster()

    -- Check if caster exists
    if not caster or caster:IsNull() then
      return
    end

    -- Check if caster has this modifier/ability
    if caster ~= parent then
      return
    end

    local black_list = {
      modifier_bottle_regeneration = 1, -- not intended, to prevent multiple proccing
      modifier_bubble_witch_blow_bubbles_ally = 1, -- to prevent multiple proccing, duration isn't constant
      modifier_bubble_witch_blow_bubbles_caster = 1, -- this is nonsense, not really a buff
      modifier_bubble_witch_bubble_of_protection_buff = 1, -- not intended, similar to aura
      modifier_bubble_witch_innate_buff_oaa = 1, -- to prevent a loop
      modifier_bubble_witch_innate_immune_oaa = 1, -- to prevent a loop
      modifier_bubble_witch_magic_bubble_buff = 1, -- to prevent multiple proccing, duration isn't constant
      modifier_generic_dead_tracker_oaa = 1, -- not intended, not a buff
      modifier_illusion = 1, -- not intended, not a buff
      modifier_invisible = 1, -- not intended, to prevent multiple proccing
      modifier_item_assault_positive = 1, -- not intended, aura
      modifier_item_bloodstone_drained = 1, -- not intended, not a buff
      modifier_item_bubble_orb_visible_buff = 1, -- not intended, similar to aura
      modifier_item_buckler_effect = 1, -- not intended, aura
      modifier_item_crimson_guard_nostack = 1, -- not intended, not a buff
      modifier_item_harpoon_pull = 1, -- not intended, not a buff
      modifier_item_lucience_movespeed_effect = 1, -- not intended, aura
      modifier_item_lucience_regen_effect = 1, -- not intended, aura
      modifier_item_magic_lamp_oaa_buff = 1, -- not intended, not a buff
      modifier_item_mekansm_noheal = 1, -- not intended, not a buff
      modifier_item_preemptive_bubble_block = 1, -- not intended, similar to aura
      modifier_item_ring_of_basilius_effect = 1, -- not intended, aura
      modifier_item_siege_mode_thinker = 1, -- not intended
      modifier_kill = 1, -- not intended, not a buff
      modifier_knockback = 1, -- not intended, not a buff
      modifier_manta = 1, -- not intended, not a buff
      modifier_observer_ward_recharger = 1, -- not intended, not a buff
      modifier_sentry_ward_recharger = 1, -- not intended, not a buff
      modifier_ui_custom_observer_ward_charges = 1, -- not intended, not a buff
      modifier_ui_custom_sentry_ward_charges = 1, -- not intended, not a buff
    }

    local exceptions = {
      modifier_item_preemptive_bubble_aura_block = 1,
    }

    local name = mod:GetName()
    if black_list[name] or (string.find(name, "_aura") and not exceptions[name]) then
      return
    end

    --print("modifier_bubble_witch_innate_buff_oaa buff applied: "..tostring(name).." with duration: "..tostring(mod:GetDuration()))

    local duration = mod:GetDuration()
    if duration > 0 then
      unit:AddNewModifier(parent, self:GetAbility(), "modifier_bubble_witch_innate_buff_oaa", {duration = mod:GetRemainingTime(), linked_mod = name})
    end
  end
end

---------------------------------------------------------------------------------------------------
modifier_bubble_witch_innate_buff_oaa = modifier_bubble_witch_innate_buff_oaa or class({})

function modifier_bubble_witch_innate_buff_oaa:IsHidden()
  return true
end

function modifier_bubble_witch_innate_buff_oaa:IsDebuff()
  return false
end

function modifier_bubble_witch_innate_buff_oaa:IsPurgable()
  return true
end

function modifier_bubble_witch_innate_buff_oaa:RemoveOnDeath()
  return true
end

function modifier_bubble_witch_innate_buff_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_bubble_witch_innate_buff_oaa:OnCreated(kv)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg = ability:GetSpecialValueFor("base_dmg")
    self.radius = ability:GetSpecialValueFor("explode_dmg_radius")
    self.immune_time = ability:GetSpecialValueFor("immune_time")
  else
    self.dmg = 50
    self.radius = 675
    self.immune_time = 0.1
  end
  if IsServer() and self:GetDuration() > 0.1 and self:GetRemainingTime() > 0.1 and kv.linked_mod then
    self.linked_mod = kv.linked_mod
    self:StartIntervalThink(0.1)
  end
end

if IsServer() then
  function modifier_bubble_witch_innate_buff_oaa:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    if not self.linked_mod then
      self:StartIntervalThink(-1)
      return
    end
    local linked_buff = parent:FindModifierByNameAndCaster(self.linked_mod, caster)
    if not linked_buff or linked_buff:IsNull() then
      self:StartIntervalThink(-1)
      self:Destroy()
    end
  end

  function modifier_bubble_witch_innate_buff_oaa:OnDestroy()
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

    local damage_table = {
      attacker = caster,
      damage = self.dmg,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability,
    }

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        if not enemy:HasModifier("modifier_bubble_witch_innate_immune_oaa") then
          if self.immune_time > 0 then
            enemy:AddNewModifier(enemy, nil, "modifier_bubble_witch_innate_immune_oaa", {duration = self.immune_time})
          end
          damage_table.victim = enemy
          ApplyDamage(damage_table)
        end
      end
    end

    -- Bubble pop particle
    local pfx = ParticleManager:CreateParticle("particles/neutral_fx/frogmen_water_bubble_explosion.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(pfx, 0, parent_pos)
    ParticleManager:ReleaseParticleIndex(pfx)

    -- Bubble pop sound
    if parent:IsAlive() then
      parent:EmitSound("Bubble_Witch.Bubble.Pop")
    else
      EmitSoundOnLocationWithCaster(parent_pos, "Bubble_Witch.Bubble.Pop", caster)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_bubble_witch_innate_immune_oaa = modifier_bubble_witch_innate_immune_oaa or class({})

function modifier_bubble_witch_innate_immune_oaa:IsHidden()
  return true
end

function modifier_bubble_witch_innate_immune_oaa:IsDebuff()
  return false
end

function modifier_bubble_witch_innate_immune_oaa:IsPurgable()
  return false
end

function modifier_bubble_witch_innate_immune_oaa:RemoveOnDeath()
  return true
end
