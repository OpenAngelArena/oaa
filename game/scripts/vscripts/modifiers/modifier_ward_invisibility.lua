LinkLuaModifier('modifier_ward_invisibility_enemy', 'modifiers/modifier_ward_invisibility.lua', LUA_MODIFIER_MOTION_NONE)

modifier_ward_invisibility = class({})
modifier_ward_invisibility_enemy = class({})

function modifier_ward_invisibility_enemy:IsHidden()
  return true
end

function modifier_ward_invisibility:OnCreated()
  self.isInvis = true
  self.id = "ward_" .. tostring(math.random())
end
function modifier_ward_invisibility:OnRefresh()
  self.isInvis = true
  self.id = "ward_" .. tostring(math.random())
end

function modifier_ward_invisibility:CheckState()
  return {
    [MODIFIER_STATE_INVISIBLE] = self.isInvis,
  }
end

function modifier_ward_invisibility:IsHidden()
  return true
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_ward_invisibility:IsAura()
  return true
end

function modifier_ward_invisibility:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_ward_invisibility:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ward_invisibility:GetAuraRadius()
  return 300
end

function modifier_ward_invisibility:GetModifierAura()
  return "modifier_ward_invisibility_enemy"
end

function modifier_ward_invisibility:GetAuraEntityReject(entity)
  if self.isInvis then
    print(self.id .. ': showing self')
  end
  self.isInvis = false

  Timers:RemoveTimer(self.id)
  Timers:CreateTimer(self.id, {
    endTime = 3,
    callback = function()
      print(self.id .. ': hiding self')
      self.isInvis = true
    end
  })
  return false
end
