package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class SpeedEditorFactory extends SingleTagEditorFactory {
        
        public function SpeedEditorFactory(inputXML:XML) {
            super(inputXML);
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new SpeedEditor();
        }
    }

}


