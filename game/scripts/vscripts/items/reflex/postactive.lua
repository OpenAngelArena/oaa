if not item_postactive then
  item_postactive = class({})
end

function item_postactive:OnSpellStart()
  local caster = self:GetCaster()

  -- Tests if given modifier is a debuff and purgable with a basic dispel
  --Applies the modifier to a test unit, purges the unit with a basic dispel affecting debuffs only,
  --then checks if the modifier was purged (All because IsDebuff and IsPurgable don't exist in the Lua API
  --for built-in modifiers)
  function IsPurgableDebuff(modifier)
    local testUnit = CreateUnitByName("npc_dota_lone_druid_bear1", Vector(0, 0, 0), false, caster, caster:GetOwner(), caster:GetTeamNumber())
    testUnit:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier:GetName(), nil)
    testUnit:Purge(false, true, true, false, false)
    local modifierIsPurgableDebuff = not testUnit:HasModifier(modifier:GetName())
    testUnit:ForceKill(false)
    return modifierIsPurgableDebuff
  end

  -- Compares the CreationTime of two modifiers and returns the older modifier
  function EarlierModifier(mod1, mod2)
    if mod1:GetCreationTime() <= mod2:GetCreationTime() then
      return mod1
    else
      return mod2
    end
  end

  local modifiers = caster:FindAllModifiers()
  local purgableDebuffs = filter(IsPurgableDebuff, iter(modifiers))

  if is_null(purgableDebuffs) then
    return
  end

  -- Find earliest applied debuff that can be purged by basic dispel
  local earliestPurgableDebuff = min_by(EarlierModifier, purgableDebuffs)

  earliestPurgableDebuff:Destroy()
end
