LinkLuaModifier("modifier_item_dispel_orb_active", "items/dispel_orb.lua", LUA_MODIFIER_MOTION_NONE)

item_dispel_orb_1 = class(ItemBaseClass)
item_dispel_orb_2 = item_dispel_orb_1
item_dispel_orb_3 = item_dispel_orb_1

function item_dispel_orb_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_dispel_orb_1:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply modifier that dispels OnIntervalThink
  caster:AddNewModifier(caster, self, "modifier_item_dispel_orb_active", { duration = self:GetSpecialValueFor("duration") })
end

---------------------------------------------------------------------------------------------------

modifier_item_dispel_orb_active = class(ModifierBaseClass)

function modifier_item_dispel_orb_active:IsHidden()
  return false
end

function modifier_item_dispel_orb_active:IsDebuff()
  return false
end

function modifier_item_dispel_orb_active:IsPurgable()
  return false
end

function modifier_item_dispel_orb_active:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    if self.particle == nil then
      self.particle = ParticleManager:CreateParticle("particles/items/dispel_orb/dispel_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    end

    local interval = self:GetAbility():GetSpecialValueFor("tick_interval")
    self:StartIntervalThink(interval)
  end
end

function modifier_item_dispel_orb_active:OnRefresh()
  if IsServer() then
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, true)
      ParticleManager:ReleaseParticleIndex(self.particle)
    end

    local parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/items/dispel_orb/dispel_base.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
  end
end

function modifier_item_dispel_orb_active:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_item_dispel_orb_active:OnIntervalThink()
  local parent = self:GetParent()

  local modifiers = parent:FindAllModifiers()
  local modifierCount = #modifiers

  parent:Purge(false, true, false, false, false)

  modifiers = parent:FindAllModifiers()
  local modifierCountAfter = #modifiers

  if modifierCountAfter < modifierCount then
    local burstEffect = ParticleManager:CreateParticle( "particles/items/dispel_orb/dispel_steam.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt( burstEffect, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true )
    ParticleManager:ReleaseParticleIndex( burstEffect )
  end
end

function modifier_item_dispel_orb_active:GetTexture()
  return "custom/dispel_orb_3"
end
