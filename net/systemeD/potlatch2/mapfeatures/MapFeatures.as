package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.net.URLLoader;

	import flash.system.Security;
	import flash.net.*;

	import mx.core.UIComponent;
	import mx.controls.DataGrid;

    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.DebugURLRequest;

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
		private var _keys:Array = null;
		private var _tags:Object = null;

        protected function loadFeatures():void {
            var request:DebugURLRequest = new DebugURLRequest("map_features.xml");
            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, onFeatureLoad);
            loader.load(request.request);
        }

        internal function get definition():XML {
            return xml;
        }
        
        private function onFeatureLoad(event:Event):void {
			var f:Feature;

            xml = new XML(URLLoader(event.target).data);
            _features = [];
			_keys = [];
			_tags = {};

            for each(var feature:XML in xml.feature) {
                f=new Feature(this,feature);
				_features.push(f);
				for each (var tag:Object in f.tags) {
					if (!_tags[tag.k]) { _tags[tag.k]=new Object; _keys.push(tag.k); }
					_tags[tag.k][tag.v]=true;
				}
            }            
			_keys.sort();

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
                var match:Boolean = true;

                // check for matching tags
                for each(var tag:Object in feature.tags) {
                    var entityTag:String = entity.getTag(tag.k);
                    match = entityTag == tag.v || (entityTag != null && tag.v == "*");
                    if ( !match ) break;
                }

				// check for matching withins
				if (match) {
					for each (var within:Object in feature.withins) {
						match = entity.countParentObjects(within) >= (within.minimum ? within.minimum : 1);
						if (!match) { break; }
					}
				}

                if (match) {
                    return feature;
				}
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
                return []; //_categories;
                
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

        [Bindable(event="featuresLoaded")]
        public function get pois():Array {
            if (xml == null )
                return null;
            var pois:Array = [];
            var counter:int = 0;
            for each ( var feature:Feature in _features ) {
              if (feature.isType("point")) {
                pois.push(feature);
              }
            }
            return pois;
        }

		[Bindable(event="featuresLoaded")]
		public function getAutoCompleteKeys():Array {
			return _keys;
		}
		
		public function getAutoCompleteValues(key:String):Array {
			var list:Array=[];
			for (var v:String in _tags[key]) { list.push(v); }
			list.sort();
			return list;
		}
		
    }

}


