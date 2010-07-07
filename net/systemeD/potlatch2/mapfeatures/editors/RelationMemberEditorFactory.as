package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class RelationMemberEditorFactory extends EditorFactory {
	    private var _relationTags:Object;
		private var _role:String;
        
        public function RelationMemberEditorFactory(inputXML:XML) {
            super(inputXML);
            _relationTags = {};
            for each(var match:XML in inputXML.match) {
                _relationTags[match.@k] = match.@v;
            }
			for each(var role:XML in inputXML.role) {
				_role=role.@role;
			}
        }
        
        public function get relationTags():Object {
            return _relationTags;
        }
        
        public function get role():String {
            return _role;
        }
        
        override public function areTagsMatching(entity:Entity):Boolean {
            var parentRelations:Array = entity.parentRelations;
            if ( parentRelations.length == 0 )
                return false;

            // get relations for the entity
            for each(var relation:Relation in parentRelations) {
				var match:Boolean=true;
                for ( var k:String in _relationTags ) {
                    var relVal:String = relation.getTag(k);
                    if ( relVal != _relationTags[k] ) { match=false; break; }
					if ( _role && !relation.hasMemberInRole(entity,_role) ) { match=false; break; }
                }
				if (match) { return true; }
            }
			return false;
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


