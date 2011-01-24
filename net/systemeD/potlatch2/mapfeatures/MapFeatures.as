package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.net.URLLoader;

	import flash.system.Security;
	import flash.net.*;

	import mx.core.UIComponent;
	import mx.controls.DataGrid;

    import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.NestedXMLLoader;

    /** All the information about all available map features that can be selected by the user or matched against entities in the map.
    * The list of map features is populated from an XML file the first time the MapFeatures instance is accessed.
    *
    * <p>There are four "types" of features: point, line, area, relation. However, the autocomplete functions refer to these as node,
    * way (line/area) and relation.</p>
    */
	public class MapFeatures extends EventDispatcher {
        private static var instance:MapFeatures;

        /** Instantiates MapFeatures by loading it if required. */
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

        /** Loads list of map features from XML file which it first retrieves. */
        protected function loadFeatures():void {
            var xmlLoader:NestedXMLLoader = new NestedXMLLoader();
            xmlLoader.addEventListener(Event.COMPLETE, onFeatureLoad);
            xmlLoader.load("map_features.xml");
        }

        /** The loaded source XML file itself. */
        internal function get definition():XML {
            return xml;
        }

        /** Load XML file, then trawl over it, setting up convenient indexes into the list of map features. */
        private function onFeatureLoad(event:Event):void {
			var f:Feature;

            xml = NestedXMLLoader(event.target).xml;
            _features = [];
            _tags = { relation:{}, way:{}, node:{} };

            for each(var feature:XML in xml..feature) {
                f=new Feature(this,feature);
                _features.push(f);
                for each (var tag:Object in f.tags) {
                    if (f.isType('line') || f.isType('area')) { addToTagList('way',tag); }
                    if (f.isType('relation'))                 { addToTagList('relation',tag); }
                    if (f.isType('point'))                    { addToTagList('node',tag); }
                }
            }

            _categories = new Array();
            for each(var catXML:XML in xml.category) {
                if ( catXML.child("category").length() == 0 )
                  _categories.push(new Category(this, catXML.@name, catXML.@id, _categories.length));
            }
            dispatchEvent(new Event("featuresLoaded"));
        }

        /** Add one item to tagList index, which will end up being a list like: ["way"]["highway"]["residential"] */
		private function addToTagList(type:String,tag:Object):void {
			if (tag.v=='*') { return; }
			if (!_tags[type][tag.k]) { _tags[type][tag.k]=new Array(); }
			if (_tags[type][tag.k].indexOf(tag.v)==-1) { _tags[type][tag.k].push(tag.v); }
		}

        /** Indicates whether the XML file has finished being loaded. */
        public function hasLoaded():Boolean {
            return xml != null;
        }

        /** Find the first Feature (template) that matches the given Entity (actual existing object in the map).
         *
         * This is done to provide appropriate editing controls that correspond to the selected Entity.
         *
         * @param entity The Entity to try and match against.
         * @return The first suitable Feature, or null. */

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


        /** Array of every Category found in the map features file. */
        [Bindable(event="featuresLoaded")]
        public function get categories():Array {
            if ( xml == null )
                return null;
            return _categories;
        }

        /** Categories that contain at least one Feature corresponding to a certain type, such as "area" or "point".
        *
        * @return Filtered Array of Category objects, possibly empty. null if XML file is not yet processed.
        */
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

        /** All features.
        *
        * @return null if XML file not yet processed. */
        [Bindable(event="featuresLoaded")]
        public function get features():Array {
            if ( xml == null )
                return null;
            return _features;
        }

        /** All Features of type "point".
        *
        * @return null if XML file not yet processed.
        */
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

        /** A list of all Keys for all features of the given type, sorted.
         * @example <listing version="3.0">getAutoCompleteKeys ("way")</listing>
         * Returns: [{name: "building"}, {name: "highway"}...]
         */
        [Bindable(event="featuresLoaded")]
        public function getAutoCompleteKeys(type:String):Array {
            var list:Array=[];
            var a:Array=[];

            for (var k:String in _tags[type]) { list.push(k); }
            list.sort();

            for each (k in list) { a.push( { name: k } ); }
            return a;
        }

        /** Get all the possible values that could go with a given key and type.
        * TODO: Include values previously entered by the user, but not existent in XML file.
        *
        * @example <listing version="3.0">getAutoCompleteValues("way", "highway")</listing>
        * Returns: [{name: "motorway"}, {name: "residential"}...]
        */
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


