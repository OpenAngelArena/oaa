LinkLuaModifier('modifier_ward_invisibility_enemy', 'modifiers/modifier_ward_invisibility.lua', LUA_MODIFIER_MOTION_NONE)

modifier_ward_invisibility = class(ModifierBaseClass)
modifier_ward_invisibility_enemy = class(ModifierBaseClass)

function modifier_ward_invisibility_enemy:IsHidden()
  return true
end

function modifier_ward_invisibility:OnCreated(keys)
  self.isInvis = true
  self.id = DoUniqueString("ward_")
  self.isFindable = not keys.invisible
end
function modifier_ward_invisibility:OnRefresh(keys)
  self.isInvis = true
  self.id = DoUniqueString("ward_")
  self.isFindable = not keys.invisible
end

function modifier_ward_invisibility:CheckState()
  return {
    [MODIFIER_STATE_INVISIBLE] = self.isInvis,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end

function modifier_ward_invisibility:IsHidden()
  return true
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_ward_invisibility:IsAura()
  return self.isFindable
end

function modifier_ward_invisibility:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_ward_invisibility:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ward_invisibility:GetAuraRadius()
  return POOP_WARD_RADIUS
end

function modifier_ward_invisibility:GetModifierAura()
  return "modifier_ward_invisibility_enemy"
end

function modifier_ward_invisibility:GetAuraEntityReject(entity)
  if self.isInvis then
    DebugPrint(self.id .. ': showing self')
  end
  self.isInvis = false

  Timers:RemoveTimer(self.id)
  Timers:CreateTimer(self.id, {
    endTime = 3,
    callback = function()
      DebugPrint(self.id .. ': hiding self')
      self.isInvis = true
    end
  })
  return false
end
