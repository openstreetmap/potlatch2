package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class NumberEditorFactory extends SingleTagEditorFactory {
        private var _minimum:Number;
        private var _maximum:Number;
        private var _stepSize:Number;
	    private var _notPresentText:String;

        public function NumberEditorFactory(inputXML:XML) {
            super(inputXML);
            _minimum = parseFloat(inputXML.hasOwnProperty("@minimum") ? String(inputXML.@minimum) : "0");
            _maximum = parseFloat(inputXML.hasOwnProperty("@maximum") ? String(inputXML.@maximum) : "100");
            _stepSize = parseFloat(inputXML.hasOwnProperty("@stepSize") ? String(inputXML.@stepSize) : "1");
            _notPresentText = inputXML.hasOwnProperty("@absenceText") ? String(inputXML.@absenceText) : "Unset";
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new NumberEditor();
        }
        
        public function get minimum():Number { return _minimum; }
        public function get maximum():Number { return _maximum; }
        public function get stepSize():Number { return _stepSize; }
        public function get notPresentText():String { return _notPresentText; }
    }

}


