/* global FindDotaHudElement, GameEvents, $, DOTA_GameState, Game */
'use strict';
var GlyphScanContainer = /** @class */ (function () {
  // constructor
  function GlyphScanContainer () {
    var _this = this;
    this.root = FindDotaHudElement('GlyphScanContainer');
    $.GetContextPanel().RemoveAndDeleteChildren();
    var panel = $.CreatePanel('Panel', $.GetContextPanel(), '');
    panel.BLoadLayoutSnippet('CustomGlyphRadarContainerSnippet');
    this.RadarCooldown = $('#OAARadarCooldown');
    this.GlyphCooldown = $('#OAAGlyphCooldown');
    this.RadarIcon = this.root.FindChildTraverse('RadarIcon');
    this.GlyphIcon = this.root.FindChildTraverse('GlyphButton');
    this.GlyphCooldown.style.clip = 'radial(50% 50%, 0deg, 0deg)';
    this.RadarCooldown.style.clip = 'radial(50% 50%, 0deg, 0deg)';
    this.CreateTooltips();
    this.StartGlyphCooldown(0.1);
    this.StartRadarCooldown(0.1);
    $.Schedule(0.2, function () {
      _this.SetRadarIcon(false);
      _this.SetGlyphIcon(true);
    });
    // First Cooldown
    this.GlyphTooltip.FindChildTraverse('cooldown_duration').text = this.NumberToTime(120);
  }
  GlyphScanContainer.prototype.Initialize = function () {
    var _this = this;
    this.DisableDotaGlyphAndRadar();
    this.UpdateCooldowns();
    this.StartRadarCooldown(210);
    GameEvents.Subscribe('glyph_scan_cooldown', function (args) {
      _this.StartRadarCooldown(args.maxCooldown);
    });
    GameEvents.Subscribe('glyph_ward_cooldown', function (args) {
      _this.StartGlyphCooldown(args.maxCooldown);
    });
  };
  GlyphScanContainer.prototype.CreateTooltips = function () {
    this.CreateGlyphTooltip();
    this.CreateRadarTooltip();
  };
  GlyphScanContainer.prototype.UpdateCooldowns = function () {
    var _this = this;
    $.Schedule(1, function () {
      if (_this.GlyphCDRemain > 0) {
        _this.GlyphCDRemain--;
      }
      if (_this.RadarCDRemain > 0) {
        _this.RadarCDRemain--;
      }
      _this.GlyphTooltip.SetHasClass('IsCooldownReady', _this.GlyphCDRemain <= 0);
      _this.RadarTooltip.SetHasClass('IsCooldownReady', _this.RadarCDRemain <= 0);
      _this.GlyphTooltip.FindChildTraverse('cooldown_timer_label').SetDialogVariable('cooldown_time', _this.NumberToTime(_this.GlyphCDRemain));
      _this.RadarTooltip.FindChildTraverse('cooldown_timer_label').SetDialogVariable('cooldown_time', _this.NumberToTime(_this.RadarCDRemain));
      _this.UpdateCooldowns();
    });
  };
  GlyphScanContainer.prototype.NumberToTime = function (seconds) {
    var date = new Date(0);
    date.setSeconds(seconds);
    return date.toUTCString().substr(21, 4);
  };
  GlyphScanContainer.prototype.CreateGlyphTooltip = function () {
    var _this = this;
    this.GlyphTooltip = $.CreatePanel('Panel', $.GetContextPanel(), '');
    this.GlyphTooltip.BLoadLayoutSnippet('DotaCustomTooltipGlyph');
    this.root.FindChildTraverse('glyph').SetPanelEvent('onmouseover' /* ON_MOUSE_OVER */, function () {
      _this.GlyphTooltip.SetHasClass('Hidden', false);
      FindDotaHudElement('DOTAHUDGlyphTooltip').visible = false;
    });
    this.root.FindChildTraverse('glyph').SetPanelEvent('onmouseout' /* ON_MOUSE_OUT */, function () {
      _this.GlyphTooltip.SetHasClass('Hidden', true);
      var el = FindDotaHudElement('DOTAHUDRadarTooltip');
      if (el) {
        el.visible = false;
      }
    });
  };
  GlyphScanContainer.prototype.CreateRadarTooltip = function () {
    var _this = this;
    this.RadarTooltip = $.CreatePanel('Panel', $.GetContextPanel(), '');
    this.RadarTooltip.BLoadLayoutSnippet('DotaCustomTooltipScan');
    this.root.FindChildTraverse('RadarButton').SetPanelEvent('onmouseover' /* ON_MOUSE_OVER */, function () { _this.RadarTooltip.SetHasClass('Hidden', false); });
    this.root.FindChildTraverse('RadarButton').SetPanelEvent('onmouseout' /* ON_MOUSE_OUT */, function () { _this.RadarTooltip.SetHasClass('Hidden', true); });
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
    panel.style.opacity = '1';
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
    this.GlyphCDRemain = duration;
    this.GlyphTooltip.FindChildTraverse('cooldown_duration').text = this.NumberToTime(duration);
    this.StartPanelCooldown(this.GlyphCooldown, duration, function (IsActive) {
      _this.SetGlyphIcon(IsActive);
    });
  };
  GlyphScanContainer.prototype.StartRadarCooldown = function (duration) {
    var _this = this;
    this.RadarCDRemain = duration;
    this.RadarTooltip.FindChildTraverse('cooldown_duration').text = this.NumberToTime(duration);
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
