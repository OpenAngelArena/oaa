
eul_typhoon_oaa = class(AbilityBaseClass)

function eul_typhoon_oaa:GetCastRange(location, target)
  return self:GetSpecialValueFor("radius")
end

function eul_typhoon_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end
