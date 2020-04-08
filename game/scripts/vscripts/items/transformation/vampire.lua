item_vampire = class(TransformationBaseClass)

local vampire = {}

LinkLuaModifier( "modifier_item_vampire", "items/transformation/vampire.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_vampire_active", "items/transformation/vampire.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_vampire:GetIntrinsicModifierName()
  return "modifier_item_vampire"
end

function item_vampire:GetTransformationModifierName()
  return "modifier_item_vampire_active"
end

item_vampire_2 = item_vampire
--------------------------------------------------------------------------------

modifier_item_vampire = class(ModifierBaseClass)

function modifier_item_vampire:IsHidden()
  return true
end

function modifier_item_vampire:OnCreated(keys)
  if not self.procRecords then
    self.procRecords = {}
  end
end

function modifier_item_vampire:DeclareFunctions()
  local funcs = {
    -- MODIFIER_EVENT_ON_HEALTH_GAINED,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_item_vampire:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_vampire:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_vampire:GetModifierStatusResistanceStacking()
  if not self:GetParent():HasModifier( "modifier_item_vampire_active" ) then
    return self:GetAbility():GetSpecialValueFor("bonus_status_resistance")
  else
    return 0
  end
end

function modifier_item_vampire:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

-- Have to check for process_procs flag in OnAttackLanded as the flag won't be set in OnTakeDamage
function modifier_item_vampire:OnAttackLanded(event)
  local parent = self:GetParent()
  if event.attacker ~= parent or not event.process_procs then
    return
  end
  self.procRecords[event.record] = true
end

function modifier_item_vampire:OnTakeDamage( event )
  if IsServer() then
    local parent = self:GetParent()
    local spell = self:GetAbility()

    if not spell.mod then
      vampire.lifesteal(self, event, spell, parent, spell:GetSpecialValueFor('lifesteal_percent'))
    end
  end
end

--------------------------------------------------------------------------------

modifier_item_vampire_active = class(ModifierBaseClass)

function modifier_item_vampire_active:IsHidden()
  return false
end

function modifier_item_vampire_active:IsDebuff()
  return false
end

function modifier_item_vampire_active:IsPurgable()
  return true
end

function modifier_item_vampire_active:OnCreated()
  if IsServer() then
    if not self.procRecords then
      self.procRecords = {}
    end
    self:StartIntervalThink(1 / self:GetAbility():GetSpecialValueFor('ticks_per_second'))
    self:GetParent():EmitSound("Vampire.Activate.Begin")
    if self.nPreviewFX == nil then
      self.nPreviewFX = ParticleManager:CreateParticle( "particles/items/vampire/vampire.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    end
  end
end

function modifier_item_vampire_active:OnDestroy()
  if IsServer() then
    if self.nPreviewFX ~= nil then
      ParticleManager:DestroyParticle( self.nPreviewFX, false )
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function modifier_item_vampire_active:OnIntervalThink()
  if IsServer() then
    local parent = self:GetParent()
    local spell = self:GetAbility()
    if not spell then
      if not self:IsNull() then
        self:Destroy()
      end
      return
    end
    local damage = parent:GetHealth() * spell:GetSpecialValueFor('damage_per_second_pct') / 100
    damage = damage / spell:GetSpecialValueFor('ticks_per_second')

    local damageTable = {
      victim = parent,
      attacker = parent,
      damage = damage,
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_REFLECTION),
      ability = spell,
    }

    ApplyDamage( damageTable )
  end
end

function modifier_item_vampire_active:DeclareFunctions()
  local funcs = {
    -- MODIFIER_EVENT_ON_HEALTH_GAINED,
    MODIFIER_PROPERTY_DISABLE_HEALING,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_item_vampire_active:GetDisableHealing( kv )
  if IsServer() then
    if not GameRules:IsDaytime() then
      return 0
	end
    -- Check that event is being called for the unit that self is attached to
    if self.isVampHeal then
      return 0
    end
    return 1
  end
end

-- Have to check for process_procs flag in OnAttackLanded as the flag won't be set in OnTakeDamage
function modifier_item_vampire_active:OnAttackLanded(event)
  local parent = self:GetParent()
  if event.attacker ~= parent or not event.process_procs then
    return
  end
  self.procRecords[event.record] = true
end

function modifier_item_vampire_active:OnTakeDamage( event )
  if IsServer() then
    local parent = self:GetParent()
    local spell = self:GetAbility()

    self.isVampHeal = true
    vampire.lifesteal(self, event, spell, parent, spell:GetSpecialValueFor('active_lifesteal_percent'))
    self.isVampHeal = false
  end
end

function vampire:lifesteal(event, spell, parent, amount)
  if IsServer() then

    if event.attacker ~= parent or not self.procRecords[event.record] then
      return
    end

    self.procRecords[event.record] = nil

    local damage = event.damage

    if damage < 0 then
      return
    end

    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    local parentTeam = parent:GetTeamNumber()
    local target = event.unit

    local ufResult = UnitFilter(
      target,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      parentTeam
    )

    if ufResult == UF_SUCCESS then
      parent:Heal( damage * ( amount * 0.01 ), parent )

      local part = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN, parent )
      ParticleManager:ReleaseParticleIndex( part )

      if parent:HasModifier( "modifier_item_vampire_active" ) then
        ProjectileManager:CreateTrackingProjectile( {
          Target = parent,
          Source = target,
          EffectName = "particles/items/vampire/vampire_projectile.vpcf",
          iMoveSpeed = 600,
          vSourceLoc = target:GetOrigin(),
          bDodgeable = false,
          bProvidesVision = false,
        } )
     end

    else
      DebugPrint('Not lifestealing from ' .. tostring(target:GetName()))
    end
  end
end
