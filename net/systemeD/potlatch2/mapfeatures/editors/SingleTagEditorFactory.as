package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

    public class SingleTagEditorFactory extends EditorFactory {
        private var tagKey:String;
        private var boxDirection:String;
        
        public function SingleTagEditorFactory(inputXML:XML, defaultLayout:String="vertical") {
            super(inputXML);
            tagKey = inputXML.@key;
            boxDirection = inputXML.@layout;
            if (!boxDirection) { boxDirection=defaultLayout; }
        }
        
        override public function areTagsMatching(entity:Entity):Boolean {
            return entity.getTag(tagKey) != null;
        }

        public function get key():String {
            return tagKey;
        }
        
        public function get direction():String {
            return "ltr";
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


