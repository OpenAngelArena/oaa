LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_manta_splitted", "items/manta.lua", LUA_MODIFIER_MOTION_NONE)

item_manta = class(ItemBaseClass)
item_manta_1 = item_manta
item_manta_2 = item_manta
item_manta_3 = item_manta
item_manta_4 = item_manta
item_manta_5 = item_manta

-- Has 30 seconds cooldown for melee heroes and 45 seconds cooldown for ranged heroes.
function item_manta:GetCooldown(level)
  local caster = self:GetCaster()
  if not caster:IsRangedAttacker() then
    -- Don't use GetLevelSpecialValueFor because for some reason that function doesn't exist on clientside
    return self:GetSpecialValueFor("cooldown_melee")
  else
    return self.BaseClass.GetCooldown(self, level)
  end
end

function item_manta:OnSpellStart()
  local caster = self:GetCaster()

  -- Disjoints projectiles upon cast.
  ProjectileManager:ProjectileDodge(caster)

  -- Applies a basic dispel on the owner upon cast.
  caster:Purge(false, true, false, false, false)

  -- Provides 1000 radius ground vision for a second upon cast.
  self:CreateVisibilityNode(caster:GetAbsOrigin(), self:GetSpecialValueFor("vision_radius"), self:GetSpecialValueFor("vision_duration"))

  -- TODO: Resets all current attack and spell targeting orders from other units on the owner.

  -- Sound
  caster:EmitSound("DOTA_Item.Manta.Activate")

  -- The user is invulnerable, hidden and spell immune during the split time.
  caster:AddNewModifier(caster, self, "modifier_item_manta_splitted", { duration = self:GetSpecialValueFor("invuln_duration") })

end

function item_manta:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

modifier_item_manta_splitted = class(ModifierBaseClass)

function modifier_item_manta_splitted:CheckState()
  return {
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true
  }
end

function modifier_item_manta_splitted:OnCreated()
  if IsServer() then
    local caster = self:GetCaster()
    self.particle = ParticleManager:CreateParticle("particles/items2_fx/manta_phase.vpcf", PATTACH_ABSORIGIN, caster)
  end
end

function modifier_item_manta_splitted:IsHidden()
  return true
end

function modifier_item_manta_splitted:IsDebuff()
  return false
end

function modifier_item_manta_splitted:IsPurgeable()
  return false
end

