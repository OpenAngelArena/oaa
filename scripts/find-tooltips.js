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
    // url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/resource/localization/dota_english.txt'
    url: 'https://raw.githubusercontent.com/spirit-bear-productions/dota_vpk_updates/main/resource/localization/abilities_english.txt'
  }, function (err, dotaEnglish) {
    const done = after(3, function (err) {
      cb(err, result);
    });

    if (err) {
      console.log(err);
      return done(err);
    }
    dotaEnglish = parseKV(dotaEnglish.body.replace(/" and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%\./g, ' and turn rate reduced by %dMODIFIER_PROPERTY_TURN_RATE_PERCENTAGE%%%."'));

    let translations = getTranslations(true, false, dotaEnglish);
    translations = Object.keys(translations.lang.Tokens.values).map(function (name) {
      return name.toLowerCase();
    });
    let result = []; // eslint-disable-line

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
        return name;
      });
      done();
    });

    luaEntitiesUtil.findAllAbilities(function (err, data) {
      if (err) {
        console.log(err);
        return done(err);
      }
      data.map(function (name) {
        const prefix = 'DOTA_Tooltip_Ability_';
        let title = prefix + name;
        const description = (prefix + name + '_description').toLowerCase();

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
        return name;
      });
      done();
    });

    luaEntitiesUtil.findAllItems(function (err, data) {
      if (err) {
        console.log(err);
        return done(err);
      }
      data.map(function (name) {
        let prefix = 'DOTA_Tooltip_';
        const requiredTitle = !name.startsWith('item_recipe');

        if (name.startsWith('item_')) {
          prefix = prefix + 'Ability_';
        }
        let title = prefix + name;
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
        }
        // if (translations.indexOf(description) === -1 && requiredDescription) {
        //   if (name.length < 39) {
        //     console.log(name, 'is missing a description', Array(39 - name.length).join(' '), '- Add the key: "' + description + '"');
        //   } else {
        //     console.log(name, 'is missing a description - Add the key: "' + description + '"');
        //   }
        //   result.push([name, description]);
        // }
        return name;
      });
      done();
    });
  });
}
