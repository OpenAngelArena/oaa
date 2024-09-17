LinkLuaModifier("modifier_item_reflection_shard_passive", "items/reflection_shard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_reflection_shard_active", "items/reflection_shard.lua", LUA_MODIFIER_MOTION_NONE)

item_reflection_shard_1 = class(ItemBaseClass)
item_reflection_shard_2 = item_reflection_shard_1
item_reflection_shard_3 = item_reflection_shard_1
item_reflection_shard_4 = item_reflection_shard_1

function item_reflection_shard_1:GetIntrinsicModifierName()
  return "modifier_item_reflection_shard_passive"
end

function item_reflection_shard_1:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  -- Basic Dispel (for the caster)
  caster:Purge(false, true, false, false, false)

  -- Sound
  caster:EmitSound("Hero_Antimage.Counterspell.Cast")

  -- Apply Reflection shard modifier
  caster:AddNewModifier(caster, self, "modifier_item_reflection_shard_active", {duration = duration})

  -- Built-in modifier (Lotus Orb Echo Shell)
  caster:AddNewModifier(caster, self, "modifier_item_lotus_orb_active", {duration = duration})
end

---------------------------------------------------------------------------------------------------

modifier_item_reflection_shard_passive = class(ModifierBaseClass)

function modifier_item_reflection_shard_passive:IsHidden()
  return true
end

function modifier_item_reflection_shard_passive:IsDebuff()
  return false
end

function modifier_item_reflection_shard_passive:IsPurgable()
  return false
end

function modifier_item_reflection_shard_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_reflection_shard_passive:OnCreated()
  self:OnRefresh()
end

function modifier_item_reflection_shard_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.magic_resist = ability:GetSpecialValueFor("bonus_magic_resist")
  end
end

function modifier_item_reflection_shard_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_item_reflection_shard_passive:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_reflection_shard_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_reflection_shard_passive:GetModifierMagicalResistanceBonus()
  return self.magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resist")
end

---------------------------------------------------------------------------------------------------

modifier_item_reflection_shard_active = class(ModifierBaseClass)

function modifier_item_reflection_shard_active:IsHidden()
  return false
end

function modifier_item_reflection_shard_active:IsDebuff()
  return false
end

function modifier_item_reflection_shard_active:IsPurgable()
  return false
end

function modifier_item_reflection_shard_active:OnCreated(event)
  if IsServer() then
    local parent = self:GetParent()
    if self.particleID == nil then
      self.particleID = ParticleManager:CreateParticle("particles/items/reflection_shard/reflection_shield.vpcf", PATTACH_ROOTBONE_FOLLOW, parent)
    end

    --if parent.stored_reflected_spells == nil then
      --parent.stored_reflected_spells = {}
    --end
  end
end


function modifier_item_reflection_shard_active:OnDestroy()
  if IsServer() then
    --local parent = self:GetParent()
    --parent:EmitSound("Item.LotusOrb.Destroy")
    if self.particleID then
      ParticleManager:DestroyParticle(self.particleID, false)
      ParticleManager:ReleaseParticleIndex(self.particleID)
      self.particleID = nil
    end
    --[[
    for _, ability in pairs(parent.stored_reflected_spells) do
      -- If this ability is not having active modifiers and its not channeling it can be removed
      if ability and not ability:IsNull() then
        if ability:NumModifiersUsingAbility() == 0 and not ability:IsChanneling() then
          -- Some abilities need a delay in case they are dealing damage with a delay (Finger of Death for example)
          -- 2 seconds delay should be enough
          Timers:CreateTimer(2, function()
            -- Check if ability is removed already
            if ability and not ability:IsNull() then
              ability:RemoveSelf()
            end
          end)
        end
      end
    end
    ]]
  end
end

function modifier_item_reflection_shard_active:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_ABSORB_SPELL,
    --MODIFIER_PROPERTY_REFLECT_SPELL,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

-- function modifier_item_reflection_shard_active:GetAbsoluteNoDamagePhysical()
  -- return 1
-- end

-- function modifier_item_reflection_shard_active:GetAbsoluteNoDamageMagical()
  -- return 1
-- end

-- function modifier_item_reflection_shard_active:GetAbsoluteNoDamagePure()
  -- return 1
-- end
if IsServer() then
  function modifier_item_reflection_shard_active:GetAbsorbSpell(event)
    local parent = self:GetParent()
    local casted_ability = event.ability

    -- Don't block if we don't have required variables
    if not casted_ability or casted_ability:IsNull() then
      return 0
    end

    local caster = casted_ability:GetCaster()

    -- Don't block allied spells
    if caster:GetTeamNumber() == parent:GetTeamNumber() then
      return 0
    end

    -- Some stuff pierce invulnerability (like Nullifier) so we need to block them too

    -- Sound
    parent:EmitSound("Hero_Antimage.Counterspell.Target")

    -- Particle
    local burst = ParticleManager:CreateParticle("particles/items/reflection_shard/immunity_sphere_yellow.vpcf", PATTACH_ABSORIGIN, parent)
    local duration = self:GetDuration()
    Timers:CreateTimer(duration, function()
      if burst then
        ParticleManager:DestroyParticle(burst, false)
        ParticleManager:ReleaseParticleIndex(burst)
      end
    end)

    return 1
  end

  function modifier_item_reflection_shard_active:GetModifierTotal_ConstantBlock(event)
    local ability = self:GetAbility()
    local attacker = event.attacker

    -- Check if attacker and ability exist
    if not attacker or attacker:IsNull() or not ability or ability:IsNull() then
      return 0
    end

    local dmg_after_reductions = event.damage
    local damage_category = event.damage_category

    -- Block only spell damage
    if damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then
      return 0
    end

    return dmg_after_reductions
  end
