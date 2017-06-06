LinkLuaModifier( "modifier_creep_assist_gold", "items/farming/modifier_creep_assist_gold.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )

item_greater_arcane_boots = class({})

function item_greater_arcane_boots:OnSpellStart()
  local caster = self:GetCaster()

  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    self:GetSpecialValueFor("replenish_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MANA_ONLY,
    FIND_ANY_ORDER,
    false
  )

  local function ReplenishMana(hero)
    local manaReplenishAmount = self:GetSpecialValueFor("replenish_amount")
    hero:GiveMana(manaReplenishAmount)

    local particleManaNumberName = "particles/msg_fx/msg_mana_add.vpcf"
    local particleManaGainName = "particles/items_fx/arcane_boots_recipient.vpcf"

    local particleManaNumberCaster = ParticleManager:CreateParticleForPlayer(particleManaNumberName, PATTACH_CUSTOMORIGIN, caster, caster:GetPlayerOwner())
    ParticleManager:SetParticleControl(particleManaNumberCaster, 0, hero:GetOrigin() + Vector(0, 0, 125))
    -- x-value controls prefix symbol, y-value controls number to show, z-value controls suffix value
    ParticleManager:SetParticleControl(particleManaNumberCaster, 1, Vector(0, manaReplenishAmount, 0))
    -- x-value controls duration, y-value controls number of characters to show, z-value doesn't seem to have an effect
    ParticleManager:SetParticleControl(particleManaNumberCaster, 2, Vector(1.5, #tostring(manaReplenishAmount) + 1, 0))
    -- xyz is color in RGB values
    ParticleManager:SetParticleControl(particleManaNumberCaster, 3, Vector(17, 180, 233))
    ParticleManager:ReleaseParticleIndex(particleManaNumberCaster)

    if hero ~= caster then
      local particleManaNumberRecipient = ParticleManager:CreateParticleForPlayer(particleManaNumberName, PATTACH_CUSTOMORIGIN, caster, hero:GetPlayerOwner())
      ParticleManager:SetParticleControl(particleManaNumberRecipient, 0, hero:GetOrigin() + Vector(0, 0, 125))
      -- x-value controls prefix symbol, y-value controls number to show, z-value controls suffix value
      ParticleManager:SetParticleControl(particleManaNumberRecipient, 1, Vector(0, manaReplenishAmount, 0))
      -- x-value controls duration, y-value controls number of characters to show, z-value doesn't seem to have an effect
      ParticleManager:SetParticleControl(particleManaNumberRecipient, 2, Vector(1.5, #tostring(manaReplenishAmount) + 1, 0))
      -- xyz is color in RGB values
      ParticleManager:SetParticleControl(particleManaNumberRecipient, 3, Vector(17, 180, 233))
      ParticleManager:ReleaseParticleIndex(particleManaNumberRecipient)
    end

    local particleManaGain = ParticleManager:CreateParticle(particleManaGainName, PATTACH_ABSORIGIN_FOLLOW, hero)
    ParticleManager:SetParticleControl(particleManaGain, 1, hero:GetOrigin())
    ParticleManager:SetParticleControl(particleManaGain, 2, hero:GetOrigin())
    ParticleManager:ReleaseParticleIndex(particleManaGain)
  end

  foreach(ReplenishMana, heroes)

  local particleArcaneActivateName = "particles/items_fx/arcane_boots.vpcf"
  local particleArcaneActivate = ParticleManager:CreateParticle(particleArcaneActivateName, PATTACH_ABSORIGIN_FOLLOW, caster)

  EmitSoundOn("DOTA_Item.ArcaneBoots.Activate", caster)
end

function item_greater_arcane_boots:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_greater_arcane_boots:GetIntrinsicModifierNames()
  return {
    "modifier_item_arcane_boots",
    "modifier_creep_assist_gold"
  }
end

item_greater_arcane_boots_2 = class(item_greater_arcane_boots)
item_greater_arcane_boots_3 = class(item_greater_arcane_boots)
item_greater_arcane_boots_4 = class(item_greater_arcane_boots)
item_greater_arcane_boots_5 = class(item_greater_arcane_boots)
