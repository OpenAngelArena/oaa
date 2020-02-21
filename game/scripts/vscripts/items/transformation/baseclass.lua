TransformationBaseClass = class(ItemBaseClass)

LinkLuaModifier( "modifier_transformation_item_watcher", "items/transformation/baseclass.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function TransformationBaseClass:GetAbilityTextureName()
  local baseName = self.BaseClass.GetAbilityTextureName( self )

  local activeName = ""

  if self.mod and not self.mod:IsNull() then
    activeName = "_active"
  end

  return baseName .. activeName
end

--function TransformationBaseClass:OnDestroy()
--end

function TransformationBaseClass:OnSpellStart()
  --self.isTransformation = true
  local caster = self:GetCaster()
  local modifierName = self:GetTransformationModifierName()

  -- if we have the modifier while this thing is "toggled"
  -- ( which we should, but 'should' isn't a concept in programming )
  -- remove it
  -- local mod = caster:FindModifierByName(modifierName)

  -- if mod then
    -- if not mod:IsNull() then
      -- mod:Destroy()
    -- end
    -- self.mod = nil
    -- if self.watcher and not self.watcher:IsNull() then
      -- self.watcher:Destroy()
    -- end

  -- else
    -- -- if it isn't toggled, add the modifier and keep track of it
    -- self:EndOthers()

    self.mod = caster:AddNewModifier( caster, self, modifierName, {duration = self:GetSpecialValueFor("duration")} )

    -- if self.watcher and not self.watcher:IsNull() then
      -- self.watcher:Destroy()
    -- end
    -- self.watcher = caster:AddNewModifier(caster, self, "modifier_transformation_item_watcher", {})

  --end
end

if IsServer() then
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
end

--------------------------------------------------------------------------------

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

if not IsServer() then
  function modifier_transformation_item_watcher:OnDestroy()
    local item = self:GetAbility()
    if item then
      item.mod = nil
    end
  end
end

function modifier_transformation_item_watcher:OnCreated()
  local item = self:GetAbility()
  local modifierName = item:GetTransformationModifierName()
  local caster = self:GetParent()

  if IsServer() then
    local mod = caster:FindModifierByName(modifierName)

    self.mod = mod
    item.mod = mod
    self:StartIntervalThink(1)
  else
    item.mod = self
  end
end
modifier_transformation_item_watcher.OnRefresh = modifier_transformation_item_watcher.OnCreated

if IsServer() then
  function modifier_transformation_item_watcher:OnIntervalThink()
    if self.mod == nil or self.mod:IsNull() then
      self:Stop()
      return
    end
    local item = self:GetAbility()
    if not item or item:GetItemState() ~= 1 then
      self:Stop()
    end
  end

  function modifier_transformation_item_watcher:Stop()
    if self.mod then
      if self.mod ~= nil or not self.mod:IsNull() then
        self.mod:Destroy()
      end
      self.mod = nil
    end
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end
