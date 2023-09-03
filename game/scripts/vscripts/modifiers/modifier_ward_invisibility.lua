
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

function modifier_ward_invisibility:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED)
end

function modifier_ward_invisibility:GetAuraRadius()
  return POOP_WARD_RADIUS
end

function modifier_ward_invisibility:GetModifierAura()
  return "modifier_ward_invisibility_enemy"
end

function modifier_ward_invisibility:GetAuraEntityReject(entity)
  if entity:IsOAABoss() then
    return true
  end

  -- Reveal the ward every time an enemy walks into range
  self.isInvis = false

  Timers:RemoveTimer(self.id)
  Timers:CreateTimer(self.id, {
    endTime = 3,
    callback = function()
      -- Hide the ward
      self.isInvis = true
    end
  })

  return false
end
