var gulp = require('gulp');
var GulpDotaNpc = require('gulp-dota2-npc');
var path = require('path');

var types = [
  'abilities',
  'heroes',
  'units',
  'items'
];

types.forEach(function (type) {
  gulp.task(type, function () {
    return gulp.src(path.join('./game/scripts/npc/' + type + '/**/*.txt'))
      .pipe(GulpDotaNpc(type))
      .pipe(gulp.dest('./game/scripts/npc'));
  });
});
