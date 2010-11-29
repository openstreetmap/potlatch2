package net.systemeD.potlatch2 {

    public class AutoVectorBackground {

        import flash.events.*
        import flash.net.*
        import net.systemeD.halcyon.Map;
        import net.systemeD.halcyon.DebugURLRequest;
        import net.systemeD.potlatch2.utils.*;

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
              var name:String = (set.name == undefined) ? null : String(set.name);
              var loader:String = set.loader;
              switch (loader) {
                case "TrackLoader":
                  break;
                case "KMLImporter":
                  break;

                case "BugLoader":
                  if (set.url && set.apiKey) {
                    name ||= 'Bugs';
                    var bugLoader:BugLoader = new BugLoader(map, String(set.url), String(set.apikey), name);
                    if (set.@loaded == "true") {
                      bugLoader.load();
                    }
                  } else {
                    trace("AutoVectorBackground: error with BugLoader");
                  }
                  break;

                case "BikeShopLoader":
                  if (set.url) {
                    name ||= 'Missing Bike Shops'
                    var bikeShopLoader:BikeShopLoader = new BikeShopLoader(map, String(set.url), name);
                    if (set.@loaded == "true") {
                      bikeShopLoader.load();
                    }
                  } else {
                    trace("AutoVectorBackground: no url for BikeShopLoader");
                  }
                  break;

                default:
                  trace("AutoVectorBackground: unknown loader");
              }
            }
        }
    }
}