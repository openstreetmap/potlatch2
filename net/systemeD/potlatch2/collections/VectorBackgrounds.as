package net.systemeD.potlatch2.collections {

    import flash.events.*
    import flash.net.*
    import flash.system.Security;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.DebugURLRequest;
    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.potlatch2.utils.*;
        
    public class VectorBackgrounds extends EventDispatcher {

        private static const GLOBAL_INSTANCE:VectorBackgrounds = new VectorBackgrounds();
        public static function instance():VectorBackgrounds { return GLOBAL_INSTANCE; }

        private var _map:Map;


        public function init(map:Map):void {
            _map = map;
            var request:DebugURLRequest = new DebugURLRequest("vectors.xml");
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onConfigLoad);
            loader.load(request.request);
        }

        public function onConfigLoad(e:Event):void {
            var xml:XML = XML(e.target.data);
            for each(var set:XML in xml.set) {

              // allow layers to be defined but disabled. This lets me put examples in the
              // config file.
              if (set.@disabled == "true") continue;

              if (!(set.policyfile == undefined)) {
                Security.loadPolicyFile(String(set.policyfile));
              }

              var name:String = (set.name == undefined) ? null : String(set.name);
              var loader:String = set.loader;
              switch (loader) {
                case "TrackLoader":
                  break;
                case "KMLImporter":
                  break;
                case "GPXImporter":
                  if (set.url) {
                    if (set.@loaded == "true") {
                      name ||= 'GPX file';
                      var layer:VectorLayer = new VectorLayer(name, _map, 'gpx.css');
                      _map.addVectorLayer(layer);
                      var gpxImporter:GpxImporter = new GpxImporter(layer, layer.paint, [String(set.url)]);
                    } else {
                      trace("configured but not loaded isn't supported yet");
                    }
                  } else {
                    trace("AutoVectorBackground: no url for GPXImporter");
                  }
                  break;

                case "BugLoader":
                  if (set.url && set.apiKey) {
                    name ||= 'Bugs';
                    var bugLoader:BugLoader = new BugLoader(_map, String(set.url), String(set.apikey), name, String(set.details));
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
                    var bikeShopLoader:BikeShopLoader = new BikeShopLoader(_map, String(set.url), name);
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