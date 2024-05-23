
modifier_rune_hill_tripledamage = class(ModifierBaseClass)

function modifier_rune_hill_tripledamage:IsHidden()
  return false
end

function modifier_rune_hill_tripledamage:IsDebuff()
  return false
end

function modifier_rune_hill_tripledamage:IsPurgable()
  return false
end

function modifier_rune_hill_tripledamage:OnCreated()
  if not IsServer() then
    return
  end
  self:StartIntervalThink(0.1)
end

function modifier_rune_hill_tripledamage:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Remove itself if not in a duel or if parent somehow doesnt exist
  if not Duels:IsActive() or not parent or parent:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  --if parent:HasModifier("modifier_rune_hill_doubledamage") then
    --parent:RemoveModifierByName("modifier_rune_hill_doubledamage")
  --end
end

function modifier_rune_hill_tripledamage:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
  }
end

function modifier_rune_hill_tripledamage:GetModifierBaseDamageOutgoing_Percentage()
  return 200
end

function modifier_rune_hill_tripledamage:GetEffectName()
  return "particles/generic_gameplay/rune_doubledamage_owner.vpcf"
end

function modifier_rune_hill_tripledamage:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_rune_hill_tripledamage:GetTexture()
  return "rune_doubledamage"
end
