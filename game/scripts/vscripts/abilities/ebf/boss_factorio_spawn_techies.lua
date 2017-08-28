
boss_factorio_spawn_techies = class(AbilityBaseClass)

function boss_factorio_spawn_techies:OnChannelFinish(bInterrupted)
  if not bInterrupted then
    if IsServer() then
      self.iAutomatonCount = self.iAutomatonCount or 0
      if self.iAutomatonCount < self:GetSpecialValueFor("unit_limit") then
        self.iAutomatonCount = self.iAutomatonCount + 1
        iSpawnDistance = self:GetSpecialValueFor("unit_spawn_distance")
        hCaster = self:GetCaster()
        vPosition = hCaster:GetAbsOrigin()
        vPosition = vPosition + RandomVector(RandomInt(0, iSpawnDistance))
        iTeamID = hCaster:GetTeam()

        sParticleName = "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf"

        hUnit = CreateUnitByName(
          "npc_dota_boss_automaton",
          vPosition,
          false,
          hCaster,
          hCaster,
          iTeamID
        )

        hUnit:OnDeath(function(keys)
          self.iAutomatonCount = self.iAutomatonCount - 1
        end)

        iParticle = ParticleManager:CreateParticle(sParticleName, PATTACH_ABSORIGIN_FOLLOW, hUnit)
        ParticleManager:SetParticleControl(iParticle, 1, Vector(50, 100, 0))
        ParticleManager:SetParticleControl(iParticle, 2, Vector(4, 10, .5))
        ParticleManager:SetParticleControl(iParticle, 3, Vector(20, 200, 0))

        EmitSoundOn("Ability.SummonUndeadSuccess", hCaster)
      end
    end
  end
end
