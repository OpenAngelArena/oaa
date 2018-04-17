-- Azazel's Summons
-- by Firetoad, April 17th, 2018

--------------------------------------------------------------------------------

--LinkLuaModifier("modifier_elixier_burst_active", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

azazel_summon = class(ItemBaseClass)

function azazel_summon:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()

    caster:EmitSound("DOTA_Item.Necronomicon.Activate")

    -- Destroy any existing summons tied to this caster
    if caster.azazel_summon then
      caster.azazel_summon:Kill(nil, caster)
    end

    -- Summon parameters
    local summon_position = caster:GetAbsOrigin() + caster:GetForwardVector() * 100
    local summon_name = self:GetAbilityName()
    summon_name = "npc_dota_"..summon_name:sub(6)

    -- Summon the creature
    GridNav:DestroyTreesAroundPoint(summon_position, 128, false)
    caster.azazel_summon = CreateUnitByName(summon_name, summon_position, true, caster, caster, caster:GetTeam())
    caster.azazel_summon:SetControllableByPlayer(caster:GetPlayerID(), true)
    caster.azazel_summon:AddNewModifier(caster, ability, "modifier_kill", {duration = self:GetSpecialValueFor("summon_duration")})

    -- Level up any relevant abilities
    if caster.azazel_summon:FindAbilityByName("azazel_summon_farmer_innate") then
      caster.azazel_summon:FindAbilityByName("azazel_summon_farmer_innate"):SetLevel(1)
    elseif caster.azazel_summon:FindAbilityByName("azazel_scout_permanent_invisibility") then
      caster.azazel_summon:FindAbilityByName("azazel_scout_permanent_invisibility"):SetLevel(1)
    end

    self:SpendCharge()
  end
end

--------------------------------------------------------------------------------

item_azazel_summon_farmer_1 = azazel_summon
item_azazel_summon_farmer_2 = azazel_summon
item_azazel_summon_farmer_3 = azazel_summon
item_azazel_summon_farmer_4 = azazel_summon
item_azazel_summon_scout_1 = azazel_summon
item_azazel_summon_scout_2 = azazel_summon
item_azazel_summon_scout_3 = azazel_summon
item_azazel_summon_scout_4 = azazel_summon
item_azazel_summon_tank_1 = azazel_summon
item_azazel_summon_tank_2 = azazel_summon
item_azazel_summon_tank_3 = azazel_summon
item_azazel_summon_tank_4 = azazel_summon

--------------------------------------------------------------------------------

