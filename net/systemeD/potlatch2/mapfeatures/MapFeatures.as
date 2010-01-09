package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

	import flash.system.Security;
	import flash.net.*;

    import net.systemeD.halcyon.connection.*;


	public class MapFeatures extends EventDispatcher {
        private static var instance:MapFeatures;

        public static function getInstance():MapFeatures {
            if ( instance == null ) {
                instance = new MapFeatures();
                instance.loadFeatures();
            }
            return instance;
        }



        private var xml:XML = null;
        private var _features:Array = null;
        private var _categories:Array = null;

        protected function loadFeatures():void {
            var request:URLRequest = new URLRequest("map_features.xml?"+Math.random());
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onFeatureLoad);
            loader.load(request);
        }

        internal function get definition():XML {
            return xml;
        }
        
        private function onFeatureLoad(event:Event):void {
            xml = new XML(URLLoader(event.target).data);
            
            _features = new Array();
            for each(var feature:XML in xml.feature) {
                _features.push(new Feature(this, feature));
            }            
            _categories = new Array();
            for each(var catXML:XML in xml.category) {
                if ( catXML.child("category").length() == 0 )
                  _categories.push(new Category(this, catXML.@name, catXML.@id, _categories.length));
            }
            dispatchEvent(new Event("featuresLoaded"));
        }

        public function hasLoaded():Boolean {
            return xml != null;
        }

        public function findMatchingFeature(entity:Entity):Feature {
            if ( xml == null )
                return null;

            for each(var feature:Feature in features) {
                // check for matching tags
                var match:Boolean = true;
                for each(var tag:Object in feature.tags) {
                    var entityTag:String = entity.getTag(tag.k);
                    match = entityTag == tag.v || (entityTag != null && tag.v == "*");
                    if ( !match ) break;
                }
                if ( match )
                    return feature;
            }
            return null;
        }
        
        [Bindable(event="featuresLoaded")]
        public function get categories():Array {
            if ( xml == null )
                return null;        
            return _categories;
        }

        [Bindable(event="featuresLoaded")]
        public function getCategoriesForType(type:String):Array {
            if ( xml == null )
                return null;
            if ( type == null || type == "" )  
                return _categories;
                
            var filteredCategories:Array = new Array();
            for each( var cat:Category in _categories ) {
                if ( cat.getFeaturesForType(type).length > 0 )
                    filteredCategories.push(cat);
            }
            return filteredCategories;
        }

        [Bindable(event="featuresLoaded")]
        public function get features():Array {
            if ( xml == null )
                return null;            
            return _features;
        }

    }

}


