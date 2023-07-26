LinkLuaModifier("modifier_boss_basic_properties_oaa", "abilities/boss/boss_basic_properties.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_truesight_oaa", "abilities/boss/boss_basic_properties.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_debuff_protection_oaa", "abilities/boss/boss_basic_properties.lua", LUA_MODIFIER_MOTION_NONE)

boss_basic_properties_oaa = class(AbilityBaseClass)

function boss_basic_properties_oaa:GetIntrinsicModifierName()
  return "modifier_boss_basic_properties_oaa"
end

function boss_basic_properties_oaa:GetCooldown(level)
  return self:GetSpecialValueFor("cooldown")
end

function boss_basic_properties_oaa:ShouldUseResources()
  return true
end

-----------------------------------------------------------------------------------------

modifier_boss_basic_properties_oaa = class(ModifierBaseClass)

function modifier_boss_basic_properties_oaa:IsHidden()
  return true
end

function modifier_boss_basic_properties_oaa:IsDebuff()
  return true
end

function modifier_boss_basic_properties_oaa:IsPurgable()
  return false
end

function modifier_boss_basic_properties_oaa:OnCreated()
  local ability = self:GetAbility()
  self.dmg_reduction = ability:GetSpecialValueFor("percent_damage_reduce")
  self.max_armor_reduction = ability:GetSpecialValueFor("max_armor_reduction")
  self.reveal_duration = ability:GetSpecialValueFor("reveal_duration")
  self.debuff_protection_duration = ability:GetSpecialValueFor("debuff_protection_duration")
end

modifier_boss_basic_properties_oaa.OnRefresh = modifier_boss_basic_properties_oaa.OnCreated

function modifier_boss_basic_properties_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_STATE_CHANGED,
  }
end

