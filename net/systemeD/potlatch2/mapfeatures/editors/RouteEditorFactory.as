package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class RouteEditorFactory extends RelationMemberEditorFactory {
        private var _icon:XMLList;
        
        public function RouteEditorFactory(inputXML:XML) {
            super(inputXML);
            _icon = inputXML.icon;
        }
        
        override protected function createRelationMemberEditor():RelationMemberEditor {
            return new RouteEditor();
        }
        
        public function get icon():XMLList {
            return _icon;
        }
    }

}


