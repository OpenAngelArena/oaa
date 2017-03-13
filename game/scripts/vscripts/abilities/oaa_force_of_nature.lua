--[[
  OAA modified version of Nature's Prophet's Nature's Call/Force of Nature ability
  Spawns upgraded treants for levels 5 and 6
  Code based on Pizzalol's Spell Library recreation of the original Dota ability
  and Valve's Lua ability example recreation

  Modified by: Trildar
  Date: 10.03.2017
]]
furion_force_of_nature = class ({})
LinkLuaModifier( "modifier_treant_giant_bonus", "modifiers/modifier_treant_giant_bonus", LUA_MODIFIER_MOTION_NONE )

function furion_force_of_nature:GetAOERadius()
  return self:GetSpecialValueFor( "area_of_effect" )
end

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
  Author: Noya
  Date: 25.01.2015.
  Checks for trees, if the spell didn't target one on its radius, interrupt with a message
]]
-- function furion_force_of_nature:OnAbilityPhaseStart()
--   local point = self:GetCursorPosition()
--   local area_of_effect = self:GetSpecialValueFor( "area_of_effect" )

--   if GridNav:IsNearbyTree( point, area_of_effect, true ) then
--     --print(ability,"Trees found")
--     return true
--   else
--     FireGameEvent( 'dota_hud_error_message', { reason = 80, message = "#dota_hud_error_must_target_tree" } )
--     return false
--   end
-- end

--[[
  Author: Noya
  Date: 25.01.2015.
  Latches the tree_cut event to spawn treants up to the amount of trees destroyed, limited by the ability rank.
]]
function furion_force_of_nature:OnSpellStart()
  local caster = self:GetCaster()
  local pID = caster:GetPlayerID()
  local target_point = self:GetCursorPosition()
  local area_of_effect = self:GetSpecialValueFor( "area_of_effect" )
  local max_treants = self:GetSpecialValueFor( "max_treants" )
  local max_giant_treants = self:GetSpecialValueFor( "max_giant_treants" )
  local duration = self:GetSpecialValueFor( "duration" )
  local treant_name = "npc_dota_furion_treant"
  local giant_treant_name = "npc_dota_furion_giant_treant"

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

  -- Create the units on the next frame
  Timers:CreateTimer(
    function()
      --print(ability.trees_cut)
      -- Figure out how many of each treant type to spawn
      local giant_treants_to_spawn = math.min( max_giant_treants, tree_count )
      local treants_to_spawn = math.min( max_treants, tree_count - giant_treants_to_spawn )
      -- Check whether the caster has the 2x Treant health/damage talent
      local treant_bonus_ability = caster:FindAbilityByName( "special_bonus_unique_furion" )
      local caster_has_treant_bonus
      if (treant_bonus_ability) then
        caster_has_treant_bonus = treant_bonus_ability:GetLevel() > 0
      end
      -- Spawn giant treants
      for i=1,giant_treants_to_spawn do
        local giant_treant = CreateUnitByName( giant_treant_name, target_point, true, caster, caster:GetOwner(), caster:GetTeamNumber() )
        giant_treant:SetControllableByPlayer( pID, false )
        giant_treant:SetOwner( caster )
        giant_treant:AddNewModifier( caster, self, "modifier_kill", {duration = duration} )
        if (caster_has_treant_bonus) then
          giant_treant:AddNewModifier( caster, self, "modifier_treant_giant_bonus", {} )
        end
      end
      -- Spawn regular treants
      for i=1,treants_to_spawn do
        local treant = CreateUnitByName( treant_name, target_point, true, caster, caster:GetOwner(), caster:GetTeamNumber() )
        treant:SetControllableByPlayer( pID, false )
        treant:SetOwner( caster )
        treant:AddNewModifier( caster, self, "modifier_kill", {duration = duration} )
        if (caster_has_treant_bonus) then
          treant:AddNewModifier( caster, self, "modifier_treant_bonus", {} )
        end
      end
    end
  )
  EmitSoundOnLocationWithCaster( target_point, "Hero_Furion.ForceOfNature", caster )
end
