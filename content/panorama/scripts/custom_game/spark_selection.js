
(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', SparkSelection);
  SparkSelection(null, 'team_sparks', CustomNetTables.GetTableValue('hero_selection', 'team_sparks'));
})();

function SparkSelection (table, key, args) {
  $.Msg(key);
  if (!args) {
    args = {};
  }
  args.gpm = args.gpm || 0;
  args.midas = args.midas || 0;
  args.power = args.power || 0;
  args.cleave = args.cleave || 0;
  $.Msg(args);

  Object.keys(args).forEach(function (value) {
    var elem = $('#' + value + 'Count');
    elem.text = args[value];
  })
}