end

--[[
function modifier_item_reflection_shard_active:GetReflectSpell(kv)
  if IsServer() then
    local parent = self:GetParent()

    local ability_name = kv.ability:GetAbilityName()
    local target = kv.ability:GetCaster()
    local ability_level = kv.ability:GetLevel()
    local ability_behaviour = kv.ability:GetBehavior()
    if type(ability_behaviour) == 'userdata' then
      ability_behaviour = tonumber(tostring(ability_behaviour))
    end

    local exception_list = {
      ["rubick_spell_steal"] = true,
      ["morphling_replicate"] = true,
      ["grimstroke_soul_chain"] = true,
      ["legion_commander_duel"] = true,
    }

    -- Do not reflect allied spells for any reason
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- If this is a reflected ability from other Reflection shard, do nothing
    -- (reflecting reflected spells should not be possible)
    if kv.ability.reflected_spell then
      return
    end

    local reflecting_modifiers = {
      "modifier_item_lotus_orb_active", -- Lotus Orb active
      "modifier_item_reflection_shard_active", -- Reflection Shard active
      "modifier_item_mirror_shield",    -- Mirror Shield
      "modifier_antimage_counterspell", -- Anti-Mage Counter Spell active
    }
    -- Check for reflecting modifiers
    local found = false
    for i = 1, #reflecting_modifiers do
      if target:HasModifier(reflecting_modifiers[i]) then
        found = true
        break
      end
    end

    -- If target has reflecting modifiers do nothing to prevent infinite loops
    -- (reflecting reflected spells should not be possible)
    if found then
      return
    end

    -- If ability is on the exception list do nothing
    if exception_list[ability_name] then
      return
    end

    -- If ability is channeling, dont reflect it because channeling abilities are buggy as hell
    if bit.band(ability_behaviour, DOTA_ABILITY_BEHAVIOR_CHANNELLED) == DOTA_ABILITY_BEHAVIOR_CHANNELLED then
      return
    end

    -- Check if the parent already has the reflected ability
    local old = false
    for _,ability in pairs(parent.stored_reflected_spells) do
      if ability and not ability:IsNull() then
        if ability:GetAbilityName() == ability_name then
          old = true
          break
        end
      end
    end

    -- Reflect Sound
    parent:EmitSound("Hero_Antimage.Counterspell.Target")

    -- Reflect particle
    local burst = ParticleManager:CreateParticle("particles/items/reflection_shard/immunity_sphere_yellow.vpcf", PATTACH_ABSORIGIN, parent)
    local duration = self:GetDuration()
    Timers:CreateTimer(duration, function()
      ParticleManager:DestroyParticle(burst, false)
      ParticleManager:ReleaseParticleIndex(burst)
    end)

    local reflect_ability
    local parent_ability
    if old then
      reflect_ability = parent:FindAbilityByName(ability_name)
    else
      parent_ability = parent:FindAbilityByName(ability_name)
      if parent_ability then
        -- This is a rare case (Rubick stole the spell and then casted that same spell on the target he stole it from and target has reflection shard buff)
        -- when parent already has the kv.ability naturally (it wasn't added or stolen), then it should not be stolen or hidden because that would mess up things
        -- We shouldn't duplicate abilities if the parent already has the kv.ability
        parent:SetCursorCastTarget(target) -- Set the target for the spell.
        parent_ability:OnSpellStart() -- Cast the spell back (to Rubick).
        return -- Don't do other stuff
      end
      reflect_ability = parent:AddAbility(ability_name) -- Add the spell to the parent for the first time
      if reflect_ability then
        reflect_ability:SetStolen(true) -- Just to be safe with some interactions.
        reflect_ability:SetHidden(true) -- Hide the ability on the parent.
        reflect_ability.reflected_spell = true  -- Tag this ability as reflected
        table.insert(parent.stored_reflected_spells, reflect_ability) -- Store the spell reference for future use.
      end
    end

    if not reflect_ability then
      -- If reflect_ability becomes nil for some reason, don't do other stuff
      --print("reflect_ability not found")
      return
    end

    reflect_ability:SetLevel(ability_level)       -- Set level to be the same as the level of the original ability
    parent:SetCursorCastTarget(target)            -- Set the target for the spell.
    reflect_ability:OnSpellStart()                -- Cast the spell.
  end
end
]]

function modifier_item_reflection_shard_active:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_item_reflection_shard_active:GetTexture()
  return "custom/reflection_shard_1"
end
