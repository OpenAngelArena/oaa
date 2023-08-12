LinkLuaModifier("modifier_generic_dead_tracker_oaa", "modifiers/modifier_generic_dead_tracker_oaa.lua", LUA_MODIFIER_MOTION_NONE)

enigma_demonic_conversion_oaa = class(AbilityBaseClass)

-- Lazy hack to make shard work
function enigma_demonic_conversion_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("enigma_demonic_conversion")

  if not vanilla_ability then
    return
  end

  if vanilla_ability:GetLevel() == 4 or ability_level >= 5 then
    return
  end

  vanilla_ability:SetLevel(ability_level)
end

function enigma_demonic_conversion_oaa:OnSpellStart()
  --local target = self:GetCursorTarget()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local origin = caster:GetAbsOrigin() -- target:GetAbsOrigin()

  local spawnCount = self:GetSpecialValueFor("spawn_count")
  local splitAttackCount = self:GetSpecialValueFor("split_attack_count")
  local duration = self:GetSpecialValueFor("duration")
  local offset = self:GetSpecialValueFor("spawn_offset")
  local extend = self:GetSpecialValueFor("life_extension")

  -- Lookup table for Eidolon unit names for each level
  local unitNames = {
    "npc_dota_lesser_eidolon",
    "npc_dota_eidolon",
    "npc_dota_greater_eidolon",
    "npc_dota_dire_eidolon",
    "npc_dota_giant_eidolon",
    "npc_dota_colossal_eidolon"
  }

  -- Kill the target
  --target:Kill(self, caster)

  -- Directions
  local direction = caster:GetForwardVector()
  direction.z = 0.0
  direction = direction:Normalized()
  local perpendicular_direction = Vector(direction.y, -direction.x, 0.0)

  -- Spawn Eidolons
  for i = 1, spawnCount do
    -- 1 behind the caster, 1 left, 1 right
    local spawn_location = origin - direction * offset
    if i == 2 or i == 5 or i == 7 then
      spawn_location = origin - perpendicular_direction * offset
    elseif i == 3 or i == 6 or i == 8 then
      spawn_location = origin + perpendicular_direction * offset
    end

    local eidolon = CreateUnitByName(unitNames[self:GetLevel()], spawn_location, true, caster, caster:GetOwner(), caster:GetTeam())
    eidolon:SetControllableByPlayer(playerID, false)
    eidolon:SetOwner(caster)
    eidolon:SetForwardVector(direction)

    -- Use built-in modifier to handle summon duration and splitting and eidolon talents hopefully
    eidolon:AddNewModifier(caster, self, "modifier_demonic_conversion", {duration = duration, allowsplit = splitAttackCount})
    eidolon:AddNewModifier(caster, self, "modifier_phased", {duration = FrameTime()}) -- for unstucking
    eidolon:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = duration + extend + MANUAL_GARBAGE_CLEANING_TIME})
  end

  caster:EmitSound("Hero_Enigma.Demonic_Conversion")
end

--[[
function enigma_demonic_conversion_oaa:CastFilterResultTarget(target)
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  local lvlRequirement = self:GetSpecialValueFor("creep_level")

  if target:GetLevel() >= lvlRequirement then
    return UF_FAIL_CUSTOM
  end

  return defaultFilterResult
end

function enigma_demonic_conversion_oaa:GetCustomCastErrorTarget(target)
  return "#dota_hud_error_cant_cast_creep_level"
end
]]
function enigma_demonic_conversion_oaa:OnStolen(hSourceAbility)
  local caster = self:GetCaster()
  if caster:HasModifier("modifier_morphling_replicate_manager") then
    local vanilla_ability = caster:FindAbilityByName("enigma_demonic_conversion")
    if not vanilla_ability then
      print("MORPHLING MORPH: vanilla Demonic Conversion not found")
      Timers:CreateTimer(FrameTime(), function()
        vanilla_ability = caster:FindAbilityByName("pugna_nether_ward")
        if not vanilla_ability then
          print("MORPHLING MORPH: vanilla Demonic Conversion not found")
          return FrameTime() -- repeat until found
        else
          vanilla_ability:SetHidden(true)
        end
      end)
    else
      vanilla_ability:SetHidden(true)
    end
  end
end
