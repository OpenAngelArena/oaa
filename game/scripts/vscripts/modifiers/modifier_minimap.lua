modifier_minimap = class(ModifierBaseClass)

if IsServer() then
  function modifier_minimap:CheckState()
    local state = {
      [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
      [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
      [MODIFIER_STATE_INVULNERABLE] = true,
      [MODIFIER_STATE_UNSELECTABLE] = true,
      [MODIFIER_STATE_NO_HEALTH_BAR] = true,
      [MODIFIER_STATE_OUT_OF_GAME] = true,
      [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
      [MODIFIER_STATE_NOT_ON_MINIMAP] = self.hidden,
    }

    return state
  end

  function modifier_minimap:SetHiddenState( bIsHidden )
    if self.hidden ~= bIsHidden then
      DebugPrint("Camp Hidden State Changed")
      self.hidden = bIsHidden
      self:CheckState()
    end
    return 0.5
  end

  function modifier_minimap:OnCreated( params )
    local minimap_entity = self:GetParent()
    local teamNumber = minimap_entity:GetTeamNumber()
    local origin = minimap_entity:GetAbsOrigin()
    self.IsBoss = params.IsBoss or false
    self.IsCapture = params.IsCapture or false
    self:SetHiddenState(false)
    self.CampHasBeenKilled = false
    self.neutrals = {}

    --Capture points Icons
    if self.IsCapture then
      Timers:CreateTimer(45, function()
        if IsValidEntity(minimap_entity) and minimap_entity:IsAlive() then
          minimap_entity:ForceKill(false)
        end
      end)
      return -1
    end

    Timers:CreateTimer(0.5, function()
      if not IsValidEntity(minimap_entity) or not minimap_entity:IsAlive() then
        return -1
      end
      -- make sure we only search for neurals on respawn to avoid performance issues
      if minimap_entity.Respawn then
        self.neutrals = FindUnitsInRadius(teamNumber, origin, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false)
        if #self.neutrals > 0 then
          minimap_entity.Respawn = false
          self.CampHasBeenKilled = false
        else
          return 0.5
        end
      end

      local hasCreepAlive = false
      local isCreepCampVisible = false

      for id,creep in pairs(self.neutrals) do
        if IsValidEntity(creep) and creep:IsAlive() then
          hasCreepAlive = true
          if minimap_entity:CanEntityBeSeenByMyTeam(creep) then
            return self:SetHiddenState(true) -- if the team sees the camp, does not need minimap
          end
        else
          table.remove(self.neutrals, id)
        end
      end

      if not hasCreepAlive and self.IsBoss and IsValidEntity(minimap_entity) and minimap_entity:IsAlive() then
        minimap_entity:ForceKill(false)
        return -1
      end

      -- Camp is not visible and has creeps and is not being farmed then show it on Minimap
      if not self.CampHasBeenKilled and hasCreepAlive then
        return self:SetHiddenState(false) -- The team does not knows if the camp is alive
      elseif self.CampHasBeenKilled then
        return self:SetHiddenState(true) -- The team knows the camp was killed
      elseif not hasCreepAlive then
        local heroes = FindUnitsInRadius(teamNumber, origin, nil, 500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO , 0, 0, false)
        -- if camp is dead and a heroe sees it
        if #heroes > 0 then
          self.CampHasBeenKilled = true
          return self:SetHiddenState(true)
        end
        -- if camp is dead and no heroe sees it
        return self:SetHiddenState(false)
      end
      print('SHOULD NOT BE HERE')
      return self:SetHiddenState(true)
    end)
  end

  function modifier_minimap:IsPurgable()
    return false
  end
end
