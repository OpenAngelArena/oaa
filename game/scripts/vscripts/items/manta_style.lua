LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_illusion", LUA_MODIFIER_MOTION_NONE)

manta_style = class(ItemBaseClass)
manta_style_2 = manta_style
manta_style_3 = manta_style
manta_style_4 = manta_style
manta_style_5 = manta_style

function manta_style:OnSpellStart()
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

  -- The user is invulnerable, hidden and spell immune during the split time.
  caster:AddNewModifier(caster, self, "modifier_manta_style_splitted", { duration = GetSpecialValueFor("invuln_duration") })

end

modifier_manta_style_splitted = class(ModifierBaseClass)

function modifier_manta_style_splitted:OnDestroy()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local teamID = caster:GetTeam()

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

  for imageIndex = 0,images_count do
    local image = ability.images[imageIndex]

  -- The formation of the owner and the illusions is always the same. One spawns on the owner's cast location and the others randomly on north, east, south or west side each.
  -- Though the formation is always the same, the owner and the illusions take a random position in the formation and have all the same facing angle.
    local position = GetImageLocation(caster, imageIndex)

  -- Recasting this replaces the illusions from the previous cast which are currently under the owner's control.
    if image ~= nil then
      if image:IsAlive() then
        position = image:GetAbsOrigin()
        image:ForceKill(false)
        image = nil
      end
    end

    image = CreateUnitByName(
      caster:GetUnitName(), --szUnitName
      position,             --vLocation
      true,                 --bFindClearSpace
      caster,               --hNPCOwner
      nil,                  --hUnitOwner
      teamID                --iTeamNumber
    )

    image:SetPlayerID(playerID)
    image:SetControllableByPlayer(playerID, true)

    --Level up the image to the caster's level.
    local caster_level = keys.caster:GetLevel()
    for i = 1, caster_level - 1 do
      image:HeroLevelUp(false)
    end

    --Set the image's available skill points to 0 and teach it the abilities the caster has.
    image:SetAbilityPoints(0)
    for abilityIndex = 0, 15 do
      local casterAbility = keys.caster:GetAbilityByIndex(abilityIndex)
      if casterAbility ~= nil then
        local imageAbility = image:FindAbilityByName(casterAbility:GetAbilityName())
        if imageAbility ~= nil then
          imageAbility:SetLevel(casterAbility:GetLevel())
        end
      end
    end

    --Recreate the caster's items for the image.
    for itemSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_5 do
      local casterItem = keys.caster:GetItemInSlot(itemSlot)
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
      duration = abilitiy:GetSpecialValueFor("illusion_duration"),
      outgoing_damage = image_outgoing_damage,
      incoming_damage = image_incoming_damage
    })

    image:MakeIllusion()  --Without MakeIllusion(), the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.  Without it, IsIllusion() returns false and IsRealHero() returns true.
  end
end
