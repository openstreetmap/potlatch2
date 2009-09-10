package net.systemeD.potlatch2.mapfeatures.editors {

    import flash.events.*;

	public class Choice extends EventDispatcher {

        private var _label:String = "";
        private var _description:String = "";
        private var _value:String = null;
        private var _icon:String = null;
        private var _match:RegExp = null;
        
        [Bindable(event="valueChange")]
        public function get label():String { return _label; }

        [Bindable(event="valueChange")]
        public function get description():String { return _description; }

        [Bindable(event="valueChange")]
        public function get value():String { return _value; }

        [Bindable(event="valueChange")]
        public function get icon():String { return _icon; }

        public function set label(l:String):void {
            _label = l;
            dispatchEvent(new Event("valueChange"));
        }
        
        public function set description(l:String):void {
            _description = l;
            dispatchEvent(new Event("valueChange"));
        }
        
        public function set value(l:String):void {
            _value = l;
            dispatchEvent(new Event("valueChange"));
        }
        
        public function set icon(l:String):void {
            _icon = l;
            dispatchEvent(new Event("valueChange"));
        }
        
        public function isTagMatch(tagValue:String):Boolean {
            if ( _match == null )
                return tagValue == _value;
            //_match.lastIndex = 0;
            //var result:Object = _match.exec(tagValue);
            //return result != null && result.index == 0 && _match.lastIndex == tagValue.length;
            return _match.test(tagValue);
        }
        
        public function set match(matchStr:String):void {
            if ( matchStr != null && matchStr != "" ) {
                _match = new RegExp("^("+matchStr+")$");
            }
        }
    }

}


