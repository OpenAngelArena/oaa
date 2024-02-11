/* global $, CustomNetTables, Game */
'use strict';

const context = $.GetContextPanel();
context.FindChildTraverse('InfoVersion').text = 'Version: ' + CustomNetTables.GetTableValue('info', 'version').value + ' ';
context.FindChildTraverse('InfoMap').text = 'Map: ' + Game.GetMapInfo().map_display_name + ' ';
context.FindChildTraverse('InfoDateTime').text = 'Gametime: ' + CustomNetTables.GetTableValue('info', 'datetime').value + ' ';
context.FindChildTraverse('InfoMode').text = CustomNetTables.GetTableValue('info', 'mode').value + ' ';
