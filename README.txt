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

Compiling Potlatch 2:

The following command will compile potlatch2 in optimized configuration
The result is put at resources/potlatch2.swf

* mxmlc potlatch2.mxml


Compiling Halcyon as standalone viewer:

* mxmlc halcyon_viewer.as


Compiling during development:

Compiling optimized versions from scratch takes a _long_ time. There are
several ways to make it faster during development and also add useful
debug stack traces and enable the commandline debugger (at the expense
of a much larger swf file.. but we're developing so that doesn't matter!).

* fcsh
  - launches the Flex Compiler SHell -- stops the compiler having to
    bootstrap itself each time you invoke it. You don't /need/ this, but it
    does make things slightly faster (about a second a shot for me)

* mxmlc -load-config+=debug-config.xml potlatch2.mxml
  - compile potlatch2 in debug configuration -- build is incremental so you
    can run it again and mxmlc will only compile changes. Output has debug
    enabled along with decent stack traces.
    (you can substitute halcyon_viewer.as in the above to compile that)

* compile 1 
  - when using fcsh recompile the first command


Running:

* Move everything from the resources/ directory into the same directory as the SWF
* Open halcyon.html or potlatch2.html in your browser

=== Some other stuff you might need to know ===

* The as3yaml library has been patched a bit to actually make it work. It will nonetheless spit out 300 warnings on Flex SDK 3.3.
* Flex compiler runs at about the speed of a tortoise soaked in molasses which happens also to be dead.


Richard Fairhurst
richard@systemeD.net

Dave Stubbs
osm@randomjunk.co.uk

