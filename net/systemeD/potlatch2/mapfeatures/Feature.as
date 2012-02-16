package net.systemeD.potlatch2.mapfeatures {
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.*;
    import flash.utils.ByteArray;
    
    import mx.core.BitmapAsset;
    import mx.graphics.codec.PNGEncoder;
    
    import net.systemeD.halcyon.ImageBank;
    import net.systemeD.halcyon.connection.Entity;
    import net.systemeD.potlatch2.utils.CachedDataLoader;


    /** A "map feature" is sort of a template for a map entity. It consists of a few crucial key/value pairs that define the feature, so that
     * entities can be recognised. It also contains optional keys, with associated editing controls, that are defined as being appropriate
     * for the feature. */
	public class Feature extends EventDispatcher {
        private var mapFeatures:MapFeatures;
        private var _xml:XML;
        // match ${foo|bar|baz|...} - see makeHTMLIcon()
        private static var variablesPattern:RegExp = /\$\{([^|}]+)\|?([^|}]+)?\|?([^|}]+)?\|?([^|}]+)?\|?([^|}]+)?\|?([^}]+)?\}/g;
        private var _tags:Array;
        private var _withins:Array;
        private var _editors:Array;

        [Embed(source="../../../../embedded/missing_icon.png")]
        [Bindable]
        public var missingIconCls:Class;


        /** Create this Feature from an XML subtree. */
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
                _tags.push( { k:String(tag.@k), v:String(tag.@v), vmatch:String(tag.@vmatch)} );
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
                // Go on then, someone tell me why this stopped working. Namespaces?:
                //for each (inputXML in mapFeatures.definition.inputSet.(@id == setName)) {
                for each (inputXML in mapFeatures.definition.inputSet) {
                    if (inputXML.@id == setName) {
                        addEditors(inputXML);
                    }
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
            var editor:EditorFactory = EditorFactory.createFactory(inputType, inputXML);
            if ( editor != null ) {
                editor.presence = Presence.getPresence(presenceStr);
                editor.sortOrder = editor.getPriority(sortOrderStr);
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
        /** The human-readable name of the feature (name), or null if none. */
        public function get name():String {
			if (_xml.attribute('name').length()>0) { return _xml.@name; }
			return null;
        }

        [Bindable(event="descriptionChanged")]
        /** The human-readable description of the feature, or null if none. */
        public function get description():String {
            var desc:XMLList = _xml.description
            if (desc.length()>0) { return desc[0]; }
            return null;
        }

        /** Returns the icon defined for the feature.
        * This uses the "image" property of the feature's icon element. If no image property is defined, returns a default "missing icon".
        */
        [Bindable(event="imageChanged")]
        public function get image():ByteArray {
            return getImage();
        }

        /** Returns the drag+drop override-icon defined for the feature.
        * This uses the "dnd" property of the feature's icon element, or if there is no override-icon it falls back to the standard image.
        */
        [Bindable(event="imageChanged")]
        public function get dndimage():ByteArray {
            return getImage(true);
        }

        /** Fetches the feature's image, as defined by the icon element in the feature definition.
        * @param dnd if true, overrides the normal image and returns the one defined by the dnd property instead. */
        private function getImage(dnd:Boolean = false):ByteArray {
            var icon:XMLList = _xml.icon;
            var imageURL:String;

            if ( dnd && icon.length() > 0 && icon[0].hasOwnProperty("@dnd") ) {
                imageURL = icon[0].@dnd;
            } else if ( icon.length() > 0 && icon[0].hasOwnProperty("@image") ) {
                imageURL = icon[0].@image;
            }

            if ( imageURL ) {
				if (ImageBank.getInstance().hasImage(imageURL)) {
					return ImageBank.getInstance().getAsByteArray(imageURL)
				} else {
	                return CachedDataLoader.loadData(imageURL, imageLoaded);
				}
            }
            var bitmap:BitmapAsset = new missingIconCls() as BitmapAsset;
            return new PNGEncoder().encode(bitmap.bitmapData);
        }
        
        /** Can this feature be drag-and-dropped from the side panel? By default, any "point" feature can,
        *   unless it has <point draganddrop="no"/> 
        * */
        public function canDND():Boolean {
        	var point:XMLList = _xml.elements("point");
        	return point.length() > 0 && !(XML(point[0]).attribute("draganddrop")[0] == "no");
        }

        private function imageLoaded(url:String, data:ByteArray):void {
            dispatchEvent(new Event("imageChanged"));
        }

        public function htmlDetails(entity:Entity):String {
            var icon:XMLList = _xml.icon;
            return makeHTMLIcon(icon, entity);
        }

        /** Convert the contents of the "icon" tag as an HTML string, with variable substitution:
        *   ${highway} shows the value of the highway key
        *   ${name|operator|network} - if there's no name value, show operator, or network, or nothing.
        *   (${ref}) - renders as nothing if $ref is valueless.
        */
        public static function makeHTMLIcon(icon:XMLList, entity:Entity):String {
            if ( icon == null )
                return "";

            var txt:String = icon.children().toXMLString();
            // Args to this function: "string matched", "substring 1", "substring 2"..., index of match, whole string
            var replaceTag:Function = function():String {
            	var matchnum=0;
            	var args=arguments;
            	var value:String = null;
            	while ((value == null || value == "") && matchnum < args.length - 3  ) {
                  value = entity.getTag(args[matchnum + 1]);
                  matchnum++;
            	}
                return value == null ? "" : htmlEscape(value);
            };
            txt = txt.replace(variablesPattern, replaceTag);
            // a slightly hacky way of making "${name} (${ref})" look ok even if ref is undefined.
            txt = txt.replace("()", ""); 
            return txt;
        }

        /** Basic HTML escaping. */
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

        /** Whether there is a help string defined or one can be derived from tags. */
        public function hasHelpURL():Boolean {
            return _xml.help.length() > 0 || _tags.length > 0;
        }

        /** The defined help string, if any. If none, generate one from tags on the feature, pointing to the OSM wiki. */
        public function get helpURL():String {
        	if (_xml.help.length() > 0)
                return _xml.help;
            else if (_tags.length > 0) {
                if (_tags[0].v == "*")
                    return "http://www.openstreetmap.org/wiki/Key:" + _tags[0].k;
                else
                    return "http://www.openstreetmap.org/wiki/Tag:" + _tags[0].k + "=" + _tags[0].v;                
            } else
                return "";

        }
    }
}

