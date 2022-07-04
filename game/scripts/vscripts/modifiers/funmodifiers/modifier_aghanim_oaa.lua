modifier_aghanim_oaa = class(ModifierBaseClass)

function modifier_aghanim_oaa:IsHidden()
  return false
end

function modifier_aghanim_oaa:IsDebuff()
  return false
end

function modifier_aghanim_oaa:IsPurgable()
  return false
end

function modifier_aghanim_oaa:RemoveOnDeath()
  return false
end

if IsServer() then
  function modifier_aghanim_oaa:OnCreated()
    local parent = self:GetParent()

    if not parent:IsRealHero() or parent:IsTempestDouble() or parent:IsClone() then
      return
    end

    -- Scepter
    if not parent:HasScepter() then
      --local scepter = CreateItem("item_ultimate_scepter_2", parent, parent)
      --parent:AddItem(scepter)
      parent:AddNewModifier(parent, nil, "modifier_item_ultimate_scepter_consumed", {})
    end

    -- Shard
    if not parent:HasShardOAA() then
      --local shard = CreateItem("item_aghanims_shard", parent, parent)
      --parent:AddItem(shard)
      parent:AddNewModifier(parent, nil, "modifier_item_aghanims_shard", {})
    end
  end
end

function modifier_aghanim_oaa:GetTexture()
  return "item_ultimate_scepter"
end
