/* global FindDotaHudElement, GameEvents, $, DOTA_GameState, Game */
'use strict';
var GlyphScanContainer = /** @class */ (function () {
  // constructor
  function GlyphScanContainer () {
    var _this = this;
    this.root = FindDotaHudElement('GlyphScanContainer');
    $.GetContextPanel().RemoveAndDeleteChildren();
    var panel = $.CreatePanel('Panel', $.GetContextPanel(), '');
    panel.RemoveAndDeleteChildren();
    panel.BLoadLayoutSnippet('CustomGlyphRadarContainerSnippet');
    this.RadarCooldown = $('#OAARadarCooldown');
    this.GlyphCooldown = $('#OAAGlyphCooldown');
    this.RadarIcon = this.root.FindChildTraverse('RadarIcon');
    this.GlyphIcon = this.root.FindChildTraverse('GlyphButton');
    this.GlyphCooldown.style.clip = 'radial(50% 50%, 0deg, 0deg)';
    this.RadarCooldown.style.clip = 'radial(50% 50%, 0deg, 0deg)';
    this.StartGlyphCooldown(0.1);
    this.StartRadarCooldown(0.1);
    $.Schedule(0.2, function () {
      _this.SetRadarIcon(false);
      _this.SetGlyphIcon(true);
    });
  }
  GlyphScanContainer.prototype.Initialize = function () {
    var _this = this;
    this.DisableDotaGlyphAndRadar();
    this.StartRadarCooldown(210);
    GameEvents.Subscribe('glyph_scan_cooldown', function (args) {
      _this.StartRadarCooldown(args.maxCooldown);
    });
    GameEvents.Subscribe('glyph_ward_cooldown', function (args) {
      _this.StartGlyphCooldown(args.maxCooldown);
    });
  };
  GlyphScanContainer.prototype.SetGlyphIcon = function (isActive) {
    if (isActive) {
      this.GlyphIcon.style.backgroundImage = 'url("file://{resources}/images/hud/reborn/poop_ward.png")';
    } else {
      this.GlyphIcon.style.backgroundImage = 'url("file://{resources}/images/hud/reborn/poop_ward_inactive.png")';
    }
  };
  GlyphScanContainer.prototype.SetRadarIcon = function (isActive) {
    if (isActive) {
      this.RadarIcon.style.backgroundImage = 'url("s2r://panorama/images/hud/reborn/icon_scan_on_psd.vtex")';
    } else {
      this.RadarIcon.style.backgroundImage = 'url("s2r://panorama/images/hud/reborn/icon_scan_off_psd.vtex")';
    }
  };
  GlyphScanContainer.prototype.DisableDotaGlyphAndRadar = function () {
    // disable default Dota cover because it starts the game with style changed by script that we can't override
    var vanilaRadarCD = this.root.FindChildTraverse('CooldownCover');
    vanilaRadarCD.visible = false;
    vanilaRadarCD.style.opacity = '0';
    var vanilaGlyphCD = this.root.FindChildTraverse('GlyphCooldown');
    vanilaGlyphCD.visible = false;
    vanilaGlyphCD.style.opacity = '0';
  };
  GlyphScanContainer.prototype.StartPanelCooldown = function (panel, duration, SetIcon) {
    $.Msg('StartingCooldown for ' + panel.id);
    SetIcon(false);
    panel.style.visibility = 'visible';
    panel.style.opacity = '0.75';
    panel.style.transitionDuration = duration + 's ';
    panel.style.clip = 'radial(50% 50%, 0deg, 0deg)';
    // Schedule hiding of the panel
    $.Schedule(duration, function () {
      $.Msg('FinishCooldown for ' + panel.id);
      panel.style.opacity = '0';
      panel.style.transitionDuration = 0.1 + 's ';
      panel.style.clip = 'radial(50% 50%, 0deg, -359deg)';
      SetIcon(true);
    });
  };
  GlyphScanContainer.prototype.StartGlyphCooldown = function (duration) {
    var _this = this;
    this.StartPanelCooldown(this.GlyphCooldown, duration, function (IsActive) {
      _this.SetGlyphIcon(IsActive);
    });
  };
  GlyphScanContainer.prototype.StartRadarCooldown = function (duration) {
    var _this = this;
    this.StartPanelCooldown(this.RadarCooldown, duration, function (IsActive) {
      _this.SetRadarIcon(IsActive);
    });
  };
  return GlyphScanContainer;
}());
var controller = new GlyphScanContainer();
if (!Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS)) {
  controller.Initialize();
} else {
  var eventHandler = GameEvents.Subscribe('oaa_state_change', function (args) {
    if (args.newState >= DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS) {
      controller.Initialize();
      $.Msg(args.newState);
      GameEvents.Unsubscribe(eventHandler);
    }
  });
}
