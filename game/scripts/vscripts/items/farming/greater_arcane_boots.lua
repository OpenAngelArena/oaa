
item_greater_arcane_boots = class(ItemBaseClass)

function item_greater_arcane_boots:OnSpellStart()
  local caster = self:GetCaster()

  -- Prevent Meepo Clones from activating Greater Arcane Boots
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

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

    local particleManaGainName = "particles/items_fx/arcane_boots_recipient.vpcf"

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, hero, manaReplenishAmount, nil)

    local particleManaGain = ParticleManager:CreateParticle(particleManaGainName, PATTACH_ABSORIGIN_FOLLOW, hero)
    ParticleManager:SetParticleControl(particleManaGain, 1, hero:GetOrigin())
    ParticleManager:SetParticleControl(particleManaGain, 2, hero:GetOrigin())
    ParticleManager:ReleaseParticleIndex(particleManaGain)
  end

  foreach(ReplenishMana, heroes)

  local particleArcaneActivateName = "particles/items_fx/arcane_boots.vpcf"
  local particleArcaneActivate = ParticleManager:CreateParticle(particleArcaneActivateName, PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:ReleaseParticleIndex(particleArcaneActivate)

  caster:EmitSound("DOTA_Item.ArcaneBoots.Activate")
end

function item_greater_arcane_boots:GetIntrinsicModifierName()
  return "modifier_item_arcane_boots"
end

item_greater_arcane_boots_2 = class(item_greater_arcane_boots)
item_greater_arcane_boots_3 = class(item_greater_arcane_boots)
item_greater_arcane_boots_4 = class(item_greater_arcane_boots)
