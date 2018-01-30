-- defines item_dispel_orb_1
-- defines modifier_item_preemptive_purge
LinkLuaModifier( "modifier_item_preemptive_purge", "items/reflex/preemptive_purge.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_purgetester", "modifiers/modifier_purgetester.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------

item_dispel_orb_1 = class(ItemBaseClass)

function item_dispel_orb_1:GetIntrinsicModifierName()
  return 'modifier_generic_bonus'
end

function item_dispel_orb_1:OnSpellStart()
  local caster = self:GetCaster()
  local mod = caster:AddNewModifier(caster, self, 'modifier_item_preemptive_purge', {
    duration = self:GetSpecialValueFor( "duration" )
  })
  return true
end

function item_dispel_orb_1:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

item_dispel_orb_2 = item_dispel_orb_1 --luacheck: ignore item_dispel_orb_2
item_dispel_orb_3 = item_dispel_orb_1

------------------------------------------------------------------------

modifier_item_preemptive_purge = class(ModifierBaseClass)

function modifier_item_preemptive_purge:IsHidden()
  return false
end

function modifier_item_preemptive_purge:IsDebuff()
  return false
end

function modifier_item_preemptive_purge:IsPurgable()
  return false
end

function modifier_item_preemptive_purge:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end


function modifier_item_preemptive_purge:OnCreated()
  local interval = self:GetAbility():GetSpecialValueFor( "tick_interval" )
  self:StartIntervalThink( interval )
  if IsServer() then
    if self.nFXIndex == nil then
      self.nFXIndex = ParticleManager:CreateParticle( "particles/items/dispel_orb/blue_flare.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
      ParticleManager:SetParticleControlEnt( self.nFXIndex, 0, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
    end
  end
end

function modifier_item_preemptive_purge:OnDestroy()
  if IsServer() then
    if self.nFXIndex ~= nil then
      ParticleManager:DestroyParticle( self.nFXIndex, true )
      ParticleManager:ReleaseParticleIndex( self.nFXIndex )
    end
  end
end

function modifier_item_preemptive_purge:OnIntervalThink()
  if IsServer() then
    local caster = self:GetCaster()

    -- Tests if given modifier is a debuff and purgable with a basic dispel
    --Applies the modifier to a test unit, purges the unit with a basic dispel affecting debuffs only,
    --then checks if the modifier was purged (All because IsDebuff and IsPurgable don't exist in the Lua API
    --for built-in modifiers)
    local modifiers = caster:FindAllModifiers()
    local hasPurgableDebuffs = false
    for _, modifier in pairs( modifiers ) do
      if modifier:GetName() ~= self:GetName() then
        local testUnit = CreateUnitByName("npc_dota_lone_druid_bear1", Vector(0, 0, 0), false, caster, caster:GetOwner(), caster:GetTeamNumber())
        testUnit:AddNewModifier(testUnit, nil, "modifier_purgetester", nil)
        testUnit:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier:GetName(), nil)
        testUnit:Purge(false, true, true, false, false)
        if not testUnit:HasModifier(modifier:GetName()) then
          print(modifier:GetName())
          hasPurgableDebuffs = true
          break
        end
      end
    end

    if hasPurgableDebuffs then
      local burstEffect = ParticleManager:CreateParticle( "particles/items/dispel_orb/steam_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
      ParticleManager:SetParticleControlEnt( burstEffect, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true )
      ParticleManager:ReleaseParticleIndex( burstEffect )
      caster:Purge(false, true, false, false, false)
    end
  end
end
