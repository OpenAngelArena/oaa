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
  local target = self:GetCursorTarget()
  local targetOrigin = target:GetOrigin()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local duration = self:GetDuration()
  local abilityLevel = self:GetLevel()
  local spawnCount = self:GetSpecialValueFor("spawn_count")
  local splitAttackCount = self:GetSpecialValueFor("split_attack_count")
  -- Lookup table for Eidolon unit names for each level
  local unitNames = {
    "npc_dota_lesser_eidolon",
    "npc_dota_eidolon",
    "npc_dota_greater_eidolon",
    "npc_dota_dire_eidolon",
    "npc_dota_giant_eidolon",
    "npc_dota_colossal_eidolon"
  }

  -- Check whether the caster has learnt the extra eidolons talent
  local casterHasExtraEidolons = caster:HasLearnedAbility("special_bonus_unique_enigma")

  -- Grant extra ediolon spawns from talent
  if casterHasExtraEidolons then
    spawnCount = spawnCount + caster:FindAbilityByName("special_bonus_unique_enigma"):GetSpecialValueFor("value")
  end

  -- Kill the target and spawn Eidolons
  target:Kill(self, caster)
  for i = 1,spawnCount do
    local eidolon = CreateUnitByName(unitNames[abilityLevel], targetOrigin, true, caster, caster:GetOwner(), caster:GetTeam())
    eidolon:SetControllableByPlayer(playerID, false)
    eidolon:SetOwner(caster)

    -- Use built-in modifier to handle summon duration and splitting and eidolon talents hopefully
    eidolon:AddNewModifier(caster, self, "modifier_demonic_conversion", {duration = duration, allowsplit = splitAttackCount})
  end

  target:EmitSound("Hero_Enigma.Demonic_Conversion")
end

-- Runs on client side first
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
