/* global $, Game, DOTA_GameState, GameUI, Players, Entities, Particles, ParticleAttachment_t, */

let tempParticles = [];
let created = false;

function CheckForAltPress () {
  if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_TEAM_SHOWCASE)) {
    if (GameUI.IsAltDown()) {
      if (!created) {
        const buildings = Entities.GetAllBuildingEntities();
        const hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());

        for (let i = 0; i < buildings.length; i++) {
          const name = Entities.GetUnitName(buildings[i]);
          if (name.indexOf('shrine') !== -1) {
            const shrine = buildings[i];
            const particle = Particles.CreateParticle('particles/ui_mouseactions/range_display.vpcf', ParticleAttachment_t.PATTACH_WORLDORIGIN, hero);
            Particles.SetParticleControl(particle, 0, Entities.GetAbsOrigin(shrine));
            Particles.SetParticleControl(particle, 1, [800, 800, 800]);
            // Store particle instance
            tempParticles.push(particle);
          }
        }
        created = true;
      }
      // $.Schedule(1/30, CheckForAltPress);
    } else {
      for (let i = 0; i < tempParticles.length; i++) {
        const p = tempParticles[i];
        if (p) {
          // End the particle effect
          Particles.DestroyParticleEffect(p, true);
          Particles.ReleaseParticleIndex(p);
        }
        tempParticles[i] = undefined;
      }
      tempParticles = [];
      created = false;
    }
  }
}

(function () {
  $.RegisterForUnhandledEvent('DOTAHudUpdate', CheckForAltPress);
})();