function modifier_item_manta_splitted:OnDestroy()
  if IsServer() then
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local playerID = caster:GetPlayerID()
    local teamID = caster:GetTeam()
    local forwardVector = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()

    local images_count = ability:GetSpecialValueFor("images_count")
    local image_outgoing_damage = ability:GetSpecialValueFor("damage_outgoing_melee_pct")
    local image_incoming_damage = ability:GetSpecialValueFor("damage_incoming_melee_pct")

    if caster:IsRangedAttacker() then
      image_outgoing_damage = ability:GetSpecialValueFor("damage_outgoing_ranged_pct")
      image_incoming_damage = ability:GetSpecialValueFor("damage_incoming_ranged_pct")
    end


    if ability.images == nil then
      ability.images = {}
    end

    -- Get Caster Position Index
    local casterIndex = RandomInt(1, images_count)

    -- Choose a random north, south, east, west position in the formation
    local imageOffset = RandomInt(1, 4)

    local function KillImage(image)
      if IsValidEntity(image) and image:IsAlive() then
        image:ForceKill(false)
      end
    end
    -- Kill illusions from previous cast
    foreach(KillImage, ability.images)

    -- Place Caster
    FindClearSpaceForUnit(caster, self.GetImageLocation(origin, casterIndex, true, casterIndex, imageOffset), true)

    --DebugDrawSphere(origin, Vector(255, 0, 0), 255, 256, true, 20)

    for imageIndex = 1,images_count do
    -- The formation of the owner and the illusions is always the same. One spawns on the owner's cast location and the others randomly on north, east, south or west side each.
    -- Though the formation is always the same, the owner and the illusions take a random position in the formation and have all the same facing angle.
      local position = self.GetImageLocation(origin, casterIndex, false, imageIndex, imageOffset)

      --DebugDrawLine(origin, position, 255, 0, 0, true, 20)

      local image = CreateUnitByName(
        caster:GetUnitName(),         --szUnitName
        position,                     --vLocation
        true,                         --bFindClearSpace
        caster,                       --hNPCOwner
        caster:GetPlayerOwner(),      --hUnitOwner
        teamID                        --iTeamNumber
      )

      image:MakeIllusion()  --Without MakeIllusion(), the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.  Without it, IsIllusion() returns false and IsRealHero() returns true.

      image:SetForwardVector(forwardVector)

      image:SetControllableByPlayer(playerID, true)

      --Level up the image to the caster's level.
      local level = caster:GetLevel()
      for i = 1, level - 1 do
        image:HeroLevelUp(false)
        HeroProgression:ReduceStatGain(image, i + 1)
      end

      --Set the image's available skill points to 0 and teach it the abilities the caster has.
      image:SetAbilityPoints(0)
      for abilityIndex = 0, caster:GetAbilityCount() - 1 do
        local casterAbility = caster:GetAbilityByIndex(abilityIndex)
        if casterAbility ~= nil then
          local imageAbility = image:FindAbilityByName(casterAbility:GetAbilityName())
          local casterAbilityLevel = casterAbility:GetLevel()
          if imageAbility ~= nil and casterAbilityLevel > 0 then
            imageAbility:SetLevel(casterAbility:GetLevel())
          end
        end
      end

      -- Note: Does not copy duration or other internal data of modifiers
      -- Primarily for copying Invoker orb modifiers
      local function CopyModifiers(modifierName, abilityName)
        local numberOfInstances = #caster:FindAllModifiersByName(modifierName)
        for i=1,numberOfInstances do
          image:AddNewModifier(image, image:FindAbilityByName(abilityName), modifierName, {})
        end
      end
      -- Copy Invoker's orbs to image
      if caster:GetUnitName() == "npc_dota_hero_invoker" then
        local modifierNames = {
          "modifier_invoker_quas_instance",
          "modifier_invoker_wex_instance",
          "modifier_invoker_exort_instance"
        }
        local abilityNames = {
          "invoker_quas",
          "invoker_wex",
          "invoker_exort"
        }
        foreach(CopyModifiers, zip(modifierNames, abilityNames))
      end

      -- Remove the TP scroll Dota puts in newly spawned heroes' inventory
      image:RemoveItem(image:GetItemInSlot(DOTA_ITEM_SLOT_1))

      --Recreate the caster's items for the image.
      for itemSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
        local casterItem = caster:GetItemInSlot(itemSlot)
        if casterItem ~= nil then
          -- Temporarily remove the item in the first slot so we know where the new item will get placed in inventory
          local firstSlotItem = image:TakeItem(image:GetItemInSlot(DOTA_ITEM_SLOT_1))
          local imageItem = image:AddItemByName(casterItem:GetName())
          -- Move item to proper slot
          image:SwapItems(DOTA_ITEM_SLOT_1, itemSlot)
          if imageItem:RequiresCharges() then
            imageItem:SetCurrentCharges(casterItem:GetCurrentCharges())
          end
          image:AddItem(firstSlotItem)
        end
      end

      -- Set Status
      image:SetHealth(caster:GetHealth())
      image:SetMana(caster:GetMana())

      -- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
      image:AddNewModifier(caster, ability, "modifier_illusion", {
        duration = ability:GetSpecialValueFor("illusion_duration"),
        outgoing_damage = image_outgoing_damage,
        incoming_damage = image_incoming_damage
      })

      image:OnDeath(function()
        image:RemoveSelf()
        image:Destroy()
      end)

      ability.images[imageIndex] = image
    end

    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)

    -- Manta Style End
    caster:EmitSound("DOTA_Item.Manta.End")
  end
end

-- Vector GetImageLocation(Vector origin, Integer blockedIndex, Boolean ignoreBlock, Integer imageIndex, Integer startOffset)
function modifier_item_manta_splitted.GetImageLocation(origin, blockedIndex, ignoreBlock, imageIndex, startOffset)
  --[[
  1: Position of Caster
  ]]

  if not ignoreBlock and imageIndex >= blockedIndex then
    imageIndex = imageIndex + 1
  end

  if imageIndex == 1 then
    return origin
  end

  local distance = 100
  local theta = (2*math.pi / 4) * (startOffset + imageIndex)
  --print(theta .. " = (360 / " .. imageCount .. ") * (" .. imageIndex .. " - 1)")

  return origin + Vector(math.cos(theta), math.sin(theta)) * distance
end
