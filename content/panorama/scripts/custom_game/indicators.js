/* global $, Game, DOTA_GameState, GameUI, Players, Entities, Particles, ParticleAttachment_t, */

const tempParticles = {};
let created = false;

function CheckForAltPress () {
  if (Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_TEAM_SHOWCASE)) {
    if (GameUI.IsAltDown()) {
      if (!created) {
        const buildings = Entities.GetAllBuildingEntities();
        const hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());

        for (let i = 0; i < buildings.length; i++) {
          const shrine = buildings[i];
          const particle = Particles.CreateParticle('.vpcf', ParticleAttachment_t.PATTACH_CUSTOMORIGIN, hero);
          Particles.SetParticleControl(particle, 0, Entities.GetAbsOrigin(shrine));
          Particles.SetParticleControl(particle, 1, [0, 0, 0]);
          Particles.SetParticleControl(particle, 2, [0, 0, 0]);
          // Store particle instance
          tempParticles[i] = particle;
        }
        created = true;
      }
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
    }
  }
}

(function () {
  $.RegisterForUnhandledEvent('DOTAHudUpdate', CheckForAltPress);
})();
