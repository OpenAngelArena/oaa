LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_illusion", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_manta_splitted", "items/manta.lua", LUA_MODIFIER_MOTION_NONE)

item_manta = class(ItemBaseClass)
item_manta_2 = item_manta
item_manta_3 = item_manta
item_manta_4 = item_manta
item_manta_5 = item_manta

function item_manta:OnSpellStart()
  local caster = self:GetCaster()

  -- Has 30 seconds cooldown for melee heroes and 45 seconds cooldown for ranged heroes.
  if not caster:IsRangedAttacker() then
    self:EndCooldown()
    self:StartCooldown(self:GetSpecialValueFor("cooldown_melee"))
  end

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
  self.particle = ParticleManager:CreateParticle("particles/items2_fx/manta_phase.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
  ParticleManager:SetParticleControl(self.particle, 0, self:GetCaster():GetAbsOrigin())
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
    local image_outgoing_damage = ability:GetSpecialValueFor("damage_outgoing_melee")
    local image_incoming_damage = ability:GetSpecialValueFor("damage_incoming_melee")

    if caster:IsRangedAttacker() then
      image_outgoing_damage = ability:GetSpecialValueFor("damage_outgoing_ranged")
      image_incoming_damage = ability:GetSpecialValueFor("damage_incoming_ranged")
    end


    if ability.images == nil then
      ability.images = {}
    end

    -- Get Caster Position Index
    local casterIndex = RandomInt(1, images_count)

    -- Place Caster
    FindClearSpaceForUnit(caster, GetImageLocation(caster:GetAbsOrigin(), casterIndex, true, casterIndex, images_count), true)

    --DebugDrawSphere(origin, Vector(255, 0, 0), 255, 360, true, 20)

    for imageIndex = 0,images_count do
      local image = ability.images[imageIndex]

    -- The formation of the owner and the illusions is always the same. One spawns on the owner's cast location and the others randomly on north, east, south or west side each.
    -- Though the formation is always the same, the owner and the illusions take a random position in the formation and have all the same facing angle.
      local position = GetImageLocation(origin, casterIndex, false, imageIndex, images_count)

    -- Recasting this replaces the illusions from the previous cast which are currently under the owner's control.
      if image ~= nil and IsValidEntity(image) then
        if image:IsAlive() then
          image:ForceKill(false)
        end
      end

      --DebugDrawLine(origin, position, 255, 0, 0, true, 20)

      image = CreateUnitByName(
        caster:GetUnitName(), --szUnitName
        position,             --vLocation
        true,                 --bFindClearSpace
        caster,               --hNPCOwner
        nil,                  --hUnitOwner
        teamID                --iTeamNumber
      )

      image:SetForwardVector(forwardVector)

      image:SetPlayerID(playerID)
      image:SetControllableByPlayer(playerID, true)

      --Level up the image to the caster's level.
      local level = caster:GetLevel()
      for i = 1, level - 1 do
        image:HeroLevelUp(false)
      end

      --Set the image's available skill points to 0 and teach it the abilities the caster has.
      image:SetAbilityPoints(0)
      for abilityIndex = 0, 15 do
        local casterAbility = caster:GetAbilityByIndex(abilityIndex)
        if casterAbility ~= nil then
          local imageAbility = image:FindAbilityByName(casterAbility:GetAbilityName())
          if imageAbility ~= nil then
            imageAbility:SetLevel(casterAbility:GetLevel())
          end
        end
      end

      --Recreate the caster's items for the image.
      for itemSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_5 do
        local casterItem = caster:GetItemInSlot(itemSlot)
        if casterItem ~= nil then
          local imageItem = CreateItem(casterItem:GetName(), image, image)
          image:AddItem(imageItem)
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

      image:MakeIllusion()  --Without MakeIllusion(), the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.  Without it, IsIllusion() returns false and IsRealHero() returns true.

      ability.images[imageIndex] = image
    end

    -- Allow Render of Caster
    caster:RemoveNoDraw()

    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)

    -- Manta Style End
    caster:EmitSound("DOTA_Item.Manta.End")
  end
end

-- Vector GetImageLocation(Vector origin, Integer blockedIndex, Boolean ignoreBlock, Integer imageIndex, Integer imageCount)
function GetImageLocation(origin, blockedIndex, ignoreBlock, imageIndex, imageCount)
  --[[
  0: Position of Caster
  ]]

  if imageIndex == 0 then
    return origin
  end

  if imageIndex >= blockedIndex then
    if not ignoreBlock then
      imageIndex = imageIndex + 1
    end
  end

  local distance = 128
  local theta = (360 / (imageCount - 1)) * imageIndex

  return origin + Vector(math.cos(theta), math.sin(theta)) * distance
end
