package net.systemeD.potlatch2.mapfeatures {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.editors.*;
    import flash.display.*;


	/** Instantiates specific editing controls such as textboxes and speed limit selectors depending on the tags of a given entity. This class has child classes that instantiate the appropriate
	* editors correctly.
	*/
	public class EditorFactory {
	    private static const PRIORITY_HIGHEST:uint = 10;
	    private static const PRIORITY_HIGH:uint = 8;
	    private static const PRIORITY_NORMAL:uint = 5;
	    private static const PRIORITY_LOW:uint = 2;
	    private static const PRIORITY_LOWEST:uint = 0;

        /** Returns a specific subclass of EditorFactory as appropriate for the type: "freetext", "checkbox", "choice", "slider", "number", "speed", "route", "turn". Otherwise null. */
        public static function createFactory(inputType:String, inputXML:XML):EditorFactory {
            switch ( inputType ) {

            case "freetext": return new FreeTextEditorFactory(inputXML);
            case "checkbox": return new CheckboxEditorFactory(inputXML);
            case "choice": return new ChoiceEditorFactory(inputXML);
            case "slider": return new SliderEditorFactory(inputXML);
            case "number": return new NumberEditorFactory(inputXML);
            case "speed": return new SpeedEditorFactory(inputXML);
            case "route": return new RouteEditorFactory(inputXML);
            case "turn": return new TurnRestrictionEditorFactory(inputXML);

            }

            return null;
        }

        /** Translates a priority string ("highest") to a const (PRIORITY_HIGHEST). */
        public static function getPriority(priority:String):uint {
            switch ( priority ) {
            case "highest": return PRIORITY_HIGHEST;
            case "high": return PRIORITY_HIGHEST;
            case "normal": return PRIORITY_NORMAL;
            case "low": return PRIORITY_LOW;
            case "lowest": return PRIORITY_LOWEST;
            default: return PRIORITY_NORMAL;
            }
        }

        /** Default Presence behaviour: onTagMatch */
        public var presence:Presence = Presence.getPresence("onTagMatch");

        /** Default sorting: PRIORITY_NORMAL */
        public var sortOrder:uint = PRIORITY_NORMAL;

        /** Default category: "Standard" */
        public var category:String = "Standard";

        private var _name:String;
        private var _description:String;

        /** The default EditorFactory extracts name, description and category from the provided map features XML subtree. */
        public function EditorFactory(inputXML:XML) {
            _name = String(inputXML.@name);
            _description = String(inputXML.@description);
            category = String(inputXML.@category);
        }

        /** Whether the tags on an entity correspond to those for the edit control. By default, returns true - must be overriden by more useful behaviour. */
        public function areTagsMatching(entity:Entity):Boolean {
            return true;
        }

        /** A subclass must provide an actual edit control. This returns null. */
        public function createEditorInstance(entity:Entity):DisplayObject {
            return null;
        }

        /** The name of the field/tag/edit control, as defined in map features XML. */
        public function get name():String {
            return _name;
        }

        /** The label given to the edited field, as defined in map features XML. */
        public function get description():String {
            return _description;
        }

    }

}


