alchemist_chemical_rage_oaa = class(AbilityBaseClass)

function alchemist_chemical_rage_oaa:GetBehavior()
  local caster = self:GetCaster()
  -- Talent that allows casting while stunned
  local talent = caster:FindAbilityByName("special_bonus_unique_alchemist_1_oaa")
  if talent and talent:GetLevel() > 0 then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
  end

  return self.BaseClass.GetBehavior(self)
end

function alchemist_chemical_rage_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local ability = caster:FindAbilityByName("alchemist_chemical_rage")

  if not ability then
    ability = self
  end

  local remove_stuns = false
  -- Talent that applies Strong Dispel
  local talent = caster:FindAbilityByName("special_bonus_unique_alchemist_1_oaa")
	if talent and talent:GetLevel() > 0 then
    -- Strong Dispel
    remove_stuns = true
  end

  -- Basic Dispel (for caster, always) or Strong Dispel (with talent)
  caster:Purge(false, true, false, remove_stuns, remove_stuns)

  -- Disjoint disjointable/dodgeable projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- Sound
  caster:EmitSound("Hero_Alchemist.ChemicalRage.Cast")

  -- Applying the built-in modifier that controls the animations, sounds and body transformation.
  -- Applies modifier_alchemist_chemical_rage hopefully
  local transform_duration = self:GetSpecialValueFor("transformation_time")
  caster:AddNewModifier(caster, ability, "modifier_alchemist_chemical_rage_transform", {duration = transform_duration})
end

function alchemist_chemical_rage_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("alchemist_chemical_rage")

  -- Check to not enter a level up loop
  if vanilla_ability and vanilla_ability:GetLevel() ~= ability_level then
    vanilla_ability:SetLevel(ability_level)
  end
end

-- function alchemist_chemical_rage_oaa:GetAssociatedSecondaryAbilities()
  -- return "alchemist_chemical_rage"
-- end

-- function alchemist_chemical_rage_oaa:OnStolen(hSourceAbility)
  -- local caster = self:GetCaster()
  -- local vanilla_ability = caster:FindAbilityByName("alchemist_chemical_rage")
  -- if not vanilla_ability then
    -- return
  -- end
  -- vanilla_ability:SetHidden(true)
-- end

function alchemist_chemical_rage_oaa:ProcsMagicStick()
  return true
end
