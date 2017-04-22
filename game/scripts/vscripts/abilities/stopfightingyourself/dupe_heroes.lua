
require('libraries/timers')

LinkLuaModifier("modifier_boss_stopfightingyourself_illusion", "abilities/stopfightingyourself/dupe_heroes.lua", LUA_MODIFIER_MOTION_NONE)


boss_stopfightingyourself_dupe_heroes = class({})

function boss_stopfightingyourself_dupe_heroes:GetAOERadius()
  	return self:GetSpecialValueFor('radius')
end

--[[
Credits: Pizzalol
]]
function boss_stopfightingyourself_dupe_heroes:OnSpellStart()
  local caster = self:GetCaster()
  local target = caster:GetAbsOrigin()

  if caster.illusions and #caster.illusions >= self:GetSpecialValueFor('max_illusions') then
    return
  end

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
    if unit:IsRealHero() and unit ~= caster then
      self:StartCooldown(self:GetSpecialValueFor('cooldown'))

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
          local ourItem = illusion:AddItemByName(theirItem:GetAbilityName())

          if ourItem:RequiresCharges() then
            local charges = theirItem:GetCurrentCharges()
            ourItem:SetCurrentCharges(charges)
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

      --illusion:MakeIllusion()

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
      if math.random(100) <= 10 then
        EmitAnnouncerSoundForPlayer('sounds/vo/announcer_dlc_rick_and_morty/generic_illusion_based_hero_02.vsnd', unit:GetPlayerID())
      end

      if caster.illusions == nil then
        caster.illusions = {}
      end
      local index = #caster.illusions + 1
      caster.illusions[index] = illusion

      illusion:OnDeath(function()
        -- create particle
        -- NOTE I have yet to see those particles
        Timer:CreateTimer(0.8, function()
          ParticleManager:CreateParticle('particles/generic_gameplay/illusion_killed.vpcf', PATTACH_ABSORIGIN, illusion)
        end)
        illusion:RemoveSelf()
        caster.illusions[index] = nil
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
