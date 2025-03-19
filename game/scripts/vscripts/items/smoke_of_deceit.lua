
item_smoke_of_deceit_oaa = class(ItemBaseClass)

function item_smoke_of_deceit_oaa:OnSpellStart()
  local caster = self:GetCaster()

  -- Sound
  caster:EmitSound("DOTA_Item.SmokeOfDeceit.Activate")

  local duration = self:GetSpecialValueFor("duration")
  local cd = self:GetSpecialValueFor("second_cast_cooldown")
  local ms = self:GetSpecialValueFor("bonus_movement_speed")
  local vis_radius = self:GetSpecialValueFor("visibility_radius")
  local spread_radius = self:GetSpecialValueFor("secondary_application_radius")
  local name = self:GetAbilityName()

  local allies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    caster,
    self:GetSpecialValueFor("application_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/items2_fx/smoke_of_deceit.vpcf", PATTACH_WORLDORIGIN, nil)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, Vector(800, 1, 800))
  ParticleManager:ReleaseParticleIndex(particle)

  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() then
      if not ally:HasModifier("modifier_smoke_of_deceit") then
        ally:AddNewModifier(caster, self, "modifier_smoke_of_deceit", {duration = duration, bonus_movement_speed = ms, visibility_radius = vis_radius, secondary_application_radius = spread_radius})

        -- Find Smoke in the allied inventory and trigger cd
        if ally ~= caster then
          for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
            local item = ally:GetItemInSlot(i)
            if item then
              if item:GetAbilityName() == name then
                item:StartCooldown(cd)
              end
            end
          end

          local neutral_item = ally:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
          if neutral_item then
            if neutral_item:GetAbilityName() == name then
              neutral_item:StartCooldown(cd)
            end
          end
        end
      end
    end
  end

  self:SpendCharge(0.1)
end
