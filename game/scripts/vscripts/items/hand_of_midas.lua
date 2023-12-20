-- Re-implementation of Hand of Midas because vanilla code doesn't work with multiple levels for whatever reason
-- Code adapted from Angel Arena Blackstar's implementation of Hand of Midas

item_hand_of_midas_1 = class(ItemBaseClass)

function item_hand_of_midas_1:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_hand_of_midas_1:CastFilterResultTarget(target)
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
   -- Don't allow targeting Necronomicon units or Undying zombies
  if defaultFilterResult == UF_SUCCESS then
    if string.sub(target:GetUnitName(), 1, 21) == "npc_dota_necronomicon" then
      return UF_FAIL_CUSTOM
    elseif IsServer() then
      if target:IsZombie() then
        return UF_FAIL_CUSTOM
      end
    end
  end

  return defaultFilterResult
end

function item_hand_of_midas_1:GetCustomCastErrorTarget(target)
  return "#dota_hud_error_cannot_transmute"
end

function item_hand_of_midas_1:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local xpMult = self:GetSpecialValueFor("xp_multiplier")
  --local defaultMaxGoldBounty = target:GetMaximumGoldBounty()
  --local defaultMinGoldBounty = target:GetMinimumGoldBounty()
  local defaultXPBounty = target:GetDeathXP()
  local bonusGold = self:GetSpecialValueFor("bonus_gold")
  local player = caster:GetPlayerOwner()
  local playerID = caster:GetPlayerOwnerID()

  -- Midas Particle
  local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
  ParticleManager:ReleaseParticleIndex(midas_particle)

  if player then
    -- Overhead gold amount popup
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, target, bonusGold, player)
    -- If the Hand of Midas user is a Spirit Bear or Arc Warden Tempest Double:
    if not caster:IsHero() or caster:IsTempestDouble() then
      caster = player:GetAssignedHero()
    end
  end

  -- Midas Sound
  target:EmitSound("DOTA_Item.Hand_Of_Midas")

  -- Give experience to the main hero; (xpMult-1) because we are NOT setting Death XP to 0 later
  if caster.AddExperience then
    caster:AddExperience(defaultXPBounty*(xpMult-1), DOTA_ModifyXP_CreepKill, false, false)
  end

  -- Giving only bonus gold as reliable gold to the player that used Hand of Midas
  Gold:ModifyGold(playerID, bonusGold, true, DOTA_ModifyGold_CreepKill)

  --target:SetDeathXP(0)           -- setting this to 0 will mess up OAA Mud Golems
  --target:SetMinimumGoldBounty(0) -- setting this to 0 will mess up OAA Mud Golems
  --target:SetMaximumGoldBounty(0) -- setting this to 0 will mess up OAA Mud Golems

  target:Kill(self, caster)
end
