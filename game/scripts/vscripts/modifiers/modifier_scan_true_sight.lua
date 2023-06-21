---
--- Created by Zarnotox.
--- DateTime: 29-Nov-17 10:50
---

modifier_scan_true_sight_thinker = class( ModifierBaseClass )

--------- modifier_scan_true_sight_thinker ---------

function modifier_scan_true_sight_thinker:IsPurgable()
  return false
end

function modifier_scan_true_sight_thinker:IsAura()
  return true
end

function modifier_scan_true_sight_thinker:IsHidden()
  return true
end

function modifier_scan_true_sight_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_scan_true_sight_thinker:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_scan_true_sight_thinker:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_scan_true_sight_thinker:GetModifierAura()
  return "modifier_truesight"
end

function modifier_scan_true_sight_thinker:GetAuraRadius()
  return SCAN_REVEAL_RADIUS
end

function modifier_scan_true_sight_thinker:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    if parent and not parent:IsNull() then
      parent:ForceKillOAA(false)
    end
  end
end
