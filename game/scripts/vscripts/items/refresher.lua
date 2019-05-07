LinkLuaModifier("modifier_item_refresher_oaa", "items/refresher.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_refresher_2 = class(ItemBaseClass)

function item_refresher_2:GetIntrinsicModifierName()
  return "modifier_item_refresher_oaa"
end

function item_refresher_2:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound( "DOTA_Item.Refresher.Activate" )
  local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControlEnt( particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true )
  ParticleManager:ReleaseParticleIndex(particle)

  -- Put ability exemption in here
  local exempt_ability_table = {
    tinker_rearm = true,
    riki_permanent_invisibility = true,
    treant_natures_guise = true
  }

  -- Put item exemption in here
  local exempt_item_table = {
    item_refresher = true,
    item_refresher_2 = true,
    item_refresher_3 = true,
    item_refresher_4 = true,
    item_refresher_5 = true
  }

  -- Reset cooldown for abilities that is not rearm
  for i = 0, caster:GetAbilityCount() - 1 do
    local ability = caster:GetAbilityByIndex(i)
    if ability and not exempt_ability_table[ability:GetAbilityName()] then
      ability:RefreshCharges()
      ability:EndCooldown()
    end
  end

  -- Reset cooldown for items
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = caster:GetItemInSlot(i)
    if item and not exempt_item_table[item:GetAbilityName()] then
      item:EndCooldown()
    end
  end
end

function item_refresher_2:IsRefreshable()
  return false
end

item_refresher_4 = item_refresher_2
item_refresher_5 = item_refresher_2

--------------------------------------------------------------------------------

modifier_item_refresher_oaa = class({})

function modifier_item_refresher_oaa:IsHidden()
  return true
end

function modifier_item_refresher_oaa:IsPurgable()
  return false
end

function modifier_item_refresher_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_refresher_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_item_refresher_oaa:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor('bonus_health_regen')
end

function modifier_item_refresher_oaa:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_health')
end

function modifier_item_refresher_oaa:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor('bonus_mana')
end
