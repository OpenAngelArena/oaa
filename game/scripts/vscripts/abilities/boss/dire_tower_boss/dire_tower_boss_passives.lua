dire_tower_boss_passives = class(AbilityBaseClass)

LinkLuaModifier("modifier_dire_tower_boss_passives", "abilities/boss/dire_tower_boss/dire_tower_boss_passives.lua", LUA_MODIFIER_MOTION_NONE)

function dire_tower_boss_passives:Precache(context)
  PrecacheResource("particle", "particles/dire_fx/dire_tower002_destruction.vpcf", context)
  PrecacheResource("model", "models/props_structures/dire_tower002_destruction.vmdl", context)
end

function dire_tower_boss_passives:GetIntrinsicModifierName()
  return "modifier_dire_tower_boss_passives"
end

function dire_tower_boss_passives:IsStealable()
  return false
end

function dire_tower_boss_passives:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_dire_tower_boss_passives = class(ModifierBaseClass)

function modifier_dire_tower_boss_passives:IsHidden()
  return true
end

function modifier_dire_tower_boss_passives:IsDebuff()
  return false
end

function modifier_dire_tower_boss_passives:IsPurgable()
  return false
end

-- function modifier_dire_tower_boss_passives:OnCreated()
  -- if IsServer() then
    -- local parent = self:GetParent()
    -- local old_angle = parent:GetAngles()
    -- local rotate_angle = QAngle(0, 90, 0)

    -- local new_angle = RotateOrientation(old_angle, rotate_angle)
    -- parent:SetAngles(new_angle[1], new_angle[2], new_angle[3]) -- changing yaw only changes facing direction and it's not model-only which is sad
  -- end
-- end

function modifier_dire_tower_boss_passives:DeclareFunctions()
  return {
    -- MODIFIER_PROPERTY_DISABLE_TURNING, -- if we disable turning, tower isnt able to attack anything behind it
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_EVENT_ON_DEATH,
  }
end

-- function modifier_dire_tower_boss_passives:GetModifierDisableTurning()
  -- return 1
-- end

function modifier_dire_tower_boss_passives:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 20000 -- it needs to be higher priority than boss properties and anti-stun
end

function modifier_dire_tower_boss_passives:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true, -- to prevent the tower from moving
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true, -- to prevent the tower from being pushed or knocked back
  }
end

function modifier_dire_tower_boss_passives:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
end

-- For the death sound and animation
if IsServer() then
  function modifier_dire_tower_boss_passives:OnDeath(event)
    local parent = self:GetParent()

    -- Check if killed unit has this modifier
    if event.unit ~= parent then
      return
    end

    local attacker = event.attacker

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Sound
    parent:EmitSound("Dire_Tower_Boss.Destruction")

    -- Model
    parent:SetOriginalModel("models/props_structures/dire_tower002_destruction.vmdl")
    parent:ManageModelChanges()

    -- Particle
    local destruction_particle = ParticleManager:CreateParticle("particles/dire_fx/dire_tower002_destruction.vpcf", PATTACH_ABSORIGIN, parent)
    ParticleManager:ReleaseParticleIndex(destruction_particle)
  end
end
