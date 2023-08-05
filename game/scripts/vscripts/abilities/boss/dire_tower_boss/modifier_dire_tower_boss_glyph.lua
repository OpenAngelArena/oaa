modifier_dire_tower_boss_glyph = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:IsPurgable()
  return false
end

function modifier_dire_tower_boss_glyph:IsHidden()
  return false
end
--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:OnCreated( kv )
  if IsServer() then
    self.count = self:GetAbility():GetSpecialValueFor( "splitshot_units" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "splitshot_bonus_range" )

    self.parent = self:GetParent()
    self.projectile_name = self.parent:GetRangedProjectileName()
    self.projectile_speed = self.parent:GetProjectileSpeed()
  end
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:OnDestroy()
  if IsServer() then
  end
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }

  return funcs
end

function modifier_dire_tower_boss_glyph:GetModifierAttackSpeedBonus_Constant( params )
  return 10
end

function modifier_dire_tower_boss_glyph:GetModifierIncomingDamage_Percentage(params)
  return -100 -- Set the incoming damage percentage to 0 (0% damage taken)
end

function modifier_dire_tower_boss_glyph:GetPriority()
    return MODIFIER_PRIORITY_HIGH
end

function modifier_dire_tower_boss_glyph:OnRefresh( kv )
    self.count = self:GetAbility():GetSpecialValueFor( "splitshot_units" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "splitshot_bonus_range" )
end

function modifier_dire_tower_boss_glyph:OnAttack( keys )
    local unit = self:GetParent() -- Get the unit that has this modifier attached
    if unit:HasModifier("modifier_dire_tower_boss_glyph") then
      self:SplitShot( keys.target)
    end
end

function modifier_dire_tower_boss_glyph:OnProjectileHit(target, location)
  print("sprojectiles")
  local caster = self:GetCaster()

  -- If there is no target don't continue
  if not target then
    return
  end



  print("secondary shot")
  caster:PerformAttack(target, false, false, true, false, false, false, false)

end

function modifier_dire_tower_boss_glyph:SplitShot(target )
    local radius = self.parent:Script_GetAttackRange() + self.bonus_range
    local enemies = FindUnitsInRadius(
        self.parent:GetTeamNumber(),
        self.parent:GetOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_COURIER,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        0,
        false
    )

    local count = 0
    for _,enemy in pairs(enemies) do
        if enemy~=target then
            local info = {
                Target = enemy,
                Source = self.parent,
                Ability = self:GetAbility(),
                EffectName = self.projectile_name,
                iMoveSpeed = self.projectile_speed,
                bDodgeable = true,
                ExtraData = {
                  secondary_shot = true
                }
            }
            ProjectileManager:CreateTrackingProjectile(info)

            count = count + 1
            if count >= self.count then break end
        end
    end

    if count>0 then
        EmitSoundOn( "Hero_Medusa.AttackSplit", self.parent )
    end
end

--Split shot fully adapted from https://github.com/vulkantsk/SpellLibraryLua/blob/master/game/SpellLibraryLua/scripts/vscripts/heroes/medusa/split_shot.lua
