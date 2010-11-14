package net.systemeD.potlatch2.mapfeatures.editors {

	import net.systemeD.halcyon.connection.*;
	import net.systemeD.potlatch2.mapfeatures.*;
	import flash.display.*;

	public class TurnRestrictionEditorFactory extends RelationMemberEditorFactory {

		public function TurnRestrictionEditorFactory(inputXML:XML) {
			super(inputXML);
		}
		
		override protected function createRelationMemberEditor():RelationMemberEditor {
			return new TurnRestrictionEditor();
		}

	}

}