if IsServer() then
  function modifier_boss_basic_properties_oaa:GetModifierTotal_ConstantBlock(keys)
    local parent = self:GetParent()

    if keys.attacker == parent then -- boss degen nonsense
      return 0
    end

    local inflictor = keys.inflictor
    if parent:CheckForAccidentalDamage(inflictor) then
      -- Block all damage if it was accidental
      return keys.damage
    end

    return keys.damage * self.dmg_reduction / 100
  end

  function modifier_boss_basic_properties_oaa:OnTakeDamage(event)
    local parent = self:GetParent()   -- boss
    local ability = self:GetAbility() -- boss_basic_properties_oaa

    local attacker = event.attacker
    local victim = event.unit
    local inflictor = event.inflictor
    local damage = event.damage

    if not attacker or attacker:IsNull() or not victim or victim:IsNull() then
      return
    end

    -- Check if damaged entity is not this boss
    if victim ~= parent then
      return
    end

    -- Check if it's self damage
    if attacker == victim then
      return
    end

    -- Check if it's accidental damage
    if parent:CheckForAccidentalDamage(inflictor) then
      return
    end

    -- Find what tier is this boss if its defined and set the appropriate damage_threshold
    local tier = parent.BossTier or 1
    local damage_threshold = BOSS_AGRO_FACTOR or 15
    damage_threshold = damage_threshold * tier

    -- Check if damage is less than the threshold
    -- second check is for invis/smoked units with Radiance type damage (damage below the threshold)
    if damage <= damage_threshold and parent:GetHealth() / parent:GetMaxHealth() > 50/100 then
      return
    end

    -- Reveal the attacker for revealDuration seconds
    attacker:AddNewModifier(parent, ability, "modifier_boss_truesight_oaa", {duration = self.reveal_duration})
  end

  function modifier_boss_basic_properties_oaa:GetModifierPhysicalArmorBonus()
    local parent = self:GetParent()
    if self.checkArmor then
      return 0
    else
      self.checkArmor = true
      local base_armor = parent:GetPhysicalArmorBaseValue()
      local current_armor = parent:GetPhysicalArmorValue(false)
      self.checkArmor = false
      local min_armor = base_armor - self.max_armor_reduction
      if current_armor < min_armor then
        return min_armor - current_armor
      end
    end
    return 0
  end

  function modifier_boss_basic_properties_oaa:GetModifierIncomingDamage_Percentage(keys)
    local attacker = keys.attacker
    local inflictor = keys.inflictor

    if not inflictor then
      -- Damage was not done with an ability
      -- Lone Druid Bear Demolish bonus damage
      if attacker:HasModifier("modifier_lone_druid_spirit_bear_demolish") then
        local ability = attacker:FindAbilityByName("lone_druid_spirit_bear_demolish")
        if ability then
          local damage_increase_pct
          if attacker:IsRealHero() then
            damage_increase_pct = ability:GetSpecialValueFor("true_form_bonus_building_damage")
          else
            damage_increase_pct = ability:GetSpecialValueFor("bonus_building_damage")
          end
          if damage_increase_pct and damage_increase_pct > 0 then
            return damage_increase_pct
          end
        end
      end

      -- Tiny Tree Grab bonus damage
      if attacker:HasModifier("modifier_tiny_tree_grab") then
        local ability = attacker:FindAbilityByName("tiny_tree_grab")
        if ability then
          local damage_increase_pct = ability:GetSpecialValueFor("bonus_damage_buildings")
          if damage_increase_pct and damage_increase_pct > 0 then
            return damage_increase_pct
          end
        end
      end

      -- Brewmaster Earth Split Demolish
      if attacker:HasModifier("modifier_brewmaster_earth_pulverize") then
        local ability = attacker:FindAbilityByName("brewmaster_earth_pulverize")
        if ability then
          local damage_increase_pct = ability:GetSpecialValueFor("bonus_building_damage")
          if damage_increase_pct and damage_increase_pct > 0 then
            return damage_increase_pct
          end
        end
      end

      return 0
    end

    -- Reduce the damage of some percentage damage spells
    local percentDamageSpells = {
      anti_mage_mana_void = true,
      bloodseeker_bloodrage = false,          -- doesn't work on vanilla Roshan
      doom_bringer_infernal_blade = true,     -- doesn't work on vanilla Roshan
      huskar_life_break = true,               -- doesn't work on vanilla Roshan
      jakiro_liquid_ice = false,
      necrolyte_reapers_scythe = true,        -- doesn't work on vanilla Roshan
      phantom_assassin_fan_of_knives = false,
      winter_wyvern_arctic_burn = true        -- doesn't work on vanilla Roshan
    }
    local name = inflictor:GetAbilityName()
    if percentDamageSpells[name] then
      return 0 - self.dmg_reduction
    end

  --   -- List of modifiers with all damage amplification that need to stack multiplicatively with Boss Resistance
  --   local damageAmpModifiers = {
  --     "modifier_bloodseeker_bloodrage",
  --     "modifier_chen_penitence",
  --     "modifier_shadow_demon_soul_catcher"
  --   }
  --   -- A list matched with the previous one for the AbilitySpecial keys that contain the damage amp values of the modifiers
  --   local ampAbilitySpecialKeys = {
  --     "damage_increase_pct",
  --     "bonus_damage_taken",
  --     "bonus_damage_taken"
  --   }

  --   -- Calculates a value that will counteract damage amplification from the named modifier such that
  --   -- it's as if the damage amplification stacks multiplicatively with Boss Resistance
  --   local function CalculateMultiplicativeAmpStack(modifierName, ampValueKey)
  --     local modifiers = parent:FindAllModifiersByName(modifierName)

  --     local function CalculateAmp(modifier)
  --       if modifier:IsNull() then
  --         return 0
  --       else
  --         local modifierDamageAmp = modifier:GetAbility():GetSpecialValueFor(ampValueKey)
  --         return (100 - damageReduction) / 100 * modifierDamageAmp - modifierDamageAmp
  --       end
  --     end

  --     return sum(map(CalculateAmp, modifiers))
  --   end

  --   local damageAmpReduction = sum(map(CalculateMultiplicativeAmpStack, zip(damageAmpModifiers, ampAbilitySpecialKeys)))
  --   return 0 - damageReduction + damageAmpReduction
    return 0
  end

  function modifier_boss_basic_properties_oaa:OnStateChanged(event)
    local parent = self:GetParent()   -- boss
    local ability = self:GetAbility() -- boss_basic_properties_oaa

    -- Debuff protection only if the boss has the boolean value
    if not parent.SiltBreakerProtection then
      return
    end

    local victim = event.unit

    if not victim or victim:IsNull() then
      return
    end

    -- Check if unit is this boss
    if victim ~= parent then
      return
    end

    if ability:IsCooldownReady() and (parent:IsStunned() or parent:IsSilenced()) then
      -- Strong Dispel
      parent:Purge(false, true, false, true, false)

      -- Add debuff protection
      parent:AddNewModifier(parent, ability, "modifier_boss_debuff_protection_oaa", {duration = self.debuff_protection_duration})

      -- Particle effect
      local blockEffectName = "particles/items_fx/immunity_sphere.vpcf"
      local blockEffect = ParticleManager:CreateParticle(blockEffectName, PATTACH_POINT_FOLLOW, parent)
      ParticleManager:ReleaseParticleIndex(blockEffect)

      -- Sound effect
      parent:EmitSound("DOTA_Item.LinkensSphere.Activate")

      -- Go on cooldown
      ability:UseResources(false, false, false, true)
    end
  end
