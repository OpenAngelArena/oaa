LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_far_sight_dummy_stuff", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_far_sight_true_sight", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)

item_far_sight = class(ItemBaseClass)

function item_far_sight:GetAOERadius()
  return self:GetSpecialValueFor("reveal_radius")
end

function item_far_sight:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_far_sight:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()
  local casterTeam = caster:GetTeamNumber()
  local revealDuration = self:GetSpecialValueFor("reveal_duration")

  --AddFOWViewer(casterTeam, target, self:GetSpecialValueFor("reveal_radius"), revealDuration, false)
  --local trueSightThinker = CreateModifierThinker(caster, self, "modifier_item_far_sight_true_sight", {duration = revealDuration}, target, casterTeam, false)

  local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", target, false, caster, caster, casterTeam)
  dummy:AddNewModifier(caster, self, "modifier_far_sight_dummy_stuff", {})
  dummy:AddNewModifier(caster, self, "modifier_item_far_sight_true_sight", {})
  dummy:AddNewModifier(caster, self, "modifier_kill", {duration = revealDuration})

  dummy:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, revealDuration)
  dummy:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, revealDuration)
end

item_far_sight_2 = item_far_sight
item_far_sight_3 = item_far_sight
item_far_sight_4 = item_far_sight

---------------------------------------------------------------------------------------------------

modifier_item_far_sight_true_sight = class(ModifierBaseClass)

function modifier_item_far_sight_true_sight:IsHidden()
  return true
end

function modifier_item_far_sight_true_sight:IsPurgable()
  return false
end

function modifier_item_far_sight_true_sight:IsAura()
  return true
end

function modifier_item_far_sight_true_sight:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.revealRadius = ability:GetSpecialValueFor("reveal_radius")
  else
    self.revealRadius = 800
  end

  if IsServer() then
    local parent = self:GetParent()
    local parent_location = parent:GetAbsOrigin()
    local parent_team = parent:GetTeamNumber()
    local enemy_team = DOTA_TEAM_BADGUYS
    if parent_team == enemy_team then
      enemy_team = DOTA_TEAM_GOODGUYS
    end

	  -- Old particle
    --self.nFXIndex = ParticleManager:CreateParticle( "particles/items/far_sight.vpcf", PATTACH_CUSTOMORIGIN, nil )
    --ParticleManager:SetParticleControl( self.nFXIndex, 0, self:GetParent():GetOrigin() )
    --ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector(radius, 0, 0) )

    -- New particles
    local index1 = ParticleManager:CreateParticleForTeam("particles/items/far_sight/far_sight_green.vpcf", PATTACH_WORLDORIGIN, parent, parent_team)
    ParticleManager:SetParticleControl(index1, 0, parent_location)
    ParticleManager:SetParticleControl(index1, 1, Vector(self.revealRadius-100, 0, 0))

    local index2 = ParticleManager:CreateParticleForTeam("particles/items/far_sight/far_sight_red.vpcf", PATTACH_WORLDORIGIN, parent, enemy_team)
    ParticleManager:SetParticleControl(index2, 0, parent_location)
    ParticleManager:SetParticleControl(index2, 1, Vector(self.revealRadius-100, 0, 0))

    self.particle1 = index1
    self.particle2 = index2
  end
end

function modifier_item_far_sight_true_sight:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_item_far_sight_true_sight:OnDeath(event)
  if event.unit == self:GetParent() then
    if self.particle1 then
      ParticleManager:DestroyParticle(self.particle1, true)
      ParticleManager:ReleaseParticleIndex(self.particle1)
      self.particle1 = nil
    end

    if self.particle2 then
      ParticleManager:DestroyParticle(self.particle2, true)
      ParticleManager:ReleaseParticleIndex(self.particle2)
      self.particle2 = nil
    end
  end
end

function modifier_item_far_sight_true_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_item_far_sight_true_sight:GetAuraRadius()
  return self.revealRadius
end

function modifier_item_far_sight_true_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_far_sight_true_sight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_item_far_sight_true_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_item_far_sight_true_sight:OnDestroy()
  if self.particle1 then
    ParticleManager:DestroyParticle(self.particle1, true)
    ParticleManager:ReleaseParticleIndex(self.particle1)
  end
  if self.particle2 then
    ParticleManager:DestroyParticle(self.particle2, true)
    ParticleManager:ReleaseParticleIndex(self.particle2)
  end
end

---------------------------------------------------------------------------------------------------

modifier_far_sight_dummy_stuff = class(ModifierBaseClass)

function modifier_far_sight_dummy_stuff:IsHidden()
  return true
end

function modifier_far_sight_dummy_stuff:IsDebuff()
  return false
end

function modifier_far_sight_dummy_stuff:IsPurgable()
  return false
end

function modifier_far_sight_dummy_stuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_far_sight_dummy_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_far_sight_dummy_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_far_sight_dummy_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_far_sight_dummy_stuff:GetBonusDayVision()
  return self:GetAbility():GetSpecialValueFor("reveal_radius")
end

function modifier_far_sight_dummy_stuff:GetBonusNightVision()
  return self:GetAbility():GetSpecialValueFor("reveal_radius")
end

function modifier_far_sight_dummy_stuff:CheckState()
  local state = {
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    [MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_FLYING] = true,
  }
  return state
end
