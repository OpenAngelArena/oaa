modifier_passive_gpm = class(ModifierBaseClass)

function modifier_passive_gpm:OnCreated()
  self:StartIntervalThink(1)
end

modifier_passive_gpm.OnRefresh = modifier_passive_gpm.OnCreated

function modifier_passive_gpm:GetTexture()
  local ability = self:GetAbility()
  if ability == nil then
    return self.BaseClass.GetTexture(self)
  end

  if ability:GetAbilityTextureName() then
    return ability:GetAbilityTextureName()
  end
  return ability:GetAbilityName()
end

if IsServer() then
  function modifier_passive_gpm:OnIntervalThink()
    if not PlayerResource then
      -- sometimes for no reason the player resource isn't there, usually only at the start of games in tools mode
      return
    end
    local caster = self:GetCaster()
    local gpm = self:GetAbility():GetSpecialValueFor('bonus_gold_per_minute')

    -- Don't give gold on illusions, Tempest Doubles, or Meepo clones
    if caster:IsIllusion() or caster:IsTempestDouble() or caster:IsClone() then
      return
    end
    Gold:ModifyGold(caster:GetPlayerOwnerID(), gpm / 60, true, DOTA_ModifyGold_GameTick)
  end
end

function modifier_passive_gpm:IsHidden()
  return false
end

function modifier_passive_gpm:IsDebuff()
  return false
end

function modifier_passive_gpm:IsPurgable()
  return false
end
