
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

      -- Stats
      illusion:SetMaximumGoldBounty(0)
      illusion:SetMinimumGoldBounty(0)
      illusion:SetDeathXP(0)
      illusion:SetRespawnsDisabled(true)

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
          OutgoingDamage = self:GetSpecialValueFor('illusion_outgoing_damage'),
          IncomingDamage = self:GetSpecialValueFor('illusion_incoming_damage'),
        }
      )

      --illusion:MakeIllusion()

      -- Set Stats to original hero
      illusion:SetHealth(unit:GetHealth())
      illusion:SetMana(unit:GetMana())


      if caster.illusions == nil then
        caster.illusions = {}
      end
      table.insert(caster.illusions, illusion)


      --illusion:SetContextThink('IllusionThink')
      ExecuteOrderFromTable({
        UnitIndex = illusion:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
        TargetIndex = unit:entindex()
      })
    end
  end
end
