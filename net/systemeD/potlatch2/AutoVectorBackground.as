package net.systemeD.potlatch2 {

    public class AutoVectorBackground {

        import flash.events.*
        import flash.net.*
        import net.systemeD.halcyon.Map;
        import net.systemeD.halcyon.DebugURLRequest;
        import net.systemeD.potlatch2.utils.BugLoader;

        private var map:Map;

        public function AutoVectorBackground(map:Map) {
            this.map = map;
        }

        public function load():void {
            var request:DebugURLRequest = new DebugURLRequest("vectors.xml");
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onConfigLoad);
            loader.load(request.request);
        }

        public function onConfigLoad(e:Event):void {
            var xml:XML = XML(e.target.data);
            for each(var set:XML in xml.set) {
              var loader:String = set.loader;
              switch (loader) {
                case "TrackLoader":
                  break;
                case "KMLImporter":
                  break;
                case "BugLoader":
                  if (set.url && set.apiKey) {
                    var bugLoader:BugLoader = new BugLoader(map, String(set.url), String(set.apikey));
                    if (set.@loaded == "true") {
                      bugLoader.load();
                    }
                  } else {
                    trace("AutoVectorBackground: error with BugLoader");
                  }
                  break;
                default:
                  trace("AutoVectorBackground: unknown loader");
              }
            }
        }
    }
}