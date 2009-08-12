package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;
    import net.systemeD.halcyon.connection.Entity;

	public class Feature extends EventDispatcher {
        private var mapFeatures:MapFeatures;
        private var _xml:XML;
        private static var variablesPattern:RegExp = /[$][{]([^}]+)[}]/g;
        private var _tags:Array;

        public function Feature(mapFeatures:MapFeatures, _xml:XML) {
            this.mapFeatures = mapFeatures;
            this._xml = _xml;
            _tags = new Array();
            
            for each(var tag:XML in definition.tag) {
                var tagObj:Object = new Object();
                tagObj["k"] = tag.@k;
                tagObj["v"] = tag.@v;
                _tags.push(tagObj);
            }

        }
        
        public function get definition():XML {
            return _xml;
        }
    
        [Bindable(event="nameChanged")]
        public function get name():String {
            return _xml.@name;
        }
    
        [Bindable(event="imageChanged")]
        public function get image():String {
            var icon:XMLList = _xml.icon;

            if ( icon.length() > 0 && icon[0].hasOwnProperty("@image") )
                return icon[0].@image;
            else
                return null;
        }
        
        public function htmlDetails(entity:Entity):String {
            var icon:XMLList = _xml.icon;
            if ( icon == null )
                return "";

            var txt:String = icon.children().toXMLString();
            var replaceTag:Function = function():String {
                var value:String = entity.getTag(arguments[1]);
                return value == null ? "" : value;
            };
            txt = txt.replace(variablesPattern, replaceTag);
            return txt;
        }
        
        public function isInCategory(category:String):Boolean {
            var cats:XMLList = _xml.category;
            if ( cats.length() == 0 )
                return false;
                
            for each( var cat:XML in cats )
                if ( cat.text()[0] == category )
                    return true;
            return false;
        }
        
        public function get tags():Array {
            return _tags;
        }
        
        public function findFirstCategory():Category {
            for each( var cat:Category in mapFeatures.categories ) {
                if ( isInCategory(cat.id) )
                    return cat;
            }
            return null;
        }
    }
}

