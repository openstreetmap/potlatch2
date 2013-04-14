package net.systemeD.potlatch2.mapfeatures.editors {

    import flash.display.*;
    
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;

    public class RelationMemberEditorFactory extends EditorFactory {
        /** Contains "route"=["hiking","foot"] key/values. The &lt;match&gt; map_features tag is parsed here from
        * "hiking|foot" pipe-separated values. */
        private var _relationTagPatterns:Object;
        private var _role:String;
        
        /** Constructs the editing panel for a relation(###), given its &lt;relation&gt; in map_features.xml */
        public function RelationMemberEditorFactory(inputXML:XML) {
            super(inputXML);
            _relationTagPatterns = {};
            for each(var match:XML in inputXML.match) {
                _relationTagPatterns[match.@k] = match.@v.split('|');
            }
            for each(var role:XML in inputXML.role) {
                _role=role.@role;
            }
        }
        
        public function get relationTagPatterns():Object {
            return _relationTagPatterns;
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
                for ( var k:String in _relationTagPatterns ) {
                    var relVal:String = relation.getTag(k);
                    if (_relationTagPatterns[k].indexOf(relVal) < 0) { match=false; break; }
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


