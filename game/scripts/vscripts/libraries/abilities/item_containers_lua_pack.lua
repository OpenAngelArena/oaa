item_containers_lua_pack = class({})
--------------------------------------------------------------------------------

function item_containers_lua_pack:OnSpellStart()

  local container = self.container
  if IsValidContainer(container) then
    local pid = self:GetOwner():GetPlayerOwnerID()
    if container:IsOpen(pid) then
      container:Close(pid)
      self.toggled = false
    else
      container:Open(pid)
      self.toggled = true
    end
  else
    print("INVALID CONTAINER", container)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
