modifier_sorcerer_oaa = class(ModifierBaseClass)

function modifier_sorcerer_oaa:IsHidden()
  return false
end

function modifier_sorcerer_oaa:IsDebuff()
  return false
end

function modifier_sorcerer_oaa:IsPurgable()
  return false
end

function modifier_sorcerer_oaa:RemoveOnDeath()
  return false
end

function modifier_sorcerer_oaa:OnCreated()
  self.chance_for_abilities_on_cast = 25
  self.chance_for_abilities_on_kill = 25
  self.chance_for_charge_based_abilities = 5
  self.chance_for_items_on_use = 2
  self.chance_for_items_on_kill = 2

  -- Put ability exemption in here
  self.exempt_ability_table = {
    --dazzle_good_juju = true,
    riki_permanent_invisibility = true,
    tinker_rearm = true,
    treant_natures_guise = true
  }

  -- Put item exemption in here
  self.exempt_item_table = {
    item_ex_machina = true,
    item_refresher_shard_oaa = true,
    item_tranquil_boots = true,
    item_hand_of_midas_1 = true,
    item_refresher = true,
    item_refresher_2 = true,
    item_refresher_3 = true,
    item_refresher_4 = true,
    item_refresher_5 = true,
  }
end

function modifier_sorcerer_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    MODIFIER_EVENT_ON_HERO_KILLED,
  }
end

if IsServer() then
  function modifier_sorcerer_oaa:OnAbilityFullyCast(event)
    local parent = self:GetParent()
    local unit = event.unit
    local ability = event.ability

    -- Check if caster unit exists
    if not unit or unit:IsNull() then
      return
    end

    -- Check if caster unit has this modifier
    if unit ~= parent then
      return
    end

    -- Check if caster is alive
    if not parent:IsAlive() then
      return
    end

    -- Check if used ability exists
    if not ability or ability:IsNull() then
      return
    end

    -- Check if used ability is refreshable
    if not ability:IsRefreshable() then
      return
    end

    local chance = self.chance_for_abilities_on_cast
    local no_charges = true
    if ability:IsItem() then
      chance = self.chance_for_items_on_use
    else
      local level = ability:GetLevel()
      no_charges = (ability:GetMaxAbilityCharges(level) == 0) or (ability:GetMaxAbilityCharges(level) == 1)
      if not no_charges then
        chance = self.chance_for_charge_based_abilities
      end
    end

    if RandomInt(1, 100) <= chance then
      if not no_charges then
        ability:RefreshCharges()
      end
      ability:EndCooldown()
    end
  end

  function modifier_sorcerer_oaa:OnHeroKilled(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local target = event.target

    -- Check if killer exists
    if not killer or killer:IsNull() then
      return
    end

    -- Don't continue if the killer doesn't belong to the parent
    if UnitVarToPlayerID(killer) ~= UnitVarToPlayerID(parent) then
      return
    end

    -- Ignore self denies and allies
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Don't trigger on Meepo Clones, Tempest Doubles and Spirit Bears
    if target:IsClone() or target:IsTempestDouble() or target:IsSpiritBearOAA() then
      return
    end

    -- Check if parent is dead
    if not parent:IsAlive() then
      return
    end

    if RandomInt(1, 100) <= self.chance_for_abilities_on_kill then
      -- Reset cooldown for abilities
      for i = 0, parent:GetAbilityCount() - 1 do
        local ability = parent:GetAbilityByIndex(i)
        if ability and not self.exempt_ability_table[ability:GetAbilityName()] and ability:IsRefreshable() then
          ability:RefreshCharges()
          ability:EndCooldown()
        end
      end

      -- Sound
      parent:EmitSound("DOTA_Item.Refresher.Activate")

      -- Particle
      local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, parent)
      ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
      ParticleManager:ReleaseParticleIndex(particle)
    end

    if RandomInt(1, 100) <= self.chance_for_items_on_kill then
      -- Reset cooldown for items
      for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        local item = parent:GetItemInSlot(i)
        if item and item:IsRefreshable() and not self.exempt_item_table[item:GetAbilityName()] then
          item:EndCooldown()
        end
      end

      -- Reset cooldown for items that are in backpack
      for j = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
        local backpack_item = parent:GetItemInSlot(j)
        if backpack_item and not self.exempt_item_table[backpack_item:GetAbilityName()] then
          backpack_item:EndCooldown()
        end
      end

      -- Reset TP scroll cooldown
      local tp_scroll = parent:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
      if tp_scroll and tp_scroll:GetName() == "item_tpscroll" then
        tp_scroll:EndCooldown()
      end

      -- Reset neutral item cooldown
      local neutral_item = parent:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
      if neutral_item and neutral_item:IsActiveNeutral() and not self.exempt_item_table[neutral_item:GetAbilityName()] then
        neutral_item:EndCooldown()
      end
    end
  end
end

function modifier_sorcerer_oaa:GetTexture()
  return "item_ex_machina"
end
