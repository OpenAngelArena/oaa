neutral_mana_burn_oaa = class(AbilityBaseClass)

function neutral_mana_burn_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  local base = self:GetSpecialValueFor("mana_base")
  local mana_pct = self:GetSpecialValueFor("mana_pct")

  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    -- Don't burn mana on spell immune or debuff immune enemies
    if enemy and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      local current_mana = enemy:GetMana()
      local max_mana = enemy:GetMaxMana()
      local mana_to_remove = math.min(current_mana, base + max_mana * mana_pct * 0.01)
      enemy:ReduceMana(mana_to_remove, self)
    end
  end
end
