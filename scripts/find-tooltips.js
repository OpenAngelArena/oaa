const request = require('request');
const parseKV = require('parse-kv');
const after = require('after');
const getTranslations = require('./parse-translation');
const luaEntitiesUtil = require('./lua-entities-util');

module.exports = {
  findMissingTooltips: findMissingTooltips
};

if (require.main === module) {
  findMissingTooltips(function (err, result) {
    console.log();
    if (err) {
      console.error(err);
      return;
    }
    if (result.length === 0) {
      console.log('Everything looks good!');
    }
  });
}

function findMissingTooltips (cb) {
  request.get({
    // url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/resource/dota_english.txt'
    url: 'https://raw.githubusercontent.com/SteamDatabase/GameTracking-Dota2/master/game/dota/pak01_dir/resource/localization/abilities_english.txt'
  }, function (err, dotaEnglish) {
    var done = after(3, function (err) {
      cb(err, result);
    });

    if (err) {
      console.log(err);
      return done(err);
    }
    dotaEnglish = parseKV(dotaEnglish.body);

    var translations = getTranslations(true, false, dotaEnglish);
    translations = Object.keys(translations.lang.Tokens.values).map(function (name) {
      return name.toLowerCase();
    });
    var result = [];

    luaEntitiesUtil.findAllUnits(function (err, data) {
      if (err) {
        console.log(err);
        return done(err);
      }
      data.map(function (name) {
        if (translations.indexOf(name) === -1) {
          if (name.length < 45) {
            console.log(name, 'is missing a title', Array(45 - name.length).join(' '), '- Add the key: "' + name + '"');
          } else {
            console.log(name, 'is missing a title - Add the key: "' + name + '"');
          }
          result.push([name, name]);
        }
      });
      done();
    });

    luaEntitiesUtil.findAllAbilities(function (err, data) {
      if (err) {
        console.log(err);
        return done(err);
      }
      data.map(function (name) {
        var prefix = 'DOTA_Tooltip_Ability_';
        var title = prefix + name;
        var description = (prefix + name + '_description').toLowerCase();

        title = title.toLowerCase();

        if (translations.indexOf(title) === -1) {
          if (name.length < 45) {
            console.log(name, 'is missing a title', Array(45 - name.length).join(' '), '- Add the key: "' + title + '"');
          } else {
            console.log(name, 'is missing a title - Add the key: "' + title + '"');
          }
          result.push([name, title]);
        } else {
          // console.log(translations.lang.Tokens.values[title]);
        }
        if (translations.indexOf(description) === -1 && !name.startsWith('special_bonus_')) {
          if (name.length < 46) {
            console.warn(name, 'is missing a desc', Array(46 - name.length).join(' '), '- Add the key: "' + description + '"');
          } else {
            console.warn(name, 'is missing a desc - Add the key: "' + description + '"');
          }
          result.push([name, description]);
        }
      });
      done();
    });

    luaEntitiesUtil.findAllItems(function (err, data) {
      if (err) {
        console.log(err);
        return done(err);
      }
      data.map(function (name) {
        var prefix = 'DOTA_Tooltip_';
        var requiredTitle = !name.startsWith('item_recipe');

        if (name.startsWith('item_')) {
          prefix = prefix + 'Ability_';
        }
        var title = prefix + name;
        // var requiredDescription = (name.startsWith('item_') && !name.startsWith('item_recipe'));
        // var description = (prefix + name + '_description').toLowerCase();

        title = title.toLowerCase();

        if (translations.indexOf(title) === -1 && requiredTitle) {
          if (name.length < 45) {
            console.log(name, 'is missing a title', Array(45 - name.length).join(' '), '- Add the key: "' + title + '"');
          } else {
            console.log(name, 'is missing a title - Add the key: "' + title + '"');
          }
          result.push([name, title]);
        } else {
          // console.log(translations.lang.Tokens.values[title]);
        }
        // if (translations.indexOf(description) === -1 && requiredDescription) {
        //   if (name.length < 39) {
        //     console.log(name, 'is missing a description', Array(39 - name.length).join(' '), '- Add the key: "' + description + '"');
        //   } else {
        //     console.log(name, 'is missing a description - Add the key: "' + description + '"');
        //   }
        //   result.push([name, description]);
        // }
      });
      done();
    });
  });
}
