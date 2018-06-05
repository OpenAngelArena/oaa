LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_urn_of_sorcery", "items/urn_of_sorcery.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_urn_of_sorcery_heal", "items/urn_of_sorcery.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_urn_of_sorcery_damage", "items/urn_of_sorcery.lua", LUA_MODIFIER_MOTION_NONE )

item_urn_of_sorcery = class(ItemBaseClass)

function item_urn_of_sorcery:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_urn_of_sorcery:GetIntrinsicModifierNames()
  return {
    "modifier_item_mekansm",
    "modifier_item_urn_of_sorcery"
  }
end

function item_urn_of_sorcery:OnSpellStart()
  local caster = self:GetCaster()
  local casterTeam = caster:GetTeamNumber()
  local units = FindUnitsInRadius(
    casterTeam,
    caster:GetAbsOrigin(),
    nil,
    self:GetSpecialValueFor("soul_release_radius"),
    DOTA_UNIT_TARGET_TEAM_BOTH,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  local function ApplyHealModifier(unit)
    local healDuration = self:GetSpecialValueFor("soul_heal_duration")
    unit:AddNewModifier(caster, self, "modifier_item_urn_of_sorcery_heal", {duration = healDuration})
  end

  local function ApplyDamageModifier(unit)
    local damageDuration = self:GetSpecialValueFor("soul_damage_duration")
    unit:AddNewModifier(caster, self, "modifier_item_urn_of_sorcery_damage", {duration = damageDuration})
  end

  local function IsAlly(unit)
    return not unit:IsOpposingTeam(casterTeam)
  end

  local allyUnits, enemyUnits = partition(IsAlly, take_n(self:GetCurrentCharges(), units))

  foreach(ApplyHealModifier, allyUnits)
  foreach(ApplyDamageModifier, enemyUnits)

  caster:EmitSound("DOTA_Item.UrnOfShadows.Activate")

  self:SetCurrentCharges(0)
end

item_urn_of_sorcery_2 = item_urn_of_sorcery
item_urn_of_sorcery_3 = item_urn_of_sorcery
item_urn_of_sorcery_4 = item_urn_of_sorcery

--------------------------------------------------------------------------

modifier_item_urn_of_sorcery = class(ModifierBaseClass)

function modifier_item_urn_of_sorcery:IsHidden()
  return true
end

function modifier_item_urn_of_sorcery:IsPurgable()
  return false
end

function modifier_item_urn_of_sorcery:RemoveOnDeath()
  return false
end

function modifier_item_urn_of_sorcery:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_urn_of_sorcery:OnCreated()
  local ability = self:GetAbility()
  self.manaRegen = ability:GetSpecialValueFor("mana_regen")
  self.maxCharges = ability:GetSpecialValueFor("max_charges")
end

modifier_item_urn_of_sorcery.OnRefresh = modifier_item_urn_of_sorcery.OnCreated

-- modifier_item_mekansm is used for the passive Mek aura, but also applies armor and bonus stats to the owner
-- so this modifier only needs to apply the mana regen bonus
function modifier_item_urn_of_sorcery:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED
  }
end

function modifier_item_urn_of_sorcery:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor("mana_regen") or self.manaRegen
end

-- Add charges when abilities are cast by nearby visible enemies
function modifier_item_urn_of_sorcery:OnAbilityExecuted(keys)
  local parent = self:GetParent()
  local sorceryUrn = self:GetAbility()
  -- Only add charges for abilities cast by visible enemies
  local filterResult = UnitFilter(keys.unit,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER),
    bit.bor(DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS),
    parent:GetTeamNumber()
  )

  -- Only allow 1 Urn of Sorcery to gain charges
  local isFirstSorceryModifier = parent:FindModifierByName("modifier_item_urn_of_sorcery") == self

  local distanceToUnit = #(parent:GetAbsOrigin() - keys.unit:GetAbsOrigin())
  local unitIsInRange = distanceToUnit <= sorceryUrn:GetSpecialValueFor("charge_radius")
  local currentCharges = sorceryUrn:GetCurrentCharges()
  local maxCharges = sorceryUrn:GetSpecialValueFor("max_charges") or self.maxCharges

  if filterResult == UF_SUCCESS and isFirstSorceryModifier and keys.ability:ProcsMagicStick() and unitIsInRange and currentCharges < maxCharges then
    sorceryUrn:SetCurrentCharges(currentCharges + 1)
  end
end

--------------------------------------------------------------------------

modifier_item_urn_of_sorcery_heal = class(ModifierBaseClass)

function modifier_item_urn_of_sorcery_heal:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_item_urn_of_sorcery_heal:OnTakeDamage(keys)
  local parent = self:GetParent()
  if keys.damage > 0 and keys.unit == parent and PlayerResource:IsValidPlayerID(keys.attacker:GetPlayerOwnerID()) then
    self:Destroy()
  end
end

function modifier_item_urn_of_sorcery_heal:OnCreated()
  local ability = self:GetAbility()
  local healAmount = ability:GetSpecialValueFor("soul_heal_amount")
  local healDuration = ability:GetSpecialValueFor("soul_heal_duration")
  self.healPerSecond = healAmount / healDuration
end

modifier_item_urn_of_sorcery_heal.OnRefresh = modifier_item_urn_of_sorcery_heal.OnCreated

function modifier_item_urn_of_sorcery_heal:GetModifierConstantHealthRegen()
  return self.healPerSecond
end

function modifier_item_urn_of_sorcery_heal:GetEffectName()
  return "particles/items2_fx/urn_of_shadows_heal.vpcf"
end

function modifier_item_urn_of_sorcery_heal:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------

modifier_item_urn_of_sorcery_damage = class(ModifierBaseClass)

function modifier_item_urn_of_sorcery_damage:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_item_urn_of_sorcery_damage:OnTooltip()
  return self.damagePerSecond
end

if IsServer() then
  function modifier_item_urn_of_sorcery_damage:OnCreated()
    local ability = self:GetAbility()
    local damageAmount = ability:GetSpecialValueFor("soul_damage_amount")
    local damageDuration = ability:GetSpecialValueFor("soul_damage_duration")
    local tickRate = ability:GetSpecialValueFor("soul_damage_interval")
    self.damagePerSecond = damageAmount / damageDuration
    self.damagePerTick = self.damagePerSecond * tickRate

    self:StartIntervalThink(tickRate)
  end

  modifier_item_urn_of_sorcery_damage.OnRefresh = modifier_item_urn_of_sorcery_damage.OnCreated
end

function modifier_item_urn_of_sorcery_damage:OnIntervalThink()
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  local damageTable = {
    victim = parent,
    attacker = caster,
    damage = self.damagePerTick,
    damage_type = DAMAGE_TYPE_PURE,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = ability
  }

  ApplyDamage(damageTable)
end

function modifier_item_urn_of_sorcery_damage:GetEffectName()
  return "particles/items2_fx/urn_of_shadows_damage.vpcf"
end

function modifier_item_urn_of_sorcery_damage:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
