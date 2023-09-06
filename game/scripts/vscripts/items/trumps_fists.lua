item_trumps_fists_1 = class(ItemBaseClass)

LinkLuaModifier("modifier_item_trumps_fists_passive", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_trumps_fists_frostbite", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_trumps_fists_active", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE)

function item_trumps_fists_1:GetIntrinsicModifierName()
  return "modifier_item_trumps_fists_passive"
end

function item_trumps_fists_1:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Create the projectile
  local info = {
    Target = target,
    Source = caster,
    Ability = self,
    EffectName = "particles/items2_fx/paintball.vpcf",
    bDodgeable = true,
    bProvidesVision = true,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
    iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
    iVisionRadius = 250,
    iVisionTeamNumber = caster:GetTeamNumber(),
  }

  ProjectileManager:CreateTrackingProjectile(info)

  -- Launch Sound
  target:EmitSound("Item.Paintball.Cast")
end

function item_trumps_fists_1:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  if not target or target:IsNull() then
    return
  end

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  -- Apply Brand of Judecca debuff (duration IS affected by status resistance)
  local debuff_duration = target:GetValueChangedByStatusResistance(self:GetSpecialValueFor("mute_duration"))
  target:AddNewModifier(caster, self, "modifier_item_trumps_fists_active", {duration = debuff_duration})

  -- Apply Frostburn debuff (duration is NOT affected by status resistance)
  local frostburn_duration = self:GetSpecialValueFor("heal_prevent_duration")
  target:AddNewModifier(caster, self, "modifier_item_trumps_fists_frostbite", {duration = frostburn_duration})

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/items2_fx/paintball_detonation.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  -- Hit Sound
  target:EmitSound("Item.Paintball.Target")
end

item_trumps_fists_2 = item_trumps_fists_1

---------------------------------------------------------------------------------------------------

modifier_item_trumps_fists_passive = class(ModifierBaseClass)

function modifier_item_trumps_fists_passive:IsHidden()
  return true
end

function modifier_item_trumps_fists_passive:IsDebuff()
  return false
end

function modifier_item_trumps_fists_passive:IsPurgable()
  return false
end

function modifier_item_trumps_fists_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_trumps_fists_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_all_stats = ability:GetSpecialValueFor( "bonus_all_stats" )
    self.bonus_damage = ability:GetSpecialValueFor( "bonus_damage" )
    self.bonus_health = ability:GetSpecialValueFor( "bonus_health" )
    self.bonus_mana = ability:GetSpecialValueFor( "bonus_mana" )
    self.heal_prevent_duration = ability:GetSpecialValueFor( "heal_prevent_duration" )
  end

  if IsServer() then
    self:GetParent():ChangeAttackProjectile()
  end
end

modifier_item_trumps_fists_passive.OnRefresh = modifier_item_trumps_fists_passive.OnCreated

function modifier_item_trumps_fists_passive:OnDestroy()
  local parent = self:GetParent()
  if IsServer() and parent and not parent:IsNull() then
    parent:ChangeAttackProjectile()
  end
end

function modifier_item_trumps_fists_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Strength()
  return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Agility()
  return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Intellect()
  return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_trumps_fists_passive:GetModifierHealthBonus()
  return self.bonus_health
end

function modifier_item_trumps_fists_passive:GetModifierManaBonus()
  return self.bonus_mana
end

