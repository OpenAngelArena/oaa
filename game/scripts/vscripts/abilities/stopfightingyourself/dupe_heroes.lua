
require('libraries/timers')

LinkLuaModifier("modifier_boss_stopfightingyourself_illusion", "abilities/stopfightingyourself/dupe_heroes.lua", LUA_MODIFIER_MOTION_NONE)


boss_stopfightingyourself_dupe_heroes = class(AbilityBaseClass)

function boss_stopfightingyourself_dupe_heroes:GetAOERadius()
  return self:GetSpecialValueFor('radius')
end

function boss_stopfightingyourself_dupe_heroes:GetCooldown(level)
  return self:GetSpecialValueFor('cooldown')
end

function boss_stopfightingyourself_dupe_heroes:CastFilterResult()
  local caster = self:GetCaster()
  local target = caster:GetAbsOrigin()

  for _,unit in ipairs(FindUnitsInRadius(
    caster:GetTeamNumber(),
    target,
    nil,
    self:GetSpecialValueFor('radius'),
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    self:GetAbilityTargetFlags(),
    FIND_ANY_ORDER,
    false
  )) do
    if unit:IsRealHero() then return true end
  end
  return false
end

--[[
Credits: Pizzalol
]]
function boss_stopfightingyourself_dupe_heroes:OnSpellStart()
  local caster = self:GetCaster()
  local target = caster:GetAbsOrigin()
  local blacklist = {
    "item_rapier"
  }

  self:StartCooldown(self:GetSpecialValueFor('cooldown'))

  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    target,
    nil,
    self:GetSpecialValueFor('radius'),
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    self:GetAbilityTargetFlags(),
    FIND_ANY_ORDER,
    false
  )

  for _,unit in ipairs(units) do
    if unit:IsRealHero() then
      -- Check if illusion cap has been reached
      if caster.illusions and caster.illusions.count >= self:GetSpecialValueFor('max_illusions') then
        return
      end

      local illusion = CreateUnitByName(
        unit:GetName(),
        unit:GetAbsOrigin(),
        true,
        caster,
        caster,
        --nil,
        --nil,
        caster:GetTeamNumber()
      )

      -- Level
      local target_level = unit:GetLevel()
      for i = 1, target_level - 1 do
        illusion:HeroLevelUp(false)
        HeroProgression:ReduceStatGain(illusion, i)
      end

      illusion:SetAbilityPoints(0)

      -- Abilities
      for slot = 0, 15 do
        local theirAbility = unit:GetAbilityByIndex(slot)

        if theirAbility then
          local ourAbility = illusion:FindAbilityByName(theirAbility:GetAbilityName())
          if ourAbility then
            ourAbility:SetLevel(theirAbility:GetLevel())
          end
        end
      end


      -- Items
      for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        local theirItem = unit:GetItemInSlot(slot)

        if theirItem then
          if not contains(theirItem:GetName(), blacklist) then
            local ourItem = illusion:AddItemByName(theirItem:GetAbilityName())

            if ourItem:RequiresCharges() then
              local charges = theirItem:GetCurrentCharges()
              ourItem:SetCurrentCharges(charges)
            end
          end
        end
      end


      -- Illusion Modifier
      illusion:AddNewModifier(
        caster,
        self,
        "modifier_illusion",
        {
          duration = -1,
          outgoing_damage = self:GetSpecialValueFor('illusion_outgoing_damage'),
          incoming_damage = self:GetSpecialValueFor('illusion_incoming_damage'),
        }
      )

      illusion:MakeIllusion()

      -- Stats
      -- BUG Gold bounty does not work
      -- NOTE XP probably too
      illusion:SetMaximumGoldBounty(0)
      illusion:SetMinimumGoldBounty(0)
      illusion:SetDeathXP(0)
      illusion:SetRespawnsDisabled(true)

      -- Set Stats to original hero
      illusion:SetHealth(unit:GetHealth())
      illusion:SetMana(unit:GetMana())

      -- Randomly play sound to player (10% chance)
      -- NOTE this doesn't seem to work
      if RandomFloat(0, 1) < 0.1 then
        --EmitAnnouncerSoundForPlayer('sounds/vo/announcer_dlc_rick_and_morty/generic_illusion_based_hero_02.vsnd', unit:GetPlayerID())
        illusion:EmitSound('sounds/vo/announcer_dlc_rick_and_morty/generic_illusion_based_hero_02.vsnd')
      end

      if caster.illusions == nil then
        caster.illusions = {
          count = 0
        }
      end
      caster.illusions[illusion:entindex()] = illusion
      caster.illusions.count = caster.illusions.count + 1

      illusion:OnDeath(function()
        -- create particle
        Timers:CreateTimer(0.1, function()
          local particle = ParticleManager:CreateParticle('particles/generic_gameplay/illusion_killed.vpcf', PATTACH_ABSORIGIN, illusion)
          ParticleManager:ReleaseParticleIndex(particle)
        end)
        caster.illusions[illusion:entindex()]:RemoveSelf()
        caster.illusions[illusion:entindex()] = nil
        caster.illusions.count = caster.illusions.count - 1
        illusion:Destroy()
      end)

      --illusion:SetContextThink('IllusionThink', ...)
      ExecuteOrderFromTable({
        UnitIndex = illusion:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
        TargetIndex = unit:entindex()
      })
    end
  end
end
