modifier_dire_tower_boss_glyph = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:IsPurgable()
  return false
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:OnCreated( kv )
  if IsServer() then
    self.nPortraitFXIndex = -1
    local nFXIndex = ParticleManager:CreateParticle( "particles/items_fx/glyph_tube.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControlEnt( nFXIndex, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_mane", self:GetParent():GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( nFXIndex, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_tail", self:GetParent():GetOrigin(), true )
  end
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:OnDestroy()
  if IsServer() then
    ParticleManager:ReleaseParticleIndex( ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_shapeshift_revert.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() ) )
  end
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MODEL_CHANGE,
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT,
  }

  return funcs
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:GetModifierModelChange( params )
  return "models/creeps/knoll_1/werewolf_boss.vmdl"
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:GetActivityTranslationModifiers( params )
  return "shapeshift"
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:GetModifierModelScale( params )
  return 75
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:GetModifierMoveSpeed_Absolute( params )
  return 550
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:GetModifierPercentageCooldown( params )
  return 50
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:GetModifierAttackPointConstant( params )
  return 0.43
end
