--[[
  OAA modified version of Nature's Prophet's Nature's Call/Force of Nature ability
  Spawns upgraded treants for levels 5 and 6
  Code based on Pizzalol's Spell Library recreation of the original Dota ability
  and Valve's Lua ability example recreation

  Modified by: Trildar
  Date: 10.03.2017
]]
furion_force_of_nature = class(AbilityBaseClass)
LinkLuaModifier( "modifier_treant_bonus_oaa", "modifiers/modifier_treant_bonus_oaa", LUA_MODIFIER_MOTION_NONE )

function furion_force_of_nature:GetAOERadius()
  return self:GetSpecialValueFor( "area_of_effect" )
end

-- Check for trees in cast area and throw a cast error if there are none
function furion_force_of_nature:CastFilterResultLocation( target_point )
  if IsServer() then
    local area_of_effect = self:GetSpecialValueFor( "area_of_effect" )

    if GridNav:IsNearbyTree( target_point, area_of_effect, true ) then
      return UF_SUCCESS
    else
      return UF_FAIL_CUSTOM
    end
  end
end

function furion_force_of_nature:GetCustomCastErrorLocation( target_point )
  return "#dota_hud_error_must_target_tree"
end

--[[
  Gets all tree entities that would be destroyed by the ability and counts them then spawns treants up to that tree count.
  Prioritizes spawning Giant Treants first before spawning normal Treants if tree count allows it.
]]
function furion_force_of_nature:OnSpellStart()
  local caster = self:GetCaster()
  local pID = caster:GetPlayerID()
  local target_point = self:GetCursorPosition()
  local area_of_effect = self:GetSpecialValueFor( "area_of_effect" )
  local max_treants = self:GetSpecialValueFor( "max_treants" )
  local duration = self:GetSpecialValueFor( "duration" )
  local ability_level = self:GetLevel()
  -- Units to spawn for each ability level
  local treant_names = {"npc_dota_furion_treant_1",
                        "npc_dota_furion_treant_2",
                        "npc_dota_furion_treant_3",
                        "npc_dota_furion_treant_4",
                        "npc_dota_furion_treant_5",
                        "npc_dota_furion_treant_6"}

  local trees = GridNav:GetAllTreesAroundPoint( target_point, area_of_effect, true )
  local tree_count = #trees

  -- Play the particle
  local particleName = "particles/units/heroes/hero_furion/furion_force_of_nature_cast.vpcf"
  local particle1 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
  ParticleManager:SetParticleControlEnt( particle1, 0, caster, PATTACH_POINT_FOLLOW, "attach_staff_base", caster:GetOrigin(), true )
  ParticleManager:SetParticleControl( particle1, 1, target_point )
  ParticleManager:SetParticleControl( particle1, 2, Vector(area_of_effect,0,0) )
  ParticleManager:ReleaseParticleIndex( particle1 )

  GridNav:DestroyTreesAroundPoint( target_point, area_of_effect, true )

  -- Check whether the caster has learnt the 2x Treant health/damage talent
  local caster_has_treant_bonus = caster:HasLearnedAbility( "special_bonus_unique_furion" )
  -- Check whether the caster has learnt the +4 Treants talent
  local caster_has_plus_treants = caster:HasLearnedAbility( "special_bonus_unique_furion_2" )
  -- Increase maximum Treants based on +4 Treants talent
  if caster_has_plus_treants then
    max_treants = max_treants + caster:FindAbilityByName( "special_bonus_unique_furion_2" ):GetSpecialValueFor( "value" )
  end
  local treants_to_spawn = math.min( max_treants, tree_count )

  -- Spawn Treants
  for i=1,treants_to_spawn do
    local treant = CreateUnitByName( treant_names[ability_level], target_point, true, caster, caster:GetOwner(), caster:GetTeamNumber() )
    treant:SetControllableByPlayer( pID, false )
    treant:SetOwner( caster )
    treant:AddNewModifier( caster, self, "modifier_kill", {duration = duration} )
    if caster_has_treant_bonus then
      treant:AddNewModifier( caster, self, "modifier_treant_bonus_oaa", {} )
    end
  end
  EmitSoundOnLocationWithCaster( target_point, "Hero_Furion.ForceOfNature", caster )
end

function furion_force_of_nature:OnStolen(hSourceAbility)
  local caster = self:GetCaster()
  self:SetHidden(true) -- Decide later if it will unhide

  if caster:FindAbilityByName("morphling_replicate") then
    self:SetHidden(false) -- Unhide if its morphling
    return
  end

  if not caster:FindAbilityByName("furion_wrath_of_nature_oaa") then
    self:SetHidden(false) -- Unhide immediately if Rubick stole force of nature after ability that is not wrath of nature
  end

  local spell_steal_ability = caster:FindAbilityByName("rubick_spell_steal")
  if not spell_steal_ability then
    self:SetHidden(false)
    return
  end
  local speal_steal_cast_range = spell_steal_ability:GetCastRange() or 1525
  local spell_steal_speed = spell_steal_ability:GetSpecialValueFor("projectile_speed") or 900
  local spell_steal_time = speal_steal_cast_range/spell_steal_speed+0.01
  Timers:CreateTimer(spell_steal_time, function()
    local wrath_of_nature_ability = caster:FindAbilityByName("furion_wrath_of_nature_oaa")
    if wrath_of_nature_ability then
      if wrath_of_nature_ability:IsHidden() or wrath_of_nature_ability:IsNull() then
        self:SetHidden(false)
      end
    else
      self:SetHidden(false)
    end
  end)
end
