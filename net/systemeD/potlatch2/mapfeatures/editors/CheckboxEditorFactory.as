package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class CheckboxEditorFactory extends SingleTagEditorFactory {
	    private var _notPresentText:String;
	    private var _notBooleanText:String;
        
        public function CheckboxEditorFactory(inputXML:XML) {
            super(inputXML);
            _notPresentText = inputXML.hasOwnProperty("@absenceText") ? String(inputXML.@absenceText) : "Unset";
            _notBooleanText = inputXML.hasOwnProperty("@invalidText") ? String(inputXML.@invalidText) : "Not yes/no";
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new CheckboxEditor();
        }
        
        public function get notPresentText():String { return _notPresentText; }
        public function get notBooleanText():String { return _notBooleanText; }
    }

}


