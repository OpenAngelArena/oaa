modifier_pudge_flesh_heap_oaa = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_pudge_flesh_heap_oaa:OnCreated( kv )
  self.flesh_heap_magic_resist = self:GetAbility():GetSpecialValueFor( "flesh_heap_magic_resist" )
  self.flesh_heap_strength_buff_amount = self:GetAbility():GetSpecialValueFor( "flesh_heap_strength_buff_amount" )

  if IsServer() then
    self:SetStackCount( self:GetAbility():GetFleshHeapKills() )
    self:GetParent():CalculateStatBonus()
  end
end

--------------------------------------------------------------------------------

function modifier_pudge_flesh_heap_oaa:OnRefresh( kv )
  self.flesh_heap_magic_resist = self:GetAbility():GetSpecialValueFor( "flesh_heap_magic_resist" )
  self.flesh_heap_strength_buff_amount = self:GetAbility():GetSpecialValueFor( "flesh_heap_strength_buff_amount" )

  if IsServer() then
    self:GetParent():CalculateStatBonus()
  end
end

--------------------------------------------------------------------------------

function modifier_pudge_flesh_heap_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
  }

  return funcs
end

--------------------------------------------------------------------------------

function modifier_pudge_flesh_heap_oaa:GetModifierMagicalResistanceBonus( params )
  return self.flesh_heap_magic_resist
end

--------------------------------------------------------------------------------

function modifier_pudge_flesh_heap_oaa:GetModifierBonusStats_Strength( params )
  return self:GetStackCount() * self.flesh_heap_strength_buff_amount
end

--------------------------------------------------------------------------------
