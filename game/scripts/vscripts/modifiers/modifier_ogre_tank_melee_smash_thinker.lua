
modifier_ogre_tank_melee_smash_thinker = class(ModifierBaseClass)

function modifier_ogre_tank_melee_smash_thinker:OnCreated(kv)
  if IsServer() then
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      self.impact_radius = ability:GetSpecialValueFor("impact_radius")
      self.stun_duration = ability:GetSpecialValueFor("stun_duration")
      self.damage = ability:GetSpecialValueFor("damage")
    end

    self:StartIntervalThink(0.01)
  end
end

function modifier_ogre_tank_melee_smash_thinker:OnIntervalThink()
  if IsServer() then
    local caster = self:GetCaster()
    if caster == nil or caster:IsNull() or (not caster:IsAlive()) or caster:IsStunned() then
      -- If caster is nil, dead, or stunned, remove smash thinker
      self:StartIntervalThink(-1)
      local parent = self:GetParent()
      if parent and not parent:IsNull() then
        UTIL_Remove(parent)
      end
    end
  end
end

function modifier_ogre_tank_melee_smash_thinker:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()
    local parent = self:GetParent()
    if caster and not caster:IsNull() and caster:IsAlive() then
      EmitSoundOnLocationWithCaster(parent:GetOrigin(), "OgreTank.GroundSmash", caster)
      local smashParticle = ParticleManager:CreateParticle("particles/test_particle/ogre_melee_smash.vpcf", PATTACH_WORLDORIGIN, caster)
      ParticleManager:SetParticleControl(smashParticle, 0, parent:GetOrigin())
      ParticleManager:SetParticleControl(smashParticle, 1, Vector(self.impact_radius, self.impact_radius, self.impact_radius))
      ParticleManager:ReleaseParticleIndex(smashParticle)

      local enemies = FindUnitsInRadius(caster:GetTeamNumber(), parent:GetOrigin(), parent, self.impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
      for _,enemy in pairs(enemies) do
        if enemy and not enemy:IsInvulnerable() then
          local damageInfo =
          {
            victim = enemy,
            attacker = caster,
            damage = self.damage,
            damage_type = DAMAGE_TYPE_PHYSICAL,
            ability = self:GetAbility(),
          }

          ApplyDamage(damageInfo)
          if not enemy:IsAlive() then
            local critParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
            ParticleManager:SetParticleControlEnt(critParticle, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetOrigin(), true)
            ParticleManager:SetParticleControl(critParticle, 1, enemy:GetOrigin())
            ParticleManager:SetParticleControlForward(critParticle, 1, -caster:GetForwardVector())
            ParticleManager:SetParticleControlEnt(critParticle, 10, enemy, PATTACH_ABSORIGIN_FOLLOW, nil, enemy:GetOrigin(), true)
            ParticleManager:ReleaseParticleIndex(critParticle)

            caster:EmitSound("Dungeon.BloodSplatterImpact")
          else
            enemy:AddNewModifier(caster, self:GetAbility(), "modifier_stunned", {duration = self.stun_duration})
          end
        end
      end
    end

    ScreenShake(parent:GetOrigin(), 10.0, 100.0, 0.5, 1300.0, 0, true)

    if parent and not parent:IsNull() then
      UTIL_Remove(parent)
    end
  end
end
