// Goes red when Valve changes a vanilla value that OAA overrides with an `// OAA` comment.
// special-values.test.js skips those values, so before this test a vanilla change under
// an OAA comment was invisible (7.42: QoP Sonic Wave, Kez Raptor Dance, Pugna mana costs).
// Fix: re-apply vanilla's change on top of the OAA value (or decide to keep it), then
//   node scripts/reviewed-vanilla.js --accept <entry>
const test = require('tape');
const RV = require('../reviewed-vanilla');

test('vanilla changes under OAA comments', function (t) {
  const snapshot = RV.load();
  t.ok(Object.keys(snapshot).length > 0, 'reviewed vanilla snapshot exists');
  RV.oaaFiles(function (err, files) {
    t.notOk(err, 'read OAA KVs');
    RV.liveVanilla(function (err, vanilla) {
      t.notOk(err, 'read vanilla KVs');
      const current = RV.collect(files, vanilla);
      // new OAA comments are recorded at today's vanilla (like the ItemCost auto-fix), so they are tracked from now on
      const added = Object.keys(current).filter(key => !(key in snapshot));
      if (added.length) {
        added.forEach(key => { snapshot[key] = current[key]; });
        RV.save(snapshot);
        t.comment('recorded ' + added.length + ' new OAA-commented keys in ' + RV.SNAPSHOT + ' (commit it)');
      }
      Object.keys(current).forEach(function (key) {
        if (added.includes(key)) return;
        const was = snapshot[key].vanilla;
        const now = current[key].vanilla;
        if (was !== now) {
          t.fail(current[key].file + ' :: ' + key + ': vanilla changed under an OAA comment (' +
            was + ' -> ' + now + '). Re-apply the change on top of the OAA value or keep it, then run: node scripts/reviewed-vanilla.js --accept ' + key.split('|')[0]);
        }
      });
      t.end();
    });
  });
});

// An OAA comment on a block protects its numbers, not its tooltip/meta keys.
// 7.42: Kez Raptor Dance base_damage kept DAMAGE_TYPE_PURE after vanilla made it physical.
const META_KEYS = ['DamageTypeTooltip', 'CalculateSpellDamageTooltip', 'affected_by_aoe_increase', 'RequiresShard', 'RequiresScepter', 'RequiresFacet', 'levelkey'];
test('meta keys inside OAA-commented blocks follow vanilla', function (t) {
  RV.oaaFiles(function (err, files) {
    t.notOk(err, 'read OAA KVs');
    RV.liveVanilla(function (err, vanilla) {
      t.notOk(err, 'read vanilla KVs');
      Object.keys(files).forEach(function (file) {
        const root = files[file] && files[file].DOTAAbilities;
        if (!root) return;
        Object.keys(root).filter(k => k !== 'values' && k !== 'comments').forEach(function (name) {
          const entry = root[name];
          const parent = vanilla[name];
          const base = entry.values && entry.values.BaseClass;
          if (!parent || typeof parent !== 'object' || (base && base !== name)) return;
          const av = entry.AbilityValues;
          const vav = parent.AbilityValues;
          if (!av || !vav) return;
          Object.keys(av).filter(k => k !== 'values' && k !== 'comments').forEach(function (key) {
            const comment = (av.comments || {})[key] || '';
            const theirs = vav[key];
            if (!comment.includes('OAA') || !theirs || !theirs.values) return;
            META_KEYS.forEach(function (meta) {
              const want = theirs.values[meta];
              const have = av[key].values[meta];
              const own = (av[key].comments || {})[meta] || '';
              if (want !== undefined && have !== want && !own.includes('OAA')) {
                t.fail(name + ': ' + meta + ' in {' + key + '} should follow vanilla (' + want + ' vs ' + have + '); the OAA comment on the block only covers its values');
              }
            });
          });
        });
      });
      t.end();
    });
  });
});
