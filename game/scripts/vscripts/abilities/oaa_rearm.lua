oaa_rearm = class(AbilityBaseClass)

function oaa_rearm:OnSpellStart()
  local caster = self:GetCaster()

  caster:EmitSound("Hero_Tinker.Rearm")
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

  caster:StopSound("Hero_Tinker.Rearm")

  -- Put ability exemption in here
  local exempt_ability_table = {
    oaa_rearm = true
  }

  -- Put item exemption in here
  local exempt_item_table = {
    item_bottle = true,
    item_infinite_bottle = true,
    item_arcane_boots = true,
    item_greater_arcane_boots = true,
    item_greater_arcane_boots_2 = true,
    item_greater_arcane_boots_3 = true,
    item_greater_arcane_boots_4 = true,
    item_greater_arcane_boots_5 = true,
    item_guardian_greaves = true,
    item_greater_guardian_greaves = true,
    item_greater_guardian_greaves_2 = true,
    item_greater_guardian_greaves_3 = true,
    item_greater_guardian_greaves_4 = true,
    item_greater_guardian_greaves_5 = true,
    item_aeon_disk = true,
    item_aeon_disk_2 = true,
    item_aeon_disk_3 = true,
    item_aeon_disk_4 = true,
    item_aeon_disk_5 = true,
    item_black_king_bar_1 = true,
    item_black_king_bar_2 = true,
    item_black_king_bar_3 = true,
    item_black_king_bar_4 = true,
    item_black_king_bar_5 = true,
    item_bubble_orb_1 = true,
    item_bubble_orb_2 = true,
    item_charge_bkb_1 = true,
    item_charge_bkb_2 = true,
    item_charge_bkb_3 = true,
    item_charge_bkb_4 = true,
    item_charge_bkb_5 = true,
    item_dispel_orb_1 = true,
    item_dispel_orb_2 = true,
    item_dispel_orb_3 = true,
    item_enrage_crystal_1 = true,
    item_enrage_crystal_2 = true,
    item_enrage_crystal_3 = true,
    item_hand_of_midas_1 = true,
    item_hand_of_midas_2 = true,
    item_hand_of_midas_3 = true,
    item_helm_of_the_dominator = true,
    item_helm_of_the_dominator_2 = true,
    item_helm_of_the_dominator_3 = true,
    item_helm_of_the_dominator_4 = true,
    item_helm_of_the_dominator_5 = true,
    item_meteor_hammer = true,
    item_meteor_hammer_2 = true,
    item_meteor_hammer_3 = true,
    item_meteor_hammer_4 = true,
    item_meteor_hammer_5 = true,
    item_necronomicon = true,
    item_necronomicon_2 = true,
    item_necronomicon_3 = true,
    item_necronomicon_4 = true,
    item_necronomicon_5 = true,
    item_pipe = true,
    item_pipe_2 = true,
    item_pipe_3 = true,
    item_pipe_4 = true,
    item_pipe_5 = true,
    item_postactive_2a = true,
    item_postactive_3a = true,
    item_reactive_2b = true,
    item_reactive_3b = true,
    item_reactive_3c = true,
    item_reduction_orb_1 = true,
    item_reduction_orb_2 = true,
    item_reduction_orb_3 = true,
    item_reflection_shard_1 = true,
    item_reflection_shard_2 = true,
    item_reflection_shard_3 = true,
    item_refresher = true,
    item_refresher_2 = true,
    item_refresher_core = true,
    item_refresher_core_2 = true,
    item_refresher_core_3 = true,
    item_regen_crystal_1 = true,
    item_regen_crystal_2 = true,
    item_regen_crystal_3 = true,
    item_sphere = true,
    item_sphere_2 = true,
    item_sphere_3 = true,
    item_sphere_4 = true,
    item_sphere_5 = true
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
