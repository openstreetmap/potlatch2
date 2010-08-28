package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class SliderEditorFactory extends SingleTagEditorFactory {
        private var _minimum:Number;
        private var _maximum:Number;
        private var _default:Number;
        private var _defaultName:String;
        private var _snapInterval:Number;
        private var _labels:Array;

        public function SliderEditorFactory(inputXML:XML) {
            super(inputXML);
            _minimum = parseFloat(inputXML.hasOwnProperty("@minimum") ? String(inputXML.@minimum) : "0");
            _maximum = parseFloat(inputXML.hasOwnProperty("@maximum") ? String(inputXML.@maximum) : "100");
            _default = parseFloat(inputXML.hasOwnProperty("@default") ? String(inputXML.@default) : "0");
            _snapInterval = parseFloat(inputXML.hasOwnProperty("@snapInterval") ? String(inputXML.@snapInterval) : "1");
            _labels = inputXML.hasOwnProperty("@labels") ?
                        String(inputXML.@labels).split(",") :
                        [_minimum.toString(), _maximum.toString()];
            _defaultName = inputXML.hasOwnProperty("@defaultName") ?
                        String(inputXML.@defaultName) : _default.toString();
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new SliderEditor();
        }
        
        public function get minimum():Number { return _minimum; }
        public function get maximum():Number { return _maximum; }
        public function get defaultValue():Number { return _default; }
        public function get defaultValueName():String { return _defaultName; }
        public function get snapInterval():Number { return _snapInterval; }
        public function get labels():Array { return _labels; }
    }

}


