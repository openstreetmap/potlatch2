package net.systemeD.potlatch2.mapfeatures {

    import net.systemeD.halcyon.connection.*;

        /** This class defines the behaviour of the "Presence" attribute in a Map Feature definition. Presence is one of "always", "onTagMatch" or "withCategory".
        * This is used to control whether edit controls for a feature show up on an given edit page.
        */
	public class Presence {
	    private static var ALWAYS:Presence;
	    private static var ON_TAG_MATCH:Presence;
	    private static var WITH_CATEGORY:Presence;

        /** Translates a string from the XML form (eg "onTagMatch") to a constant (ON_TAG_MATCH) */
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

        /** Determines whether a given edit control (editor) should be used for a given entity, given a certain category page is open.
        *
        * If not overriden by a child class, the behaviour is "always": show the edit control on the "Basic" page, and on the appropriate category page.
        *
        */
        public function isEditorPresent(editor:EditorFactory, forEntity:Entity, forCategory:String):Boolean {
            return forCategory == null || forCategory == editor.category;
        }

    }

}

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    /** Special behaviour for the "onTagMatch" case: only show the edit controls if the tags specified for the feature are present on the entity. */
    class OnTagMatch extends Presence {
        public function OnTagMatch() {}

        override public function isEditorPresent(editor:EditorFactory, forEntity:Entity, forCategory:String):Boolean {
            return (forCategory == null || forCategory == editor.category) &&
                      editor.areTagsMatching(forEntity);
        }
    }

    /** Special behaviour for the "withCategory" case: only show the edit controls if the tags specified for the feature are present on the entity AND
     * if the appropriate category page is open. */
    class WithCategory extends Presence {
        public function WithCategory() {}

        override public function isEditorPresent(editor:EditorFactory, forEntity:Entity, forCategory:String):Boolean {
            return forCategory == editor.category &&
                      editor.areTagsMatching(forEntity);
        }
    }

