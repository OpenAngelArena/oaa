ItemBaseClass = class({})

function ItemBaseClass:GetAbilityTextureName(brokenAPI)
  return self.BaseClass.GetAbilityTextureName(self)
end

function ItemBaseClass:ProcsMagicStick()
  return false
end

if IsServer() then
  if not OnChargeCountChanged_Engine then
    OnChargeCountChanged_Engine = CDOTA_Item_Lua.OnChargeCountChanged
    function CDOTA_Item_Lua:OnChargeCountChanged(what)
      OnChargeCountChanged_Engine(self)
    end
  end
end
