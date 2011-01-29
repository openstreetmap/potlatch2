package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.net.*;
    import flash.utils.ByteArray;
    import mx.core.BitmapAsset;
    import mx.graphics.codec.PNGEncoder;

    import net.systemeD.halcyon.connection.Entity;
    import net.systemeD.potlatch2.utils.CachedDataLoader;

        /** A "map feature" is sort of a template for a map entity. It consists of a few crucial key/value pairs that define the feature, so that
         * entities can be recognised. It also contains optional keys, with associated editing controls, that are defined as being appropriate
         * for the feature. */
	public class Feature extends EventDispatcher {
        private var mapFeatures:MapFeatures;
        private var _xml:XML;
        private static var variablesPattern:RegExp = /[$][{]([^}]+)[}]/g;
        private var _tags:Array;
	private var _withins:Array;
        private var _editors:Array;

        [Embed(source="../../../../embedded/missing_icon.png")]
        [Bindable]
        public var missingIconCls:Class;


        public function Feature(mapFeatures:MapFeatures, _xml:XML) {
            this.mapFeatures = mapFeatures;
            this._xml = _xml;
            parseConditions();
            parseEditors();
        }

        private function parseConditions():void {
            _tags = [];
           _withins = [];

			// parse tags
            for each(var tag:XML in definition.tag) {
                _tags.push( { k:String(tag.@k), v:String(tag.@v)} );
            }

			// parse 'within'
            for each(var within:XML in definition.within) {
				var obj:Object= { entity:within.@entity, k:within.@k };
				if (within.attribute('v'      ).length()>0) { obj['v'      ]=within.@v;       }
				if (within.attribute('minimum').length()>0) { obj['minimum']=within.@minimum; }
				if (within.attribute('role'   ).length()>0) { obj['role'   ]=within.@role;    }
                _withins.push(obj);
            }
        }

        private function parseEditors():void {
            _editors = new Array();

            addEditors(definition);

            _editors.sortOn(["sortOrder", "name"], [Array.DESCENDING | Array.NUMERIC, Array.CASEINSENSITIVE]);
        }

        private function addEditors(xml:XML):void {
            var inputXML:XML;

            for each(var inputSetRef:XML in xml.inputSet) {
                var setName:String = String(inputSetRef.@ref);
                for each (inputXML in mapFeatures.definition.inputSet.(@id==setName)) {
                    addEditors(inputXML);
                }
            }

            for each(inputXML in xml.input) {
                addEditor(inputXML);
            }
        }

        private function addEditor(inputXML:XML):void {
            var inputType:String = inputXML.@type;
            var presenceStr:String = inputXML.@presence;
            var sortOrderStr:String = inputXML.@priority;
//          _tags.push( { k:String(inputXML.@key) } ); /* add the key to tags so that e.g. addr:housenumber shows up on autocomplete */
            var editor:EditorFactory = EditorFactory.createFactory(inputType, inputXML);
            if ( editor != null ) {
                editor.presence = Presence.getPresence(presenceStr);
                editor.sortOrder = EditorFactory.getPriority(sortOrderStr);
                _editors.push(editor);
            }
        }

        /** List of editing controls associated with this feature. */
        public function get editors():Array {
            return _editors;
        }

        /** The XML subtree that this feature was loaded from. */
        public function get definition():XML {
            return _xml;
        }

        [Bindable(event="nameChanged")]
        /** The human-readable name of the feature, or null if none. */
        public function get name():String {
			if (_xml.attribute('name').length()>0) { return _xml.@name; }
			return null;
        }

        [Bindable(event="imageChanged")]
        /** An icon for the feature. If none is defined, return default "missing icon". */
        public function get image():ByteArray {
            var icon:XMLList = _xml.icon;
            var imageURL:String = null;
            var img:ByteArray;

            if ( icon.length() > 0 && icon[0].hasOwnProperty("@image") )
                imageURL = icon[0].@image;

            if ( imageURL != null ) {
                img = CachedDataLoader.loadData(imageURL, imageLoaded);
            }
            if (img) {
              return img;
            }
            var bitmap:BitmapAsset = new missingIconCls() as BitmapAsset;
            return new PNGEncoder().encode(bitmap.bitmapData);
        }

        private function imageLoaded(url:String, data:ByteArray):void {
            dispatchEvent(new Event("imageChanged"));
        }

        public function htmlDetails(entity:Entity):String {
            var icon:XMLList = _xml.icon;
            return makeHTMLIcon(icon, entity);
        }

        public static function makeHTMLIcon(icon:XMLList, entity:Entity):String {
            if ( icon == null )
                return "";

            var txt:String = icon.children().toXMLString();
            var replaceTag:Function = function():String {
                var value:String = entity.getTag(arguments[1]);
                return value == null ? "" : htmlEscape(value);
            };
            txt = txt.replace(variablesPattern, replaceTag);
            return txt;
        }

        public static function htmlEscape(str:String):String {
            var newStr:String = str.replace(/&/g, "&amp;");
            newStr = newStr.replace(/</g, "&lt;");
            newStr = newStr.replace(/>/g, "&gt;");
            newStr = newStr.replace(/"/g, "&quot;");	// "
            newStr = newStr.replace(/'/g, "&apos;");	// '
            return newStr;
        }

        /** Whether this feature belongs to the given category or not, as defined by its definition in the XML file. */
        public function isInCategory(category:String):Boolean {
            var cats:XMLList = _xml.category;
            if ( cats.length() == 0 )
                return false;

            for each( var cat:XML in cats )
                if ( cat.text()[0] == category )
                    return true;
            return false;
        }


        /** List of {k, v} pairs that define the feature. */
        public function get tags():Array {
            return _tags;
        }

        /** List of "withins" which further restrict the applicability of the feature. Each within is a {entity, k, ?v, ?minimum, ?role} object. */
        public function get withins():Array {
            return _withins;
        }

        /** The first category that the feature belongs to, as defined by the order of the map features XML file. */
        public function findFirstCategory():Category {
            for each( var cat:Category in mapFeatures.categories ) {
                if ( isInCategory(cat.id) )
                    return cat;
            }
            return null;
        }

        /** Whether the feature is of the given type (point, line/area, relation). */
        public function isType(type:String):Boolean {
            if (type=='area') {
			    return (_xml.elements(type).length() > 0) || (_xml.elements('line').length() > 0);
            } else {
			    return _xml.elements(type).length() > 0;
			}
        }

        /** Whether there is a help string defined. */
        public function hasHelpURL():Boolean {
            return _xml.help.length() > 0;
        }

        /** The defined help string, if any. */
        public function get helpURL():String {
            return _xml.help;
        }
    }
}

