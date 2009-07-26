package net.systemeD.halcyon.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;

	public class Category extends EventDispatcher {
        private var mapFeatures:MapFeatures;
        private var _name:String;
        private var _id:String;
        private var _features:Array;

        public function Category(mapFeatures:MapFeatures, name:String, id:String) {
            this.mapFeatures = mapFeatures;
            this._name = name;
            this._id = id;
            
            _features = new Array();
            for each( var feature:Feature in mapFeatures.features ) {
                if ( feature.isInCategory(id) )
                    _features.push(feature);
            }
        }

        public function get id():String {
            return _id;
        }

        [Bindable(event="categoryChange")]
        public function get name():String {
            return _name;
        }
        
        [Bindable(event="featuresChanged")]
        public function get features():Array {
            return _features;
        }
    }
}


