#!/bin/bash
set -e
shopt -s extglob

source ../bitrated-server/.env
PATH=./node_modules/.bin:$PATH

TARGET=${1?"unspecified target directory"}

mkdir $TARGET

# Combine libs
echo "Combining common libs..."
(cd static/lib && cat jquery.min.js onready.js bootstrap/js/bootstrap.min.js toastr/toastr.min.js piwik.js) \
  | uglifyjs --mangle --compress warnings=false \
  > $TARGET/libs.js
(cd static/lib && cat open-sans.css bootstrap/css/bootstrap.min.css toastr/toastr.min.css ladda.min.css) | cleancss | \
  # fix bootstrap font path
  sed "s#\.\./fonts/#fonts/#g" > $TARGET/libs.css

# Copy static files
echo "Copying static files..."
cp -rL static/{img,share,fonts,glyphs,favicon.ico} $TARGET

mkdir $TARGET/lib
cp -rL static/lib/{sui,typeaheadjs.css,intro.js,webshim} $TARGET/lib

# Build Primus
echo "Building Primus..."
coffee ../bitrated-server/websocket/client-library.coffee \
  | uglifyjs --mangle --compress warnings=false \
  > $TARGET/lprimus.min.js

# Compile browserify bundles
echo "Compiling browserify bundles..."
find bundles -follow -type f -name '*.coffee' | while read bundle
do
  jspath=$TARGET/${bundle#bundles/}
  jspath=${jspath%.coffee}.js
  echo "  - $bundle -> $jspath"
  mkdir -p $(dirname $jspath)
  sem --id bundle -j 3 browserify --extension .coffee --entry $bundle \
    "|" uglifyjs --mangle --compress warnings=false \
    ">" $jspath
done
sem --wait --id bundle

# Compile stylus
echo "Compiling stylus..."
find styl -type f -name '*.styl' | while read path
do
  cssdir=$(dirname $path)
  cssdir=$TARGET/${cssdir#styl}
  echo "  - $path -> $cssdir"
  mkdir -p $cssdir
  stylus --compress $path --out $cssdir
done

# Create a single CSS file for site-wide CSS
cat $TARGET/libs.css $TARGET/common.css > $TARGET/sw.css

# Append custom intro.js styles to main CSS file
# cat $TARGET/tour.css >> $TARGET/lib/intro.js/introjs.css
