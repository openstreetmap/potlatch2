== Halcyon - ActionScript 3 renderer for Potlatch 2.0 ==

Here's some embryonic unfinished stuff to play with.

This is a live OSM renderer written in AS3 which will one day grow into a beautiful map editor. It's rules-based (like, say, Mapnik) and does dotted lines, text on a path, casing, icons for POIs, all of that.

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
  - compile for the first time
* compile 1 
  - compile each subsequent time (_much_ faster than using mxmlc every time)

Running:
* Make sure test.yaml and icons/ are in the same directory as halcyon.swf
* Open halcyon.swf in your browser

=== Some other stuff you might need to know ===

* The as3yaml library has been patched a bit to actually make it work.
* The stuff about -managers=flash.fonts.AFEFontManager is probably only required on OS X.
* Flex compiler runs at about the speed of a tortoise soaked in molasses which happens also to be dead.


Richard Fairhurst
richard@systemeD.net
