package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;

	public class Category extends EventDispatcher {
        private var mapFeatures:MapFeatures;
        private var _name:String;
        private var _id:String;
        private var _features:Array;
        private var _index:uint;

        public function Category(mapFeatures:MapFeatures, name:String, id:String, globalIndex:uint) {
            this.mapFeatures = mapFeatures;
            this._name = name;
            this._id = id;
            this._index = globalIndex;
            
            _features = new Array();
            for each( var feature:Feature in mapFeatures.features ) {
                if ( feature.isInCategory(id) )
                    _features.push(feature);
            }
        }

        public function get id():String {
            return _id;
        }
        
        public function get index():uint {
            return _index;
        }

        [Bindable(event="categoryChange")]
        public function get name():String {
            return _name;
        }
        
        [Bindable(event="featuresChanged")]
        public function get features():Array {
            return _features;
        }
        
        [Bindable(event="featuresChanged")]
        public function getFeaturesForType(type:String):Array {
            if ( type == null || type == "" )
                return []; //_features;
                
            var filteredFeatures:Array = new Array();
            for each( var feature:Feature in _features ) {
                if ( feature.isType(type) )
                    filteredFeatures.push(feature);
            }
            return filteredFeatures;
        }
        
    }
}


