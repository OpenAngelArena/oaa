if hero == nil then
  hero = PlayerResource:GetPlayer(0):GetAssignedHero()
  Physics:Unit(hero)
end

--[[if true then
  boxcollider4 = Physics:AddCollider("aabox2", Physics:ColliderFromProfile("aaboxreflect"))
  boxcollider4.box = {Vector(-400,-800,0), Vector(-200,-200,500)}
  boxcollider4.draw = true
  boxcollider4.test = function(self, unit)
    return IsPhysicsUnit(unit)
  end
  return
end]]

if testCount == nil then
  if not enigma then
    enigma = CreateUnitByName('npc_dummy_unit', Vector(0,0,0), true, hero, hero, hero:GetTeamNumber())
    enigma:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
    enigma:SetModel('models/heroes/enigma/enigma.vmdl')
    enigma:SetOriginalModel('models/heroes/enigma/enigma.vmdl')

    Physics:Unit(enigma)

    planet1 = CreateUnitByName('npc_dummy_unit', Vector(0,0,0), true, hero, hero, hero:GetTeamNumber())
    planet1:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
    planet1:SetModel('models/props_gameplay/rune_doubledamage01.vmdl')
    planet1:SetOriginalModel('models/props_gameplay/rune_doubledamage01.vmdl')
    Physics:Unit(planet1)


    planet2 = CreateUnitByName('npc_dummy_unit', Vector(0,0,0), true, hero, hero, hero:GetTeamNumber())
    planet2:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
    planet2:SetModel('models/props_gameplay/rune_haste01.vmdl')
    planet2:SetOriginalModel('models/props_gameplay/rune_haste01.vmdl')
    Physics:Unit(planet2)

    planet3 = CreateUnitByName('npc_dummy_unit', Vector(0,0,0), true, hero, hero, hero:GetTeamNumber())
    planet3:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
    planet3:SetModel('models/props_gameplay/rune_illusion01.vmdl')
    planet3:SetOriginalModel('models/props_gameplay/rune_illusion01.vmdl')
    Physics:Unit(planet3)
  end

  Timers:CreateTimer(function()
    enigma:SetAbsOrigin(Vector(0,0,400))

    enigma:RemoveCollider()
    collider = enigma:AddColliderFromProfile("gravity")
    collider.radius = 1000
    collider.fullRadius = 0
    collider.force = 5000
    collider.linear = false
    collider.test = function(self, collider, collided)
      return IsPhysicsUnit(collided) and collided.GetUnitName and collided:GetUnitName() == "npc_dummy_unit"
    end

    planet1:SetAbsOrigin(Vector(-500,0,400))
    planet2:SetAbsOrigin(Vector(300,0,400))
    planet3:SetAbsOrigin(Vector(0,100,400))

    planet1:SetPhysicsVelocity(Vector(0,600,0))
    planet2:SetPhysicsVelocity(Vector(0,0,1000))
    planet3:SetPhysicsVelocity(Vector(1,0,1):Normalized() * 1200)
    planet1:SetPhysicsFriction(0)
    planet2:SetPhysicsFriction(0)
    planet3:SetPhysicsFriction(0)
  end)

  testCount = -1
end

