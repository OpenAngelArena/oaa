---
--- Created by Zarnotox.
--- DateTime: 29-Nov-17 10:50
---

modifier_scan_true_sight_thinker = class( ModifierBaseClass )
modifier_scan_true_sight = class( ModifierBaseClass )

--------- modifier_scan_true_sight_thinker ---------

function modifier_scan_true_sight_thinker:IsPurgable()
  return false
end

function modifier_scan_true_sight_thinker:IsAura()
  return true
end

function modifier_scan_true_sight_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_scan_true_sight_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_scan_true_sight_thinker:GetModifierAura()
  return "modifier_scan_true_sight"
end

function modifier_scan_true_sight_thinker:GetAuraRadius()
  return SCAN_REVEAL_RADIUS
end

if IsServer() then

  function modifier_scan_true_sight_thinker:OnDestroy()
    UTIL_Remove( self:GetParent() )
  end

end

--------- modifier_scan_true_sight ---------

function modifier_scan_true_sight:IsPurgable()
  return false
end

function modifier_scan_true_sight:IsDebuff()
  return true
end

function modifier_scan_true_sight:IsHidden()
  return false
end

function modifier_scan_true_sight:GetPriority()
  return MODIFIER_PRIORITY_HIGH
end

function modifier_scan_true_sight:CheckState()
  local state = {
    [MODIFIER_STATE_INVISIBLE] = false
  }
  return state
end