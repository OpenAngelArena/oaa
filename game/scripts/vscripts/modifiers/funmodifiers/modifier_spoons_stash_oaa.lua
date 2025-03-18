-- Note: Doesnt work for Meepo: Boots placed in backpack are not copied to clones.

modifier_spoons_stash_oaa = class(ModifierBaseClass)

function modifier_spoons_stash_oaa:IsHidden()
  return false
end

function modifier_spoons_stash_oaa:IsDebuff()
  return false
end

function modifier_spoons_stash_oaa:IsPurgable()
  return false
end

function modifier_spoons_stash_oaa:RemoveOnDeath()
  return false
end

function modifier_spoons_stash_oaa:CheckState()
  return {
    [MODIFIER_STATE_CAN_USE_BACKPACK_ITEMS] = true,
  }
end

function modifier_spoons_stash_oaa:GetTexture()
  return "custom/modifiers/spoons_stash"
end
