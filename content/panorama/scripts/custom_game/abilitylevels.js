'use strict'

(function () {
  GameEvents.Subscribe("ability_level_error", DisplayAbilityLevelError)
}())

function DisplayAbilityLevelError (data) {
  // Localise hero level requirement error message and insert hero level number
  var errorMessageText = $.Localize("#dota_hud_error_ability_cant_upgrade_hero_level").replace("%s1", data.requiredLevel)

  var errorData = {reason: 80, message: errorMessageText}
  GameEvents.SendEventClientSide("dota_hud_error_message", errorData)
}
