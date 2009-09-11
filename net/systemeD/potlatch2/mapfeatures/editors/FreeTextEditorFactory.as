package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class FreeTextEditorFactory extends SingleTagEditorFactory {
	    private var _notPresentText:String;
        
        public function FreeTextEditorFactory(inputXML:XML) {
            super(inputXML);
            _notPresentText = inputXML.hasOwnProperty("@absenceText") ? String(inputXML.@absenceText) : "Unset";
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new FreeTextEditor();
        }
        
        public function get notPresentText():String {
            return _notPresentText;
        }
    }

}


