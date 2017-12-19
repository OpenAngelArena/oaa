
TransformationBaseClass = class(ItemBaseClass)

if IsServer() then
--------------------------------------------------------------------------------

  function TransformationBaseClass:GetAbilityTextureName()
    local baseName = self.BaseClass.GetAbilityTextureName( self )

    local activeName = ""

    if self.mod and not self.mod:IsNull() then
      activeName = "_active"
    end

    return baseName .. activeName
  end

  function TransformationBaseClass:OnSpellStart()
    local caster = self:GetCaster()
    local modifierName = self:GetTransformationModifierName()

    -- if we have the modifier while this thing is "toggled"
    -- ( which we should, but 'should' isn't a concept in programming )
    -- remove it
    local mod = caster:FindModifierByName( modifierName )

    if mod and not mod:IsNull() then
      mod:Destroy()
      self.mod = nil

      -- caster:EmitSound( "OAA_Item.SiegeMode.Deactivate" )
    else
      -- if it isn't toggled, add the modifier and keep track of it
      self.mod = caster:AddNewModifier( caster, self, modifierName, {} )

      -- caster:EmitSound( "OAA_Item.SiegeMode.Activate" )
    end
  end

  function TransformationBaseClass:OnUnequip()
    print('unequip!?')
    print(self:GetItemState())
  end

--------------------------------------------------------------------------------
end
