faceless_void_time_lock_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_faceless_void_time_lock_oaa", "abilities/oaa_time_lock.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

-- this should probably be moved elsewhere somewhere down the line
-- probably somewhere where anything prng can access it
faceless_void_time_lock_oaa.prngTable = {}
faceless_void_time_lock_oaa.prngTable[5] = 0.038
faceless_void_time_lock_oaa.prngTable[10] = 0.01475
faceless_void_time_lock_oaa.prngTable[15] = 0.03221
faceless_void_time_lock_oaa.prngTable[20] = 0.0557
faceless_void_time_lock_oaa.prngTable[25] = 0.08475
faceless_void_time_lock_oaa.prngTable[30] = 0.11895
faceless_void_time_lock_oaa.prngTable[35] = 0.14628
faceless_void_time_lock_oaa.prngTable[40] = 0.18128
faceless_void_time_lock_oaa.prngTable[45] = 0.21867
faceless_void_time_lock_oaa.prngTable[50] = 0.25701
faceless_void_time_lock_oaa.prngTable[55] = 0.29509
faceless_void_time_lock_oaa.prngTable[60] = 0.33324
faceless_void_time_lock_oaa.prngTable[65] = 0.38109
faceless_void_time_lock_oaa.prngTable[70] = 0.42448
faceless_void_time_lock_oaa.prngTable[75] = 0.46134
faceless_void_time_lock_oaa.prngTable[80] = 0.50276

--------------------------------------------------------------------------------

function faceless_void_time_lock_oaa:GetIntrinsicModifierName()
  return "modifier_faceless_void_time_lock_oaa"
end

--------------------------------------------------------------------------------

modifier_faceless_void_time_lock_oaa = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_faceless_void_time_lock_oaa:IsHidden()
  return true
end

function modifier_faceless_void_time_lock_oaa:IsDebuff()
  return false
end

function modifier_faceless_void_time_lock_oaa:IsPurgable()
  return false
end

function modifier_faceless_void_time_lock_oaa:RemoveOnDeath()
  return false
end

--------------------------------------------------------------------------------

function modifier_faceless_void_time_lock_oaa:DeclareFunctions()
  local funcs = {
  MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
}

return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
  -- we're putting the stuff in this function because it's only run on a successful attack
  -- and it runs before OnAttackLanded, so we need to determine if a bash happens before then
  function modifier_faceless_void_time_lock_oaa:GetModifierProcAttack_BonusDamage_Magical( event )
    local parent = self:GetParent()

    -- no bash while broken or illusion
    if parent:PassivesDisabled() or parent:IsIllusion() then
      return 0
    end

    local target = event.target

    -- can't bash towers or wards, but can bash allies
    if UnitFilter( target, DOTA_UNIT_TARGET_TEAM_BOTH, bit.bor( DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC ), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, parent:GetTeamNumber() ) ~= UF_SUCCESS then
      return 0
    end

    local spell = self:GetAbility()

    -- don't bash while on cooldown
    if not spell:IsCooldownReady() then
      return 0
    end

    local chance = spell:GetSpecialValueFor( "chance_pct" )

    -- we're using the modifier's stack to store the amount of prng failures
    -- this could be something else but since this modifier is hidden anyway ...
    local prngMult = self:GetStackCount() + 1

    -- compared prng to slightly less prng
    if RandomFloat( 0.0, 1.0 ) <= ( spell.prngTable[chance] * prngMult ) then
      -- reset failure count
      self:SetStackCount( 0 )

      local duration = spell:GetSpecialValueFor( "duration" )

      -- creeps have a different duration
      if not target:IsHero() then
        duration = spell:GetSpecialValueFor( "duration_creep" )
      end

      -- apply the stun modifier
      target:AddNewModifier( parent, spell, "modifier_faceless_void_timelock_freeze", { duration = duration } )
      target:EmitSound( "Hero_FacelessVoid.TimeLockImpact" )

      -- use cooldown ( and mana, if necessary )
      spell:UseResources( true, true, true )

      -- because talents are dumb we need to manually get its value
      local damageTalent = 0

      local dtalent = parent:FindAbilityByName( "special_bonus_unique_faceless_void_3" )

      -- we also have to manually check if it's been skilled or not
      if dtalent and dtalent:GetLevel() > 0 then
        damageTalent = dtalent:GetSpecialValueFor( "value" )
      end

      -- apply the proc damage
      return spell:GetSpecialValueFor( "bonus_damage" ) + damageTalent

    else
      -- increment failure count
      self:SetStackCount( prngMult )

      return 0
    end
  end
end
