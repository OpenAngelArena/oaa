boss_alchemist_chemical_rage = class(AbilityBaseClass)

function boss_alchemist_chemical_rage:Precache(context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_alchemist.vsndevts", context)
end

function boss_alchemist_chemical_rage:OnSpellStart()
  local caster = self:GetCaster()

  local remove_stuns = true

  -- Strong Dispel (for the boss)
  caster:Purge(false, true, false, remove_stuns, remove_stuns)

  -- Disjoint disjointable/dodgeable projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- Sound
  caster:EmitSound("Hero_Alchemist.ChemicalRage.Cast")

  -- Applying the built-in modifier that controls the animations, sounds and body transformation.
  -- Applies modifier_alchemist_chemical_rage hopefully
  local transform_duration = self:GetSpecialValueFor("transformation_time")
  caster:AddNewModifier(caster, self, "modifier_alchemist_chemical_rage_transform", {duration = transform_duration})
end
