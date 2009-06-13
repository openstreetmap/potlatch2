package net.systemeD.halcyon.mapfeatures {

    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

	import flash.system.Security;
	import flash.net.*;

    import net.systemeD.halcyon.connection.*;


	public class MapFeatures {
        private static var instance:MapFeatures;

        public static function getInstance():MapFeatures {
            if ( instance == null ) {
                instance = new MapFeatures();
                instance.loadFeatures();
            }
            return instance;
        }



        private var xml:XML = null;

        protected function loadFeatures():void {
            var request:URLRequest = new URLRequest("map_features.xml");
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onFeatureLoad);
            loader.load(request);
        }

        private function onFeatureLoad(event:Event):void {
            xml = new XML(URLLoader(event.target).data);
        }

        public function hasLoaded():Boolean {
            return xml != null;
        }

        public function findMatchingFeature(entity:Entity):XML {
            if ( xml == null )
                return null;

            for each(var feature:XML in xml.feature) {
                // check for matching tags
                var match:Boolean = true;
                for each(var tag:XML in feature.tag) {
                    var entityTag:String = entity.getTag(tag.@k);
                    match = entityTag == tag.@v || (entityTag != null && tag.@v == "*");
                    if ( !match ) break;
                }
                if ( match )
                    return feature;
            }
            return null;
        }
    }

}


