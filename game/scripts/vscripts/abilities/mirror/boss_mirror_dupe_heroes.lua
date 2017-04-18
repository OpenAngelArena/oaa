
require('internal/util')

LinkLuaModifier("modifier_boss_mirror_illusion", "abilities/mirror/boss_mirror_dupe_heroes.lua", LUA_MODIFIER_MOTION_NONE)


boss_mirror_dupe_heroes = class({})

function boss_mirror_dupe_heroes:GetAOERadius()
  	return self:GetSpecialValueFor('radius')
end

--[[
Credits: Pizzalol
]]
function boss_mirror_dupe_heroes:OnSpellStart()
  local caster = self:GetCaster()
  local target = caster:GetAbsOrigin()

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
    if unit:IsRealHero() and unit ~= caster then
      local illusion = CreateUnitByName(
        unit:GetName(),
        unit:GetAbsOrigin(),
        true,
        nil,
        nil,
        caster:GetTeamNumber()
      )

      -- Stats
      illusion:SetAttackCapability(unit:GetAttackCapability())
      illusion:SetMaximumGoldBounty(0)
      illusion:SetMinimumGoldBounty(0)
      illusion:SetDeathXP(0)
      illusion:SetRespawnsDisabled(true)

      -- TODO: Fix Stat Progression

      -- Level
      local target_level = unit:GetLevel()
      for i = 1, target_level - 1 do
        illusion:HeroLevelUp(false)
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
        "modifier_boss_mirror_illusion",
        {
          OutgoingDamage = self:GetSpecialValueFor('illusion_outgoing_damage'),
          IncomingDamage = self:GetSpecialValueFor('illusion_incoming_damage'),
        }
      )

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



modifier_boss_mirror_illusion = class({})

function modifier_boss_mirror_illusion:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_IS_ILLUSION,
  }
end

function modifier_boss_mirror_illusion:OnCreated(kv)
  local caster = self:GetCaster()

  self.OutgoingDamage = kv.OutgoingDamage
  self.IncomingDamage = kv.IncomingDamage
end

function modifier_boss_mirror_illusion:GetModifierDamageOutgoing_Percentage()
  return self.OutgoingDamage
end

function modifier_boss_mirror_illusion:GetModifierIncomingDamage_Percentage()
  return self.IncomingDamage
end

function modifier_boss_mirror_illusion:IsDebuff()
  return true
end

function modifier_boss_mirror_illusion:IsHidden()
  return false
end

function modifier_boss_mirror_illusion:GetIsIllusion()
  return true
end
