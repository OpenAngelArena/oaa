
item_vampire = class(TransformationBaseClass)

LinkLuaModifier( "modifier_item_vampire", "items/transformation/vampire.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_vampire_active", "items/transformation/vampire.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_vampire:GetIntrinsicModifierName()
  return "modifier_item_vampire"
end

function item_vampire:GetTransformationModifierName()
  return "modifier_item_vampire_active"
end

--------------------------------------------------------------------------------

modifier_item_vampire = class(ModifierBaseClass)
modifier_item_vampire_active = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_item_vampire_active:IsPurgable()
  return false
end

--------------------------------------------------------------------------------

function modifier_item_vampire_active:OnCreated()
  if IsServer() then
    self.health_fraction = 0
  end
end

function modifier_item_vampire_active:IsPurgable()
  return false
end

function modifier_item_vampire_active:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_HEALTH_GAINED,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

Debug:EnableDebugging()

function modifier_item_vampire_active:OnHealthGained( kv )
  if IsServer() then
    -- Check that event is being called for the unit that self is attached to
    if not self.isVampHeal and kv.unit == self:GetParent() and kv.gain > 0 then
      local desiredHP = kv.unit:GetHealth() - kv.gain + self.health_fraction
      desiredHP = math.max(desiredHP, 1)
      -- Keep record of fractions of health since Dota doesn't (mainly to make passive health regen sort of work)
      self.health_fraction = desiredHP % 1

      DebugPrintTable(kv)
      kv.unit:SetHealth( desiredHP )
    end
  end
end

function modifier_item_vampire_active:OnAttackLanded( event )
  if IsServer() then
    local parent = self:GetParent()
    local spell = self:GetAbility()

    -- i can just use code from greater power treads here!
    -- yaaaaay
    if event.attacker == parent then
      local target = event.target

      local healAmount = event.original_damage * spell:GetSpecialValueFor('active_lifesteal_percent') / 100

      self.isVampHeal = true
      parent:Heal(healAmount, self)
      self.isVampHeal = false
    end
  end
end
