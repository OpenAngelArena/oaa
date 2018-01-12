"use strict";
var GlyphScanContainer = /** @class */ (function () {
    // constructor
    function GlyphScanContainer() {
        this.root = FindDotaHudElement('GlyphScanContainer');
        this.GlyphIcon = this.root.FindChildTraverse('GlyphButton');
        this.RadarIcon = this.root.FindChildTraverse('RadarIcon');
    }
    GlyphScanContainer.prototype.Initialize = function () {
        this.InitializeCooldownOverlays();
        controller.StartGlyphCooldown(0);
        controller.StartRadarCooldown(0);
    };
    GlyphScanContainer.prototype.SetGlyphIcon = function (isActive) {
        if (isActive) {
            this.GlyphIcon.style.backgroundImage = 'url("file://{resources}/images/hud/reborn/poop_ward.png")';
        }
        else {
            this.GlyphIcon.style.backgroundImage = 'url("file://{resources}/images/hud/reborn/poop_ward_inactive.png")';
        }
    };
    GlyphScanContainer.prototype.SetRadarIcon = function (isActive) {
        if (isActive) {
            this.RadarIcon.style.backgroundImage = 'url("s2r://panorama/images/hud/reborn/icon_scan_on_psd.vtex")';
        }
        else {
            this.RadarIcon.style.backgroundImage = 'url("s2r://panorama/images/hud/reborn/icon_scan_off_psd.vtex")';
        }
    };
    GlyphScanContainer.prototype.InitializeCooldownOverlays = function () {
        // disable default Dota cover because it starts the game with style changed by script that we can't override
        var vanilaRadarCD = this.root.FindChildTraverse('CooldownCover');
        vanilaRadarCD.visible = false;
        vanilaRadarCD.style.opacity = "0";
        var radarCD = this.root.FindChildTraverse('OAARadarCooldown');
        if (radarCD == null) {
            radarCD = $('#OAARadarCooldown');
            radarCD.SetParent(vanilaRadarCD.GetParent());
        }
        this.RadarCooldown = radarCD;
        var vanilaGlyphCD = this.root.FindChildTraverse('GlyphCooldown');
        vanilaGlyphCD.visible = false;
        vanilaGlyphCD.style.opacity = "0";
        var glyphCD = this.root.FindChildTraverse('OAAGlyphCooldown');
        if (glyphCD == null) {
            glyphCD = $('#OAAGlyphCooldown');
            glyphCD.SetParent(vanilaGlyphCD.GetParent());
        }
        this.GlyphCooldown = glyphCD;
        radarCD = $.GetContextPanel().FindChildTraverse('OAARadarCooldown');
        if (radarCD != null)
            radarCD.DeleteAsync(1);
        glyphCD = $.GetContextPanel().FindChildTraverse('OAAGlyphCooldown');
        if (glyphCD != null)
            glyphCD.DeleteAsync(1);
    };
    GlyphScanContainer.prototype.StartPanelCooldown = function (panel, duration) {
        panel.style.visibility = 'visible';
        $.Msg('StartingCooldown for ' + panel.id);
        panel.style.opacity = "1";
        panel.style.transitionDuration = duration + "s ";
        panel.style.clip = "radial(50% 50%, 0deg, 0deg)";
        //Schedule hiding of the panel
        $.Schedule(duration, function () {
            $.Msg('FinishCooldown for ' + panel.id);
            panel.style.transitionDuration = 0 + "s ";
            panel.style.clip = "radial(50% 50%, 0deg, -360deg)";
            panel.style.visibility = 'collapse';
            panel.style.opacity = "0";
        });
    };
    GlyphScanContainer.prototype.StartGlyphCooldown = function (duration) {
        var scope = this;
        this.SetGlyphIcon(false);
        this.StartPanelCooldown(this.GlyphCooldown, duration);
        $.Schedule(duration, function () {
            scope.SetGlyphIcon(true);
        });
    };
    GlyphScanContainer.prototype.StartRadarCooldown = function (duration) {
        var scope = this;
        this.SetRadarIcon(false);
        this.StartPanelCooldown(this.RadarCooldown, duration);
        $.Schedule(duration, function () {
            scope.SetRadarIcon(true);
        });
    };
    return GlyphScanContainer;
}());
var controller = new GlyphScanContainer();
if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_GAME_IN_PROGRESS)) {
    GameEvents.Subscribe('oaa_state_change', function (args) {
        controller.Initialize();
        // Initial Dota Radar Cooldown
    });
    GameEvents.Subscribe('glyph_scan_cooldown', function (args) {
        $.Msg('Panorama Recieve SCAN');
        controller.StartRadarCooldown(args.maxCooldown);
    });
    GameEvents.Subscribe('glyph_ward_cooldown', function (args) {
        $.Msg('Panorama Recieve GLYPH');
        controller.StartGlyphCooldown(args.maxCooldown);
    });
}
else {
    controller.Initialize();
    GameEvents.Subscribe('glyph_scan_cooldown', function (args) {
        $.Msg('Panorama Recieve SCAN');
        controller.StartRadarCooldown(args.maxCooldown);
    });
    GameEvents.Subscribe('glyph_ward_cooldown', function (args) {
        $.Msg('Panorama Recieve GLYPH');
        controller.StartGlyphCooldown(args.maxCooldown);
    });
    //controller.StartGlyphCooldown(30);
    //controller.StartRadarCooldown(30);
}
