LinkLuaModifier( "modifier_transformation_item_watcher", "items/transformation/baseclass.lua", LUA_MODIFIER_MOTION_NONE )

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
    self.isTransformation = true
    local caster = self:GetCaster()
    local modifierName = self:GetTransformationModifierName()

    -- if we have the modifier while this thing is "toggled"
    -- ( which we should, but 'should' isn't a concept in programming )
    -- remove it
    local mod = caster:FindModifierByName(modifierName)

    if mod then
      if not mod:IsNull() then
        mod:Destroy()
      end
      self.mod = nil

      -- caster:EmitSound( "OAA_Item.SiegeMode.Deactivate" )
    else
      -- if it isn't toggled, add the modifier and keep track of it
      self:EndOthers()

      self.mod = caster:AddNewModifier( caster, self, modifierName, {} )

      if self.watcher and not self.watcher:IsNull() then
        self.watcher:Destroy()
      end
      self.watcher = caster:AddNewModifier(caster, self, "modifier_transformation_item_watcher", {})
      self.watcher.mod = self.mod
      self.watcher:Start()

      -- caster:EmitSound( "OAA_Item.SiegeMode.Activate" )
    end
  end

  function TransformationBaseClass:EndOthers()
    local caster = self:GetCaster()

    local function IsTransformation(item)
      return item and item.isTransformation and item ~= self
    end

    local items = filter(IsTransformation, map(partial(caster.GetItemInSlot, caster), range(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6)))

    items:each(function (item)
      local modifierName = item:GetTransformationModifierName()
      local mod = caster:FindModifierByName(modifierName)
      if mod and not mod:IsNull() then
        mod:Destroy()
      end
      if item.watcher and not item.watcher:IsNull() then
        item.watcher:Destroy()
      end
    end)
  end

--------------------------------------------------------------------------------
end

modifier_transformation_item_watcher = class(ModifierBaseClass)

function modifier_transformation_item_watcher:IsPurgable()
  return false
end

function modifier_transformation_item_watcher:IsHidden()
  return true
end

function modifier_transformation_item_watcher:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

if IsServer() then
  function modifier_transformation_item_watcher:Start()
    self:StartIntervalThink(1)
  end

  function modifier_transformation_item_watcher:OnIntervalThink()
    if self.mod:IsNull() then
      self:Stop()
      return
    end
    local item = self:GetAbility()
    if item:GetItemState() ~= 1 then
      self:Stop()
    end
  end

  function modifier_transformation_item_watcher:Stop()
    if self.mod then
      if not self.mod:IsNull() then
        self.mod:Destroy()
      end
      self.mod = nil
    end
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end
