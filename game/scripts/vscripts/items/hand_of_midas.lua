-- Re-implementation of Hand of Midas because vanilla code doesn't work with multiple levels for whatever reason
-- Code adapted from Angel Arena Blackstar's implementation of Hand of Midas

item_hand_of_midas_1 = class(ItemBaseClass)

function item_hand_of_midas_1:GetIntrinsicModifierName()
  return "modifier_item_hand_of_midas"
end

function item_hand_of_midas_1:CastFilterResultTarget(target)
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  if defaultFilterResult ~= UF_SUCCESS then
    return defaultFilterResult
  -- Don't allow targeting Necronomicon units
  elseif string.sub(target:GetUnitName(), 1, 21) == "npc_dota_necronomicon" then
    return UF_FAIL_CUSTOM
  elseif IsServer() then
    return UF_SUCCESS
  end
end

function item_hand_of_midas_1:GetCustomCastErrorTarget(target)
  return "#dota_hud_error_cannot_transmute"
end

function item_hand_of_midas_1:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local xpMult = self:GetSpecialValueFor("xp_multiplier")
  local defaultGoldBounty = target:GetGoldBounty()
  local bonusGold = math.max(self:GetSpecialValueFor("bonus_gold"), defaultGoldBounty)
  local player = caster:GetPlayerOwner()
  local playerID = caster:GetPlayerOwnerID()

  if caster.AddExperience then
    caster:AddExperience(target:GetDeathXP() * xpMult, DOTA_ModifyXP_CreepKill, false, false)
  end
  PlayerResource:ModifyGold(playerID, bonusGold, true, DOTA_ModifyGold_CreepKill)
  if player then
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, target, bonusGold, player)
  end
  target:EmitSound("DOTA_Item.Hand_Of_Midas")
  local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
  ParticleManager:ReleaseParticleIndex(midas_particle)

  target:SetDeathXP(0)
  target:SetMinimumGoldBounty(0)
  target:SetMaximumGoldBounty(0)

  target:Kill(self, caster)
end

item_hand_of_midas_2 = class(item_hand_of_midas_1)
item_hand_of_midas_3 = class(item_hand_of_midas_1)
