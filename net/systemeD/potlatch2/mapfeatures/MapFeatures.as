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
//		private var _keys:Array = null;
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
			_tags = { relation:{}, way:{}, node:{} };

            for each(var feature:XML in xml.feature) {
                f=new Feature(this,feature);
				_features.push(f);
				for each (var tag:Object in f.tags) {
					if (f.isType('line') || f.isType('area')) { addToTagList('way',tag); }
					if (f.isType('relation'))				  { addToTagList('relation',tag); }
					if (f.isType('point'))					  { addToTagList('node',tag); }
				}
            }            

            _categories = new Array();
            for each(var catXML:XML in xml.category) {
                if ( catXML.child("category").length() == 0 )
                  _categories.push(new Category(this, catXML.@name, catXML.@id, _categories.length));
            }
            dispatchEvent(new Event("featuresLoaded"));
        }

		private function addToTagList(type:String,tag:Object):void {
			if (tag.v=='*') { return; }
			if (!_tags[type][tag.k]) { _tags[type][tag.k]=new Array(); }
			if (_tags[type][tag.k].indexOf(tag.v)==-1) { _tags[type][tag.k].push(tag.v); }
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
		public function getAutoCompleteKeys(type:String):Array {
			var list:Array=[];
			var a:Array=[];

			for (var k:String in _tags[type]) { list.push(k); }
			list.sort();

			for each (k in list) { a.push( { name: k } ); }
			return a;
		}
		
		[Bindable(event="featuresLoaded")]
		public function getAutoCompleteValues(type:String,key:String):Array {
			var a:Array=[];
			if (_tags[type][key]) {
				_tags[type][key].sort();
				for each (var v:String in _tags[type][key]) { a.push( { name: v } ); }
			}
			return a;
		}
		
    }

}


