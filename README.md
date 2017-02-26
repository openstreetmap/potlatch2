# Potlatch 2.0 - OpenStreetMap editor in ActionScript 3

Potlatch 2.0 is the fourth OpenStreetMap online editor (after two Java applets and Potlatch 1, and before iD). It's written in ActionScript 3 and requires a Flash Player.

## What you'll need

* Apache Flex SDK - download the installer at https://flex.apache.org/installer.html
* AS3 docs - http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/
* Flash debug player - http://www.adobe.com/support/flashplayer/debug_downloads.html

The Flash debug player is essential to see errors as and when they occur.

You'll only need OSM Rails port installed on your local machine if you are doing hard-core server-communication coding. Generally you can use the dev server at api06.dev.openstreetmap.org for development and testing.

## Compiling during development

* `fcsh`
  - launches the Flex Compiler SHell -- stops the compiler having to
    bootstrap itself each time you invoke it. You don't need this, but it
    does make things slightly faster (about a second a shot for me)
* `mxmlc -load-config+=debug-config.xml potlatch2.mxml`
  - compile potlatch2 in debug configuration -- build is incremental so you
    can run it again and mxmlc will only compile changes. Output has debug
    enabled along with decent stack traces.
    (you can substitute halcyon_viewer.as in the above to compile that)
* `compile 1`
  - when using fcsh recompile the first command. (Incremental recompiling does not work on Java 8, but 6 or 7 are fine.)

If you have rlwrap on your system, use `rlwrap fcsh` so that command-line history will work within fcsh.

Flash's security model will not allow you to make calls from localhost to the internet. Either use 127.0.0.1 instead; or run `resources/server.py` to launch a local server, then go to http://localhost:3333/potlatch2.html to get started (or if you're already running e.g. Apache locally, feel free to use that instead.) Alternatively, you can update your global Flash security settings to "always trust files" in your local dev area.

If you are testing against a local copy of openstreetmap-website, you will need to add an OAuth application by going to `http://rails-port.local/user/<username>/oauth_clients/new`. Enter `Potlatch 2 (local)` as the name and `http://localhost:3333/resources/potlatch2.html` as the application URL, and then update resources/potlatch2.html replacing the domains.

## Compiling using ant

1. Copy the properties template file: `cp build.properties.template build.properties`
2. Edit the FLEX_HOME variable in build.properties: e.g. `FLEX_HOME=c:/flex_sdk/4.5.0.20967`
3. `ant` to compile in debug configuration, putting the result at resources/potlatch2.swf

You can also `ant release` to compile in release configuration; `ant halcyon` to compile the Halcyon rendering engine as a standalone viewer; `ant docs` to create class documentation (in resources/docs) using asdoc; `ant test` to run the (few) unit tests using flexunit.

`ant debug-no-locales` and `ant release-no-locales` are quicker as they skip the translation steps. You may need to tell ant to use more memory, by typing export ANT_OPTS="-Xms768m -Xmx1024m -XX:MaxPermSize=768m -XX:ReservedCodeCacheSize=512m" beforehand (you can put this in your .profile).

## Compiling with Flex Builder

If you happen to have Adobe Flex Builder 3/Flash Builder 4, you can create a project and import files into it. See http://wiki.openstreetmap.org/wiki/Potlatch_2/Developer_Documentation for details.

## Thank you

Many icons used in halcyon/potlatch2 are based on the awesome CC0-licensed SJJB icons project. http://www.sjjb.co.uk/mapicons/

Thanks to Dave Stubbs, Andy Allan, Steve Bennett and everyone else who contributed to Potlatch 2 during its heyday. 

Richard Fairhurst / @richardf