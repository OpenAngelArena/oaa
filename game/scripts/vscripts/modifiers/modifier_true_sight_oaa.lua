

LinkLuaModifier( "modifier_true_sight_oaa", "modifiers/modifier_true_sight_oaa.lua", LUA_MODIFIER_MOTION_NONE )

modifier_true_sight_oaa_thinker = class( ModifierBaseClass )
modifier_true_sight_oaa = class( ModifierBaseClass )

--------- modifier_true_sight_oaa_thinker ---------


function modifier_true_sight_oaa_thinker:OnCreated(keys)
  self.Radius = keys.radius
end

function modifier_true_sight_oaa_thinker:IsPurgable()
  return false
end

function modifier_true_sight_oaa_thinker:IsAura()
  return true
end

function modifier_true_sight_oaa_thinker:IsHidden()
  return true
end

function modifier_true_sight_oaa_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_true_sight_oaa_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_true_sight_oaa_thinker:GetModifierAura()
  return "modifier_true_sight_oaa"
end

function modifier_true_sight_oaa_thinker:GetAuraRadius()
  return self.Radius
end

if IsServer() then

  function modifier_true_sight_oaa_thinker:OnDestroy()
    UTIL_Remove( self:GetParent() )
  end

end

--------- modifier_true_sight_oaa ---------

function modifier_true_sight_oaa:IsPurgable()
  return false
end

function modifier_true_sight_oaa:IsDebuff()
  return true
end

function modifier_true_sight_oaa:IsHidden()
  return false
end

function modifier_true_sight_oaa:GetTexture()
  return "item_gem"
end

function modifier_true_sight_oaa:GetPriority()
  return MODIFIER_PRIORITY_HIGH
end

function modifier_true_sight_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_INVISIBLE] = false
  }
  return state
end
