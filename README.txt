== Halcyon and Potlatch 2.0 - ActionScript 3 renderer and editor ==

Potlatch 2.0 is the new version of the OpenStreetMap online editor.

Halcyon is its rendering engine. It's rules-based (like, say, Mapnik) and does dotted lines, text on a path, casing, icons for POIs, all of that.

Both are written in ActionScript 3. Potlatch 2.0 additionally uses the Flex framework.

=== What you'll need ===

* OSM Rails port installed on your local machine
* Flex SDK - http://www.adobe.com/products/flex/ (free, OS X/Windows/Linux)
* AS3 docs - http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/
* Flash debug player - http://www.adobe.com/support/flashplayer/downloads.html
* Basically you might as well just sell your soul to Adobe

=== How to compile and run ===

Compiling:

* fcsh
  - launches the Flex Compiler SHell

* mxmlc -managers=flash.fonts.AFEFontManager -output=/path/to/halcyon.swf /path/to/halcyon.mxml 
* mxmlc -managers=flash.fonts.AFEFontManager -output=/path/to/halcyon_viewer.swf /path/to/halcyon_viewer.as
  - compile Potlatch or Halcyon for the first time

* compile 1 
  - compile each subsequent time (_much_ faster than using mxmlc every time)

* for nice debug reports compile with the mxmlc command:
  mxmlc -managers=flash.fonts.AFEFontManager -compiler.debug -compiler.verbose-stacktraces -output=halcyon.swf halcyon.mxml

Running:

* Move everything from the resources/ directory into the same directory as the SWF
* Open halcyon.html or potlatch2.html in your browser

=== Some other stuff you might need to know ===

* The as3yaml library has been patched a bit to actually make it work. It will nonetheless spit out 300 warnings on Flex SDK 3.3.
* The stuff about -managers=flash.fonts.AFEFontManager is probably only required on OS X.
* Flex compiler runs at about the speed of a tortoise soaked in molasses which happens also to be dead.


Richard Fairhurst
richard@systemeD.net
