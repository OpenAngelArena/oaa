oaa_rearm = class({})

function oaa_rearm:OnSpellStart()
  local caster = self:GetCaster()

  EmitSoundOn("Hero_Tinker.Rearm", caster)
  local particleName = "particles/units/heroes/hero_tinker/tinker_rearm.vpcf"
  self.particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetOrigin(), true)
  ParticleManager:SetParticleControlEnt(self.particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack3", caster:GetOrigin(), true)
end

function oaa_rearm:GetChannelAnimation()
  local animationLevel = math.min(self:GetLevel(), 3)
  return _G["ACT_DOTA_TINKER_REARM" .. animationLevel]
end

function oaa_rearm:OnChannelFinish(bInterrupted)
  local caster = self:GetCaster()

  ParticleManager:DestroyParticle(self.particle, false)
  ParticleManager:ReleaseParticleIndex(self.particle)
  self.particle = nil

  StopSoundOn("Hero_Tinker.Rearm", caster)

  -- Put ability exemption in here
  local exempt_ability_table = {
    oaa_rearm = true
  }

  -- Put item exemption in here
  local exempt_item_table = {
    item_black_king_bar = true,
    item_charge_bkb = true,
    item_arcane_boots = true,
    item_hand_of_midas = true,
    item_hand_of_midas_2 = true,
    item_hand_of_midas_3 = true,
    item_helm_of_the_dominator = true,
    item_pipe = true,
    item_pipe_2 = true,
    item_refresher = true,
    item_refresher_2 = true,
    item_refresher_core = true,
    item_refresher_core_2 = true,
    item_refresher_core_3 = true,
    item_sphere = true,
    item_sphere_2 = true,
    item_bottle = true,
    item_infinite_bottle = true,
    item_necronomicon = true,
    item_necronomicon_2 = true,
    item_necronomicon_3 = true,
    item_necronomicon_4 = true,
    item_necronomicon_5 = true,
    item_reactive = true,
    item_reactive_2a = true,
    item_reactive_2b = true,
    item_reactive_3a = true,
    item_reactive_3b = true,
    item_reactive_3c = true,
    item_preemptive = true,
    item_preemptive_2a = true,
    item_preemptive_2b = true,
    item_preemptive_3a = true,
    item_preemptive_3b = true,
    item_preemptive_3c = true,
    item_postactive = true,
    item_postactive_2a = true,
    item_postactive_2b = true,
    item_postactive_3a = true,
    item_postactive_3b = true,
    item_postactive_3c = true
  }

  if not bInterrupted then
    -- Reset cooldown for abilities that is not rearm
    for i = 0, caster:GetAbilityCount() - 1 do
      local ability = caster:GetAbilityByIndex(i)
      if ability and not exempt_ability_table[ability:GetAbilityName()] then
        ability:EndCooldown()
      end
    end

    -- Reset cooldown for items
    for i = 0, 5 do
      local item = caster:GetItemInSlot(i)
      if item and not exempt_item_table[item:GetAbilityName()] then
        item:EndCooldown()
      end
    end
  end
end