if IsServer() then
  function modifier_item_trumps_fists_passive:OnAttackLanded(event)
    if not self:IsFirstItemInInventory() then
      return
    end
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacker is an illusion or dead
    if attacker:IsIllusion() or not attacker:IsAlive() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    -- Disable multiplicative stacking with Skadi
    if target:HasModifier("modifier_item_skadi_slow") then
      return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    -- Apply Frostburn debuff
    target:AddNewModifier(parent, ability, "modifier_item_trumps_fists_frostbite", {duration = self.heal_prevent_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_trumps_fists_frostbite = class(ModifierBaseClass)

function modifier_item_trumps_fists_frostbite:IsHidden()
  return false
end

function modifier_item_trumps_fists_frostbite:IsDebuff()
  return true
end

function modifier_item_trumps_fists_frostbite:IsPurgable()
  return false
end

function modifier_item_trumps_fists_frostbite:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
    --if IsServer() then
      --self.totalDuration = self:GetDuration() or self:GetAbility():GetSpecialValueFor( "heal_prevent_duration" )
      --self.health_fraction = 0
    --end
  end
end

modifier_item_trumps_fists_frostbite.OnRefresh = modifier_item_trumps_fists_frostbite.OnCreated

function modifier_item_trumps_fists_frostbite:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_EVENT_ON_HEALTH_GAINED,
  }
end

--function modifier_item_trumps_fists_frostbite:GetDisableHealing()
  --return 1
--end
-- Old heal prevention that decays over time
--[[
function modifier_item_trumps_fists_frostbite:OnHealthGained( kv )
  if IsServer() then
    -- Check that event is being called for the unit that self is attached to
    if kv.unit == self:GetParent() and kv.gain > 0 then
      local healPercent = self.heal_prevent_percent / 100 * (self:GetRemainingTime() / self.totalDuration)
      local desiredHP = kv.unit:GetHealth() + kv.gain * healPercent + self.health_fraction
      desiredHP = math.max(desiredHP, 1)
      -- Keep record of fractions of health since Dota doesn't (mainly to make passive health regen sort of work)
      self.health_fraction = desiredHP % 1

      DebugPrint(desiredHP)
      kv.unit:SetHealth( desiredHP )
    end
  end
end
]]

if IsServer() then
  -- Deals damage every time a unit gains hp; damage is equal to a percent of gained hp;
  function modifier_item_trumps_fists_frostbite:OnHealthGained(event)
    local caster = self:GetCaster()
    local unit = event.unit
    local gained_hp = event.gain or 0

    -- Check if unit exists
    if not unit or unit:IsNull() then
      return
    end

    -- Check if unit has this modifier
    if unit ~= self:GetParent() then
      return
    end

    if gained_hp <= 0 then
      return
    end

    -- Check if caster exists
    if not caster or caster:IsNull() then
      return
    end

    -- Check if caster is alive
    if not caster:IsAlive() then
      return
    end

    -- Check if unit has vanilla Sticky Napalm
    if unit:FindModifierByNameAndCaster("modifier_batrider_sticky_napalm", caster) then
      return
    end

    -- Disable multiplicative stacking with Skadi
    if unit:HasModifier("modifier_item_skadi_slow") then
      return
    end

    local heal_to_damage = self.heal_prevent_percent or 45
    local damage = gained_hp * heal_to_damage / 100

    -- If unit has Veil of Discord debuff, try to find the item and reduce the damage because it will be amped by Veil
    if unit:HasModifier("modifier_item_veil_of_discord_debuff") then
      local veil_debuff = unit:FindModifierByName("modifier_item_veil_of_discord_debuff")
      local veil_item = veil_debuff:GetAbility()
      if veil_item then
        local damage_amp = veil_item:GetSpecialValueFor("spell_amp")
        if damage_amp then
          damage = damage / (1 + damage_amp/100)
        end
      end
    end

    local damage_table = {
      victim = unit,
      attacker = caster,
      damage = damage,
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION),
      ability = self:GetAbility(),
    }

    ApplyDamage(damage_table)
  end
end

function modifier_item_trumps_fists_frostbite:GetEffectName()
  return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_debuff.vpcf"
end

function modifier_item_trumps_fists_frostbite:GetTexture()
  return "custom/trumps_fists"
end

---------------------------------------------------------------------------------------------------

modifier_item_trumps_fists_active = class(ModifierBaseClass)

function modifier_item_trumps_fists_active:IsHidden()
  return false
end

function modifier_item_trumps_fists_active:IsDebuff()
  return true
end

function modifier_item_trumps_fists_active:IsPurgable()
  return true
end

function modifier_item_trumps_fists_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
end

function modifier_item_trumps_fists_active:GetModifierProvidesFOWVision()
	return 1
end

function modifier_item_trumps_fists_active:CheckState()
  return {
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_PROVIDES_VISION] = true,
  }
end

--function modifier_item_trumps_fists_active:GetEffectName()
  --return ""
--end

--function modifier_item_trumps_fists_active:GetEffectAttachType()
  --return PATTACH_ABSORIGIN_FOLLOW
--end

function modifier_item_trumps_fists_active:GetTexture()
  return "custom/trumps_fists"
end
