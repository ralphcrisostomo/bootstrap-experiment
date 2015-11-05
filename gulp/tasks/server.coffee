gulp        = require('gulp')
compass     = require('gulp-compass')
jade        = require('gulp-jade')
uglify      = require('gulp-uglify')
coffeelint  = require('gulp-coffeelint')
minifyCSS   = require('gulp-minify-css')
source      = require('vinyl-source-stream')
buffer      = require('vinyl-buffer')
sourcemaps  = require('gulp-sourcemaps')
browserify  = require('browserify')
browserSync = require('browser-sync')
runSequence = require('run-sequence')

dir =
  app   : './app'
  dist  : './dist'

gulp.task "html", ->
  gulp.src "#{dir.app}/index.jade"
  .pipe jade { pretty : true }
  .pipe gulp.dest "#{dir.dist}"

gulp.task "compass", ->
  gulp.src "#{dir.app}/style.scss"
  .pipe compass
    sass      : "#{dir.app}"
    css       : "#{dir.dist}/assets"
    image     : "#{dir.dist}/assets"
    sourcemap : true
  .pipe minifyCSS()
  .pipe gulp.dest "#{dir.dist}/assets"

gulp.task "clean", ->
  gulp.src "#{dir.dist}", {read : false}
  .pipe clean()

gulp.task "browserify", ->
  browserify "#{dir.app}/script.coffee"
  .bundle()
  .pipe source "script.js"
  .pipe buffer()
  .pipe sourcemaps.init({loadMaps : true})
  .pipe uglify()
  .pipe sourcemaps.write('./')
  .pipe gulp.dest "#{dir.dist}/assets"

gulp.task "browser-sync", ->
  browserSync
    port: 3000
    server :  { baseDir : [ "#{dir.dist}", "#{dir.app}" ], index : "index.html" }
    files :   [ "#{dir.dist}/**", "!#{dir.dist}/**.map"]

gulp.task "coffeelint", ->
  @item = @seq[0].split(":").slice(-2)[0]
  gulp.src [
    "#{dir.app}/**/*.coffee"
    '!./node_modules/**'
  ]
  .pipe coffeelint
    max_line_length :
      level : 'ignore'
  .pipe coffeelint.reporter('default')

gulp.task "build", (callback) ->
  runSequence(
    "browserify"
    "compass"
    "html"
    callback
  )
gulp.task "server", ["coffeelint"], ->
  runSequence "build", "browser-sync", =>
    gulp.watch  "#{dir.app}/**/*.scss",     [ "compass", browserSync.reload]
    gulp.watch  "#{dir.app}/**/*.jade",     [ "html", browserSync.reload]
    gulp.watch  "#{dir.app}/**/*.coffee",   [ "browserify", browserSync.reload]