LinkLuaModifier("modifier_meepo_divided_we_stand_oaa", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_death", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)

meepo_divided_we_stand_oaa = class(AbilityBaseClass)

function meepo_divided_we_stand_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local PID = caster:GetPlayerOwnerID()
  local mainMeepo = PlayerResource:GetSelectedHeroEntity(PID)

  mainMeepo.meepoList = mainMeepo.meepoList or GetAllMeepos(mainMeepo)

  if caster ~= mainMeepo then
    return nil
  end

  -- Create a clone
  local newMeepo = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
  newMeepo:SetPlayerID(PID)
  newMeepo:SetControllableByPlayer(PID, false)
  newMeepo:SetOwner(caster:GetOwner())
  FindClearSpaceForUnit(newMeepo, caster:GetAbsOrigin(), false)

  -- Preventing dropping and selling items in inventory
  newMeepo:SetHasInventory(false)
  newMeepo:SetCanSellItems(false)
  -- Disabling bounties because clone can die
  newMeepo:SetMaximumGoldBounty(0)
  newMeepo:SetMinimumGoldBounty(0)
  newMeepo:SetDeathXP(0)

  newMeepo:AddNewModifier(caster, self, "modifier_meepo_divided_we_stand_oaa", {})

  table.insert(caster.meepoList, newMeepo)
end

---------------------------------------------------------------------------------------------------

modifier_meepo_divided_we_stand_oaa = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa:IsHidden()
	return true
end

function modifier_meepo_divided_we_stand_oaa:IsDebuff()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsPurgable()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsPermanent()
  return true
end

function modifier_meepo_divided_we_stand_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ORDER,
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_meepo_divided_we_stand_oaa:OnCreated(kv)
  if IsServer() then
    self:StartIntervalThink(0.5)
  end
end

function modifier_meepo_divided_we_stand_oaa:OnIntervalThink()
  local meepo = self:GetParent()
  local mainMeepo = self:GetCaster()
  -- Set stats the same as main meepo
  meepo.SetBaseStrength(meepo, mainMeepo.GetStrength(mainMeepo))
  meepo.SetBaseAgility(meepo ,mainMeepo.GetAgility(mainMeepo))
  meepo.SetBaseIntellect(meepo, mainMeepo.GetIntellect(mainMeepo))
  meepo:CalculateStatBonus(true)
  -- Set clone level the same as main meepo
  --while meepo.GetLevel(meepo) < mainMeepo.GetLevel(mainMeepo) do
    --meepo:AddExperience(10, DOTA_ModifyXP_Unspecified, false, false)
  --end

  -- Preventing clone from respawning
  --meepo:SetRespawnsDisabled(true)

  --LevelAbilitiesForAllMeepos(mainMeepo) -- This should be done only on the main meepo
end

function modifier_meepo_divided_we_stand_oaa:OnTakeDamage(keys)
  local mainMeepo = self:GetCaster()
  local parent = self:GetParent()
  if keys.unit==parent then
    if parent:GetHealth() <= 0 then
      if parent~=mainMeepo then
        local oldLocation = mainMeepo:GetAbsOrigin()
        mainMeepo:SetAbsOrigin(parent:GetAbsOrigin())
        mainMeepo:Kill(keys.inflictor,keys.attacker)
        mainMeepo:SetAbsOrigin(oldLocation)
        parent:SetHealth(parent:GetMaxHealth())
        Timers:CreateTimer(0.1, function()
          parent:AddNewModifier(mainMeepo,self:GetAbility(),"modifier_meepo_divided_we_stand_oaa_death",{})
        end)
      end
      for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
        if meepo~=mainMeepo then
          meepo:AddNewModifier(mainMeepo,self:GetAbility(),"modifier_meepo_divided_we_stand_oaa_death",{})
        end
      end
    end
  end
end

function modifier_meepo_divided_we_stand_oaa:OnRespawn(keys)
  local parent = self:GetParent()
  local mainMeepo = self:GetCaster()
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo~=mainMeepo then
      meepo:RemoveModifierByName("modifier_meepo_divided_we_stand_oaa_death")
      meepo:RemoveNoDraw()
      FindClearSpaceForUnit(meepo,mainMeepo:GetAbsOrigin(),true)
      meepo:AddNewModifier(meepo,self:GetAbility(),"modifier_phased",{["duration"]=0.1})
    end
  end
end

modifier_meepo_divided_we_stand_oaa_death = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_death:IsPermanent()
  return true
end

function modifier_meepo_divided_we_stand_oaa_death:IsHidden()
  return true
end

function modifier_meepo_divided_we_stand_oaa_death:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_death:IsDebuff()
	return false
end

function modifier_meepo_divided_we_stand_oaa_death:OnCreated()
  if IsServer() then
    self:GetParent():StartGesture(ACT_DOTA_DIE)
    self:StartIntervalThink(1.5)
  end
end

function modifier_meepo_divided_we_stand_oaa_death:OnIntervalThink()
  local parent = self:GetParent()
  parent:RemoveGesture(ACT_DOTA_DIE)
  parent:AddNoDraw()
  if parent:GetTeamNumber()==DOTA_TEAM_GOODGUYS then
      parent:SetAbsOrigin(Vector(-10000,-10000,0))
  else
      parent:SetAbsOrigin(Vector(10000,10000,0))
  end
  parent:SetHealth(parent:GetMaxHealth())
  parent:SetMana(parent:GetMaxMana())
  self:StartIntervalThink(-1)
end

function modifier_meepo_divided_we_stand_oaa_death:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
  }
end

function LevelAbilitiesForAllMeepos(unit)
  local PID = unit:GetPlayerOwnerID()
  local mainMeepo = PlayerResource:GetSelectedHeroEntity(PID)
  for a = 0, mainMeepo:GetAbilityCount() - 1 do
    local ability = mainMeepo:GetAbilityByIndex(a)
    if ability then
      for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
        if meepo ~= mainMeepo then
          local cloneAbility = meepo:FindAbilityByName(ability:GetAbilityName())
          if ability:GetLevel() > cloneAbility:GetLevel() then
            cloneAbility:SetLevel(ability:GetLevel())
          elseif ability:GetLevel() < cloneAbility:GetLevel() then
            ability:SetLevel(cloneAbility:GetLevel())
            --mainMeepo:SetAbilityPoints(mainMeepo:GetAbilityPoints()-1)
          end
        end
      end
    end
  end
  for _, meepo in pairs(GetAllMeepos(mainMeepo)) do
    if meepo ~= mainMeepo then
      meepo:SetAbilityPoints(0)
    end
  end
end

function GetAllMeepos(caster)
  if caster.meepoList then
    return caster.meepoList
  else
    return {caster}
  end
end