-- Default block others
if testCount == 0 then
  enigma:RemoveSelf()
  planet1:RemoveSelf()
  planet2:RemoveSelf()
  planet3:RemoveSelf()
  if testUnit == nil then
    --PrecacheUnitByNameAsync("npc_dota_hero_slark", function(...) end)
    testUnit = CreateUnitByName('npc_dummy_blank', hero:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
    testUnit:SetModel('models/heroes/viper/viper.vmdl')
    testUnit:SetOriginalModel('models/heroes/viper/viper.vmdl')

    testUnit:SetControllableByPlayer(0, true)
    Physics:Unit(testUnit)

    ring = nil
    ring2 = nil
    ring3 = nil
    ring4 = nil
    ring5 = nil
    ring6 = nil

    box1 = nil
    box2 = nil
    box3 = nil

    mass = 100
  end

  if testUnit2 == nil then
    --PrecacheUnitByNameAsync("npc_dota_hero_slark", function(...) end)
    testUnit2 = CreateUnitByName('npc_dummy_blank', hero:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
    --testUnit2:SetModel('models/heroes/viper/viper.vmdl')
    --testUnit2:SetOriginalModel('models/heroes/viper/viper.vmdl')
    testUnit2:SetModel('models/heroes/abaddon/abaddon.vmdl')
    testUnit2:SetOriginalModel('models/heroes/abaddon/abaddon.vmdl')

    testUnit2:SetControllableByPlayer(0, true)
    testUnit2:SetRenderColor(200,0,0)
    Physics:Unit(testUnit2)
  end

  collider = hero:AddColliderFromProfile("blocker")
  collider.radius = 400
  collider.draw = {color = Vector(200,200,200), alpha = 5}

  ring = {unit = hero, radius = 400, alpha = 0, rgb = Vector(200,50,50)}

  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
  collider.postaction = function(self, collider, collided)
    print("post: " .. collided:GetName() .. " -- " .. VectorDistance(collider:GetAbsOrigin(), collided:GetAbsOrigin()))
  end
  collider.preaction = function(self, collider, collided)
    print("pre: " .. collided:GetName() .. " -- " .. VectorDistance(collider:GetAbsOrigin(), collided:GetAbsOrigin()))
  end


  Physics:RemoveCollider("testbox")
  boxcollider = Physics:AddCollider("testbox", Physics:ColliderFromProfile("boxblocker"))
  boxcollider.box = {Vector(-200,0,0), Vector(0,0,0), Vector(-200,1000,500)}
  boxcollider.test = function(self, unit)  
    return IsPhysicsUnit(unit)
  end
  boxcollider.draw = {color = Vector(50,200,50), alpha = 5}
  units = {}
  --[[for i=1,4 do
    units[i] = CreateUnitByName('npc_dummy_unit', hero:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
    --units[i]:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
    units[i]:SetModel("models/props_gameplay/rune_doubledamage01.vmdl")
    units[i]:SetOriginalModel("models/props_gameplay/rune_doubledamage01.vmdl")
    units[i]:AddNewModifier(units[i], nil, "modifier_phased", {})
  end]]

  Physics:RemoveCollider("testbox2")
  boxcollider2 = Physics:AddCollider("testbox2", Physics:ColliderFromProfile("boxreflect"))
  boxcollider2.box = {Vector(-100,700,0), Vector(1000,700,0), Vector(-100,900,500)}
  boxcollider2.test = function(self, unit)
    return IsPhysicsUnit(unit)
  end
  boxcollider2.draw = {color = Vector(200,50,200), alpha = 5}
    
end

-- Self-blocker
if testCount == 1 then
  collider.moveSelf = true
end

-- Half radius
if testCount == 2 then
  collider.radius = 200
end

--testCount = 3
-- Remove collider, new collider
if testCount == 3 then
  hero:RemoveCollider()
  Timers:CreateTimer("timer", {
    callback = function()
      local unit = CreateUnitByName('npc_dummy_unit', hero:GetAbsOrigin() + hero:GetForwardVector() * 100, true, hero, hero, hero:GetTeamNumber())
      unit:FindAbilityByName("reflex_dummy_unit"):SetLevel(1)
      unit:SetModel("models/props_gameplay/rune_doubledamage01.vmdl")
      unit:SetOriginalModel("models/props_gameplay/rune_doubledamage01.vmdl")

      unit:AddNewModifier(unit, nil, "modifier_phased", {})

      Physics:Unit(unit)
      unit:SetMass(mass)
      local projCollider = unit:AddColliderFromProfile("delete")
      projCollider.draw = {color=Vector(50,50,200), alpha=0}
      projCollider.radius = 100
      projCollider.test = function(self, collider, collided)
        return IsPhysicsUnit(collided) and collided.GetUnitName ~= nil and collided:GetUnitName() == "npc_dummy_blank"
      end

      --unit:SetPhysicsVelocityMax(1000)

      unit:SetFriction(0)
      unit:AddPhysicsVelocity(hero:GetForwardVector() * 3000)
      unit:OnPhysicsFrame(function(unit)
        local dir = testUnit:GetAbsOrigin() - unit:GetAbsOrigin()
        dir = dir:Normalized()

        unit:SetPhysicsAcceleration(dir * 3000)
        end)
      return 1
    end
    })
end

if testCount == 4 then
  Physics:RemoveCollider("testbox")
  boxcollider = Physics:AddCollider("testbox", Physics:ColliderFromProfile("boxreflect"))
  boxcollider.box = {Vector(-100,550,0), 
    RotatePosition(Vector(-100,550,0), QAngle(0,-15,0), Vector(-100,350,0)), 
    RotatePosition(Vector(-100,550,0), QAngle(0,-15,0), Vector(1000,550,0)) + Vector(0,0,500)}
  boxcollider.test = function(self, unit)
    return IsPhysicsUnit(unit)
  end
  boxcollider.draw = {color = Vector(200,200,200), alpha = 5}
end

if testCount == 5 then
  collider = hero:AddColliderFromProfile("blocker")

  collider.radius = 400
  collider.draw = {color = Vector(200,50,50), alpha = 0}
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 6 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("gravity")
  collider.draw = {color = Vector(200,50,200), alpha = 0}
  collider.radius = 1000
  collider.force = 1000
  collider.linear = false
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end
if testCount == 7 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("gravity")
  collider.draw = {color = Vector(100,50,200), alpha = 0}
  collider.radius = 1000
  collider.fullRadius = 500
  collider.force = 1000
  collider.linear = true
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 8 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("gravity")
  collider.draw = {color = Vector(50,200,50), alpha = 0}
  collider.radius = 1500
  collider.fullRadius = 1000
  collider.minRadius = 750
  collider.force = 1000
  collider.linear = true
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 9 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("repel")
  collider.draw = {color = Vector(200,200,50), alpha = 0}
  collider.radius = 1000
  collider.force = 1000
  collider.linear = false
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 10 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("reflect")
  collider.draw = {color = Vector(200,200,200), alpha = 0}
  collider.radius = 200
  collider.multiplier = 1
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 11 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("momentum")
  collider.draw = {color = Vector(0,0,0), alpha = 0}
  collider.radius = 200
  collider.blockRadius = 100
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 12 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("momentum")
  collider.draw = {color = Vector(0,0,0), alpha = 0}
  collider.radius = 200
  collider.blockRadius = 200
  collider.test = function(self, collider, collided)
  mass = 5
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 13 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("momentum")
  collider.draw = {color = Vector(0,0,0), alpha = 0}
  collider.radius = 200
  collider.blockRadius = 200
  collider.elasticity = 0
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 14 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("momentum")
  collider.draw = {color = Vector(50,200,50), alpha = 0}
  collider.radius = 200
  collider.blockRadius = 0
  collider.elasticity = 0
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end

if testCount == 15 then
  hero:RemoveCollider()
  collider = hero:AddColliderFromProfile("gravity")
  collider.draw = {color = Vector(50,200,50), alpha = 0}
  collider.radius = 1500
  collider.fullRadius = 1000
  collider.minRadius = 750
  collider.force = 1000
  collider.linear = true
  collider.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end

  collider2 = hero:AddColliderFromProfile("blocker")
  collider.draw = {color = Vector(200,200,50), alpha = 0}
  collider2.radius = 400
  collider2.test = function(self, collider, collided)
    return IsPhysicsUnit(collided) or (collided.IsRealHero and collided:IsRealHero())
  end
end


print(testCount)
testCount = testCount + 1

--PrintTable(Physics.Colliders)

print('0----0')
--print(testUnit:GetModelRadius())
--print(testUnit:BoundingRadius2D())
--print(testUnit:GetHullRadius())
--print(testUnit:GetPaddedCollisionRadius())
PrintTable(Physics.Colliders)
print('0----0')

hero:Hibernate(false)