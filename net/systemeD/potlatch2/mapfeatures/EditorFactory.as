package net.systemeD.potlatch2.mapfeatures {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.editors.*;
    import flash.display.*;


	public class EditorFactory {
	    private static const PRIORITY_HIGHEST:uint = 10;
	    private static const PRIORITY_HIGH:uint = 8;
	    private static const PRIORITY_NORMAL:uint = 5;
	    private static const PRIORITY_LOW:uint = 2;
	    private static const PRIORITY_LOWEST:uint = 0;
	
        public static function createFactory(inputType:String, inputXML:XML):EditorFactory {
            switch ( inputType ) {
            
            case "freetext": return new FreeTextEditorFactory(inputXML);
            case "checkbox": return new CheckboxEditorFactory(inputXML);
            case "choice": return new ChoiceEditorFactory(inputXML);
            case "speed": return new SpeedEditorFactory(inputXML);
            case "route": return new RouteEditorFactory(inputXML);
            case "turn": return new TurnRestrictionEditorFactory(inputXML);
            
            }
            
            return null;
        }

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
        
        public var presence:Presence = Presence.getPresence("onTagMatch");
        public var sortOrder:uint = PRIORITY_NORMAL;
        public var category:String = "Standard";
        
        private var _name:String;
        private var _description:String;
        
        public function EditorFactory(inputXML:XML) {
            _name = String(inputXML.@name);
            _description = String(inputXML.@description);
            category = String(inputXML.@category);
        }
        
        public function areTagsMatching(entity:Entity):Boolean {
            return true;
        }

        public function createEditorInstance(entity:Entity):DisplayObject {
            return null;
        }
        
        public function get name():String {
            return _name;
        }

        public function get description():String {
            return _description;
        }

    }

}


