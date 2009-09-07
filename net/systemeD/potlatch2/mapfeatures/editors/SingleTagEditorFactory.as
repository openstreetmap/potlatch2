package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class SingleTagEditorFactory extends EditorFactory {
	    private var tagKey:String;
        
        public function SingleTagEditorFactory(inputXML:XML) {
            super(inputXML);
            tagKey = inputXML.@key;
        }
        
        override public function areTagsMatching(entity:Entity):Boolean {
            return entity.getTag(tagKey) != null;
        }

        public function get key():String {
            return tagKey;
        }
        
        override public function createEditorInstance(entity:Entity):DisplayObject {
            var editor:SingleTagEditor = createSingleTagEditor();
            editor.factory = this;
            editor.entity = entity;
            return editor;
        }
        
        protected function createSingleTagEditor():SingleTagEditor {
            return null;
        }
    }

}


