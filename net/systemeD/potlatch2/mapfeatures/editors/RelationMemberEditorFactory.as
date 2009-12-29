package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class RelationMemberEditorFactory extends EditorFactory {
	    private var _relationTags:Object;
        
        public function RelationMemberEditorFactory(inputXML:XML) {
            super(inputXML);
            _relationTags = {};
            for each(var match:XML in inputXML.match) {
                _relationTags[match.@k] = match.@v;
            }
        }
        
        public function get relationTags():Object {
            return _relationTags;
        }
        
        override public function areTagsMatching(entity:Entity):Boolean {
            var parentRelations:Array = entity.parentRelations;
            if ( parentRelations.length == 0 )
                return false;
                
            // get relations for the entity
            for each(var relation:Relation in parentRelations) {
                for ( var k:String in _relationTags ) {
                    var relVal:String = relation.getTag(k);
                    if ( relVal != _relationTags[k] )
                        return false;
                }
            }
            // all must match
            return true;
        }
        
        override public function createEditorInstance(entity:Entity):DisplayObject {
            var editor:RelationMemberEditor = createRelationMemberEditor();
            editor.factory = this;
            editor.entity = entity;
            return editor;
        }
        
        protected function createRelationMemberEditor():RelationMemberEditor {
            return null;
        }
    }

}


