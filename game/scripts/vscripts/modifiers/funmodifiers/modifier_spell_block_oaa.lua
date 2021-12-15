modifier_spell_block_oaa = class(ModifierBaseClass)

function modifier_spell_block_oaa:IsHidden()
  return true
end

function modifier_spell_block_oaa:IsDebuff()
  return false
end

function modifier_spell_block_oaa:IsPurgable()
  return false
end

function modifier_spell_block_oaa:RemoveOnDeath()
  return false
end

function modifier_spell_block_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSORB_SPELL,
  }
end

function modifier_spell_block_oaa:GetAbsorbSpell(event)
  if not IsServer() then
    return 0
  end

  local parent = self:GetParent()
  local casted_ability = event.ability

  if not casted_ability or casted_ability:IsNull() then
    return 0
  end

  local caster = casted_ability:GetCaster()

  -- Don't block allied spells
  if caster:GetTeamNumber() == parent:GetTeamNumber() then
    return 0
  end

  -- No need to block if parent is invulnerable
  if parent:IsInvulnerable() then
    return 0
  end

  -- Don't block if passive is on cooldown
  if parent:HasModifier("modifier_spell_block_cooldown_oaa") then
    return 0
  end

  local chance = 25/100
  local cooldown = 10

  -- Get number of failures
  local prngMult = self:GetStackCount() + 1

  if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(chance) * prngMult) then
    -- Reset failure count
    self:SetStackCount(0)
	
	-- Sound
    parent:EmitSound("DOTA_Item.LinkensSphere.Activate")
	
    -- Particle
    local pfx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_POINT_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(pfx)

    -- Start cooldown by adding a modifier
    parent:AddNewModifier(parent, nil, "modifier_spell_block_cooldown_oaa", {duration = cooldown})

    return 1
  else
    -- Increment number of failures
    self:SetStackCount(prngMult)
  end

  return 0
end

---------------------------------------------------------------------------------------------------

modifier_spell_block_cooldown_oaa = class(ModifierBaseClass)

function modifier_spell_block_cooldown_oaa:IsHidden()
  return false
end

function modifier_spell_block_cooldown_oaa:IsDebuff()
  return true
end

function modifier_spell_block_cooldown_oaa:IsPurgable()
  return false
end
