package net.systemeD.potlatch2.mapfeatures.editors {

    import flash.events.*;

	public class SpeedChoice extends EventDispatcher {

        private static const speedRE:RegExp = /^([0-9.]+)\s*(.*)$/;
        
        private var _scalar:Number = -1;
        private var _unit:String = null;
        private var _description:String = "";
        private var _value:String = null;
        private var _isEditable:Boolean = false;
        
        public function SpeedChoice(speedStr:String) {
            value = speedStr;
        }
        
        private function parseSpeedString(speedStr:String):Object {
            var match:Object = speedRE.exec(speedStr);
            if ( match == null )
                return null;
            
            try {
                var scalar:Number = Number(match[1]);
                var unit:String = match[2].replace(/\s/g, "");
                if ( unit == null || unit == "" || unit == "kph" || unit == "kmh" )
                    unit = "km/h";
                return {scalar: scalar, unit: unit};
            } catch ( exception:Object ) {
                return null;
            }
            
            return null;
        }
        
        [Bindable(event="valueChange")]
        public function get scalar():String { return String(_scalar); }

        [Bindable(event="valueChange")]
        public function get description():String { return _description; }

        [Bindable(event="valueChange")]
        public function get value():String { return _value; }

        [Bindable(event="valueChange")]
        public function get unit():String { return _unit; }

        [Bindable(event="editableChange")]
        public function get isEditable():Boolean { return _isEditable; }

        public function set isEditable(editable:Boolean):void {
            _isEditable = editable;
            dispatchEvent(new Event("editableChange"));
        }
        
        public function isTagMatch(tagValue:String):Boolean {
            if ( _value == tagValue )
                return true;
            
            var tagSpeed:Object = parseSpeedString(tagValue);
            return tagSpeed != null && tagSpeed.scalar == _scalar && tagSpeed.unit == _unit;
        }
        
        public function set value(speedStr:String):void {
            var speed:Object = parseSpeedString(speedStr);
            if ( speed != null ) {
                _scalar = speed.scalar;
                _unit = speed.unit;
                _description = String(_scalar) + " "+_unit;
                _value = String(_scalar) + (_unit == "km/h" ? "":" "+_unit);
            } else {
                _value = speedStr;
            }
            dispatchEvent(new Event("valueChange"));
        }
    }

}


