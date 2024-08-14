LinkLuaModifier("modifier_generic_projectile", "modifiers/modifier_generic_projectile.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spiders_spiderball_slow", "abilities/boss/spider_boss/spider_boss_spidershot.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------

spider_boss_spidershot = class(AbilityBaseClass)

------------------------------------------------------------------------------------

function spider_boss_spidershot:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

------------------------------------------------------------------------------------

function spider_boss_spidershot:OnSpellStart(keys)
  local caster = self:GetCaster()
  local explode_delay = self:GetSpecialValueFor("explode_time")
  local number_of_spiders = self:GetSpecialValueFor("spiders_count")

  if self.target_points then
    caster:EmitSound("hero_ursa.attack")

    for _, target in pairs(self.target_points) do
      local indicator = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_generic_wardspot_model.vpcf", PATTACH_CUSTOMORIGIN, caster)
      ParticleManager:SetParticleControl(indicator, 2, target)

      local origin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hitloc")) + (caster:GetForwardVector() * 30)

      local ball = CreateUnitByName("npc_dota_boss_spiders_spiderball", origin, false, caster, caster, caster:GetTeamNumber())

      local projectileModifier = ball:AddNewModifier(caster, self, "modifier_generic_projectile", {})
      local projectileTable = {
        onLandedCallback = function ()
          local smoke = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_blast_off_fire_smallmoketrail.vpcf", PATTACH_POINT, ball)
          ParticleManager:ReleaseParticleIndex(smoke)

          if indicator then
            ParticleManager:DestroyParticle(indicator, true)
            ParticleManager:ReleaseParticleIndex(indicator)
          end

          Timers:CreateTimer(explode_delay, function ()
            if ball and not ball:IsNull() then
              if ball:IsAlive() then
                EmitSoundOnLocationWithCaster(ball:GetAbsOrigin(), "Hero_Techies.Suicide", caster)

                local explosion = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf", PATTACH_CUSTOMORIGIN, caster)
                ParticleManager:SetParticleControl(explosion, 0, ball:GetAbsOrigin())
                ParticleManager:SetParticleControl(explosion, 3, ball:GetAbsOrigin())
                ParticleManager:ReleaseParticleIndex(explosion)

                for i=1, number_of_spiders do
                  PrecacheUnitByNameAsync("npc_dota_boss_spiders_spider", function ()
                    local spider = CreateUnitByName("npc_dota_boss_spiders_spider", ball:GetAbsOrigin() + RandomVector(32), true, caster, caster, caster:GetTeamNumber())
                    local spawn = ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_spiderlings_spawn_b_lv.vpcf", PATTACH_POINT, spider)
                    ParticleManager:ReleaseParticleIndex(spawn)
                  end, 0)
                end

                -- Instead of UTIL_Remove:
                ball:AddNoDraw()
                ball:ForceKillOAA(false)
              end
            end
          end)
        end,
        onUnitHitCallback = function (v)
          if not v:IsMagicImmune() and not v:IsDebuffImmune() then
            v:AddNewModifier(caster, self, "modifier_boss_spiders_spiderball_slow", { duration = self:GetSpecialValueFor("impact_slow_duration") })

            local damageTable = {
              victim = v,
              attacker = caster,
              damage = self:GetSpecialValueFor("impact_damage"),
              damage_type = self:GetAbilityDamageType(),
              ability = self
            }

            ApplyDamage(damageTable)

            if v and not v:IsNull() and v:IsAlive() then
              -- Particle
              local impact = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_base_attack_impact.vpcf", PATTACH_POINT, v)
              ParticleManager:SetParticleControlEnt(impact, 1, v, PATTACH_POINT, "attach_hitloc", v:GetAbsOrigin(), true)
              ParticleManager:ReleaseParticleIndex(impact)
              -- Sound
              v:EmitSound("Hero_Broodmother.SpawnSpiderlingsImpact")
            end
          end
        end,
        onDiedCallback = function ()
          if indicator then
            ParticleManager:DestroyParticle(indicator, true)
            ParticleManager:ReleaseParticleIndex(indicator)
          end

          if ball and not ball:IsNull() then
            ball:AddNoDraw()
          end
        end,
        hitRadius = 128,
        speed = self:GetSpecialValueFor("projectile_speed"),
        origin = origin,
        target = target,
        height = self:GetSpecialValueFor("projectile_height"),
        selectable = true,
        noInvul = true
      }
      projectileModifier:InitProjectile(projectileTable)
    end

    self.target_points = nil
  end
end

------------------------------------------------------------------------------------

modifier_boss_spiders_spiderball_slow = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_spiders_spiderball_slow:IsHidden()
  return false
end

function modifier_boss_spiders_spiderball_slow:IsDebuff()
  return true
end

function modifier_boss_spiders_spiderball_slow:IsPurgable()
  return true
end

------------------------------------------------------------------------------------

function modifier_boss_spiders_spiderball_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

------------------------------------------------------------------------------------

function modifier_boss_spiders_spiderball_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("impact_slow_rate")
end
