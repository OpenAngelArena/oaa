var gulp = require('gulp');

// modules
require('./npc-custom');

gulp.task('npc', ['abilities', 'heroes', 'items', 'units']);
gulp.task('default', ['npc']);
