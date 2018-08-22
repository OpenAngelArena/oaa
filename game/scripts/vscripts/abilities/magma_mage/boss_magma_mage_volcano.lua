
LinkLuaModifier("modifier_boss_magma_mage_volcano", "abilities/magma_mage/modifier_boss_magma_mage_volcano.lua", LUA_MODIFIER_MOTION_VERTICAL) --knockup from torrent
LinkLuaModifier("modifier_stun_generic", "modifiers/modifier_stun_generic", LUA_MODIFIER_MOTION_NONE) --stun
LinkLuaModifier("modifier_boss_magma_mage_volcano_thinker", "abilities/magma_mage/modifier_boss_magma_mage_volcano_thinker.lua", LUA_MODIFIER_MOTION_NONE) --applied to volcano units to create magma pools
LinkLuaModifier("modifier_boss_magma_mage_volcano_thinker_child", "abilities/magma_mage/modifier_boss_magma_mage_volcano_thinker_child.lua", LUA_MODIFIER_MOTION_NONE) --applied to volcano units to make them invulnerable and pop in
LinkLuaModifier("modifier_boss_magma_mage_volcano_burning_effect", "abilities/magma_mage/modifier_boss_magma_mage_volcano_burning_effect.lua", LUA_MODIFIER_MOTION_NONE) --particles-only modifier for standing in magma

boss_magma_mage_volcano = class(AbilityBaseClass)

function boss_magma_mage_volcano:OnOwnerDied()
  self:KillAllVolcanos()
end

function boss_magma_mage_volcano:OnSpellStart()
  if IsServer() then
    --EmitSoundOn("",self:GetOwner())
    local hCaster = self:GetCaster()
    local nCastRange = self:GetSpecialValueFor("torrent_range")
    local nTorrents = self:GetSpecialValueFor("torrents_casted")

    local kv = {
    duration = self:GetSpecialValueFor("totem_duration_max"),
    }
    for i=1,nTorrents do

      --get random location within cast range
      local fRadians = RandomFloat(0,2*math.pi)
      local fDist = RandomFloat(0,nCastRange)
      local vLoc = hCaster:GetAbsOrigin()
      vLoc.x = vLoc.x + fDist*math.cos(fRadians)
      vLoc.y = vLoc.y + fDist*math.sin(fRadians)
      vLoc.z = GetGroundHeight(vLoc, nil)

      local hUnit = CreateUnitByName("npc_dota_magma_mage_volcano", vLoc, false, hCaster, hCaster, hCaster:GetTeamNumber())
      hUnit:AddNewModifier(hCaster,self,"modifier_boss_magma_mage_volcano_thinker", kv)
      hUnit:SetModelScale(0.01)
      local nMaxHealth = self:GetSpecialValueFor("totem_health")
      hUnit:SetBaseMaxHealth(nMaxHealth)
      hUnit:SetMaxHealth(nMaxHealth)
      hUnit:SetHealth(nMaxHealth)
      if self.zVolcanoName == nil then
        self.zVolcanoName = hUnit:GetName()
      end
    end

  end
end

--------------------------------------------------------------------------------

function boss_magma_mage_volcano:KillAllVolcanos() --kill all volcanos created by this ability's caster
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.zVolcanoName)
    local zModName = "modifier_boss_magma_mage_volcano_thinker"
    for _,volcano in pairs(volcanos) do
      if volcano:HasModifier( zModName ) and (volcano:FindModifierByName( zModName ):GetCaster() == self:GetCaster()) then
        volcano:ForceKill(false)
      end
    end
  end
  return
end

function boss_magma_mage_volcano:FindClosestMagmaPool() --returns the location (Vector) of the closest magma (edge of a magma pool)
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.zVolcanoName)
    local zModName = "modifier_boss_magma_mage_volcano_thinker"
    local hClosestVolcano = nil
    local nClosestEdgeDistance = math.huge
    for _,volcano in pairs(volcanos) do
      if volcano:HasModifier( zModName ) and (volcano:FindModifierByName( zModName ):GetCaster():GetTeamNumber() == self:GetCaster():GetTeamNumber()) then
        local EdgeDistance = (self:GetOwner():GetOrigin() - volcano:GetOrigin()):Length2D() - volcano:FindModifierByName( zModName ):GetMagmaRadius()
        if EdgeDistance < nClosestEdgeDistance then
          nClosestEdgeDistance = EdgeDistance
          hClosestVolcano = volcano
        end
      end
    end
    if hClosestVolcano == nil then
      return nil
    end
    local vEdgeLoc = self:GetOwner():GetAbsOrigin() + (hClosestVolcano:GetAbsOrigin()-self:GetOwner():GetAbsOrigin()):Normalized()*nClosestEdgeDistance
     DebugDrawLine(self:GetOwner():GetOrigin(),vEdgeLoc,0,255,255,true,10)
    return vEdgeLoc
  end
  return
end

function boss_magma_mage_volcano:GetNumVolcanos()
  if IsServer() then
    local volcanos = Entities:FindAllByName(self.zVolcanoName)
    local NumVolcanos = 0
    if #volcanos > 0 then
      local zModName = "modifier_boss_magma_mage_volcano_thinker"
      for _,volcano in pairs(volcanos) do
        if volcano:HasModifier( zModName ) and (volcano:FindModifierByName( zModName ):GetCaster():GetTeamNumber() == self:GetCaster():GetTeamNumber()) then
          NumVolcanos = NumVolcanos + 1
        end
      end
    end
    print("MAGMA_MAGE NumVolcanos", NumVolcanos)
    return NumVolcanos
  end
  return
end
