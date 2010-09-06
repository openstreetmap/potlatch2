package net.systemeD.potlatch2.mapfeatures {

    import net.systemeD.halcyon.connection.*;


	public class Presence {
	    private static var ALWAYS:Presence;
	    private static var ON_TAG_MATCH:Presence;
	    private static var WITH_CATEGORY:Presence;
	
        public static function getPresence(presence:String):Presence {
            if ( ALWAYS == null ) {
                ALWAYS = new Presence();
                ON_TAG_MATCH = new OnTagMatch();
                WITH_CATEGORY = new WithCategory();
            }
            if ( presence == "always" )
                return ALWAYS;
            if ( presence == "onTagMatch" )
                return ON_TAG_MATCH;
            if ( presence == "withCategory" )
                return WITH_CATEGORY;
            return ON_TAG_MATCH;
        }

        public function isEditorPresent(editor:EditorFactory, forEntity:Entity, forCategory:String):Boolean {
            return forCategory == null || forCategory == editor.category;
        }

    }

}

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;

    class OnTagMatch extends Presence {
        public function OnTagMatch() {}
        
        override public function isEditorPresent(editor:EditorFactory, forEntity:Entity, forCategory:String):Boolean {
            return (forCategory == null || forCategory == editor.category) &&
                      editor.areTagsMatching(forEntity);
        }
    }

    class WithCategory extends Presence {
        public function WithCategory() {}
        
        override public function isEditorPresent(editor:EditorFactory, forEntity:Entity, forCategory:String):Boolean {
            return forCategory == editor.category &&
                      editor.areTagsMatching(forEntity);
        }
    }