end

function modifier_boss_basic_properties_oaa:CheckState()
  local parent = self:GetParent()
  local name = parent:GetUnitName()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
  if not string.find(name, "_wanderer_") then
    state[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
  end
  return state
end

---------------------------------------------------------------------------------------------------

modifier_boss_truesight_oaa = class(ModifierBaseClass)

function modifier_boss_truesight_oaa:IsDebuff()
  return true
end

function modifier_boss_truesight_oaa:IsPurgable()
  return false
end

function modifier_boss_truesight_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.maxRevealDist = ability:GetSpecialValueFor("reveal_max_distance")
  else
    self.maxRevealDist = 1500
  end
end

modifier_boss_truesight_oaa.OnRefresh = modifier_boss_truesight_oaa.OnCreated

function modifier_boss_truesight_oaa:IsHidden()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if not caster or caster:IsNull() or parent:HasModifier("modifier_slark_shadow_dance") or parent:HasModifier("modifier_slark_depth_shroud") then
    return true
  end

  return (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self.maxRevealDist
end

function modifier_boss_truesight_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

if IsServer() then
  function modifier_boss_truesight_oaa:CheckState()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if not caster or caster:IsNull() or parent:HasModifier("modifier_slark_shadow_dance") or parent:HasModifier("modifier_slark_depth_shroud") then
      return {}
    end

    -- Only reveal when within reveal_max_distance of boss
    if (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() <= self.maxRevealDist then
      return {
        [MODIFIER_STATE_INVISIBLE] = false
      }
    end

    return {}
  end
end

function modifier_boss_truesight_oaa:GetEffectName()
  return "particles/items2_fx/true_sight_debuff.vpcf"
end

function modifier_boss_truesight_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_truesight_oaa:GetTexture()
  return "item_gem"
end

---------------------------------------------------------------------------------------------------

modifier_boss_debuff_protection_oaa = class(ModifierBaseClass)

function modifier_boss_debuff_protection_oaa:IsHidden()
  return false
end

function modifier_boss_debuff_protection_oaa:IsDebuff()
  return false
end

function modifier_boss_debuff_protection_oaa:IsPurgable()
  return false
end

function modifier_boss_debuff_protection_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_boss_debuff_protection_oaa:CheckState()
  return {
    [MODIFIER_STATE_HEXED] = false,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_SILENCED] = false,
    [MODIFIER_STATE_STUNNED] = false,
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
    --[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
    [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
  }
end

function modifier_boss_debuff_protection_oaa:GetEffectName()
  return "particles/items_fx/black_king_bar_overhead.vpcf"
end

function modifier_boss_debuff_protection_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end
