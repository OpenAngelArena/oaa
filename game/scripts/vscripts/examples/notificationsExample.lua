-- Send a notification to all players that displays up top for 5 seconds
Notifications:TopToAll({text="Top Notification for 5 seconds ", duration=5.0})
-- Send a notification to playerID 0 which will display up top for 9 seconds and be green, on the same line as the previous notification
Notifications:Top(0, {text="GREEEENNNN", duration=9, style={color="green"}, continue=true})

-- Display 3 styles of hero icons on the same line for 5 seconds.
Notifications:TopToAll({hero="npc_dota_hero_axe", duration=5.0})
Notifications:TopToAll({hero="npc_dota_hero_axe", imagestyle="landscape", continue=true})
Notifications:TopToAll({hero="npc_dota_hero_axe", imagestyle="portrait", continue=true})

-- Display a generic image and then 2 ability icons and an item on the same line for 5 seconds
Notifications:TopToAll({image="file://{images}/status_icons/dota_generic.psd", duration=5.0})
Notifications:TopToAll({ability="nyx_assassin_mana_burn", continue=true})
Notifications:TopToAll({ability="lina_fiery_soul", continue=true})
Notifications:TopToAll({item="item_force_staff", continue=true})


-- Send a notification to all players on radiant (GOODGUYS) that displays near the bottom of the screen for 10 seconds to be displayed with the NotificationMessage class added
Notifications:BottomToTeam(DOTA_TEAM_GOODGUYS, {text="AAAAAAAAAAAAAA", duration=10, class="NotificationMessage"})
-- Send a notification to player 0 which will display near the bottom a large red notification with a solid blue border for 5 seconds
Notifications:Bottom(PlayerResource:GetPlayer(0), {text="Super Size Red", duration=5, style={color="red", ["font-size"]="110px", border="10px solid blue"}})


-- Remove 1 bottom and 2 top notifications 2 seconds later
Timers:CreateTimer(2,function()
  Notifications:RemoveTop(0, 2)
  Notifications:RemoveBottomFromTeam(DOTA_TEAM_GOODGUYS, 1)

  -- Add 1 more notification to the bottom
  Notifications:BottomToAll({text="GREEEENNNN again", duration=9, style={color="green"}})
end)

-- Clear all notifications from the bottom
Timers:CreateTimer(7, function()
  Notifications:ClearBottomFromAll()
end)