
modifier_spider_boss_rage = class( ModifierBaseClass )

function modifier_spider_boss_rage:IsHidden()
  return false
end

function modifier_spider_boss_rage:IsDebuff()
  return false
end

function modifier_spider_boss_rage:IsPurgable()
  return false
end

function modifier_spider_boss_rage:RemoveOnDeath()
  return true
end

function modifier_spider_boss_rage:OnCreated( kv )
  local parent = self:GetParent()
  local ability = self:GetAbility()

  self.bonus_damage = ability:GetSpecialValueFor( "bonus_damage" )
  self.bonus_movespeed_pct = ability:GetSpecialValueFor( "bonus_movespeed_pct" )
  self.lifesteal_pct = ability:GetSpecialValueFor( "lifesteal_pct" )

  if IsServer() then
    parent.enraged = true

    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_broodmother/broodmother_hunger_buff.vpcf", PATTACH_CUSTOMORIGIN, parent )
    ParticleManager:SetParticleControlEnt( nFXIndex, 0, parent, PATTACH_POINT_FOLLOW, "attach_thorax", parent:GetAbsOrigin(), true )
    self:AddParticle( nFXIndex, false, false, -1, false, false  )

    parent:EmitSound("Dungeon.SpiderBoss.Rage")
  end
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  parent:StopSound("Dungeon.SpiderBoss.Rage")
  parent.enraged = false
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:DeclareFunctions()
  local funcs =
  {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_EVENT_ON_ATTACKED,
    MODIFIER_PROPERTY_TOOLTIP,
  }
  return funcs
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:GetModifierPreAttack_BonusDamage( params )
	return self.bonus_damage
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:GetModifierMoveSpeedBonus_Percentage( params )
	return self.bonus_movespeed_pct
end

function modifier_spider_boss_rage:GetModifierAttackSpeedReductionPercentage()
  return 0
end

function modifier_spider_boss_rage:GetModifierModelScale()
  return 25
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:OnAttacked( params )
	if IsServer() then
		if params.attacker == self:GetParent() then
			local hTarget = params.target
			if hTarget and not hTarget:IsNull() and not hTarget:IsBuilding() and not hTarget:IsOther() then
				local fHealAmt = math.min( params.damage, hTarget:GetHealth() ) * self.lifesteal_pct / 100
				--print( "fHealAmt == " .. fHealAmt )
				self:GetCaster():Heal( fHealAmt, self:GetAbility() )
				ParticleManager:ReleaseParticleIndex( ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() ) )
			end
		end
	end
end

--------------------------------------------------------------------------------

function modifier_spider_boss_rage:Tooltip()
	return self.lifesteal_pct
end

