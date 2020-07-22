
visage_summon_familiars_oaa = class(AbilityBaseClass)

function visage_summon_familiars_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local playerID = caster:GetPlayerID()
  local abilityLevel = self:GetLevel()

  if caster.familiars == nil then
    caster.familiars = {}
  end

  -- Kill non-dead familiars created with previous cast of this spell
  for _, v in pairs(caster.familiars) do
    if v and not v:IsNull() then
      if v:IsAlive() then
        v:ForceKill(false)
      end
    end
  end

  local baseUnitName = "npc_dota_visage_familiar"
  local levelUnitName = baseUnitName .. abilityLevel
  local number_of_familiars = self:GetSpecialValueFor("total_familiars")

  if caster:HasScepter() then
    number_of_familiars = self:GetSpecialValueFor("scepter_total_familiars")
  end

  -- Talent that increases number of familiars
	local talent = caster:FindAbilityByName("special_bonus_unique_visage_6")
	if talent then
		if talent:GetLevel() > 0 then
			number_of_familiars = number_of_familiars + talent:GetSpecialValueFor("value")
		end
	end

  for i = 1, number_of_familiars do
    local familiar = self:SpawnUnit(levelUnitName, caster, playerID, false)

    -- Level the familiar's stone form ability to match ability level
    local stoneFormAbility = familiar:FindAbilityByName("visage_summon_familiars_stone_form")
    if stoneFormAbility then
      stoneFormAbility:SetLevel(abilityLevel)
    end

    -- modifier_visage_summon_familiars_damage_charge

    -- Create particle effects
    --local particleName = ".vpcf"
    --local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
    --ParticleManager:SetParticleControl(particle, 0, unit:GetOrigin())
    --ParticleManager:ReleaseParticleIndex(particle)

    -- Store familiars on the caster handle
    table.insert(caster.familiars, familiar)
  end
  -- Sound
  caster:EmitSound("Hero_Visage.SummonFamiliars.Cast")
end

function visage_summon_familiars_oaa:OnUpgrade()
  local abilityLevel = self:GetLevel()
  local self_cast_ability = self:GetCaster():FindAbilityByName("visage_stone_form_self_cast")

  -- Check to not enter a level up loop
  if self_cast_ability and self_cast_ability:GetLevel() ~= abilityLevel then
    self_cast_ability:SetLevel(abilityLevel)
  end
end

-- Copied and modified from Beastmaster Call of the Wild Boar and Hawk
function visage_summon_familiars_oaa:SpawnUnit(levelUnitName, caster, playerID, bRandomPosition)
  local position = caster:GetOrigin()

  if bRandomPosition then
    position = position + RandomVector(1):Normalized() * RandomFloat(50, 100)
  end

  local npcCreep = CreateUnitByName(levelUnitName, position, true, caster, caster:GetOwner(), caster:GetTeam())
  npcCreep:SetControllableByPlayer(playerID, false)
  npcCreep:SetOwner(caster)
  npcCreep:SetForwardVector(caster:GetForwardVector())

  return npcCreep
end
