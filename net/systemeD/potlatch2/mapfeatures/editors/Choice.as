package net.systemeD.potlatch2.mapfeatures.editors {

    import flash.events.*;

	public class Choice extends EventDispatcher {

        [Bindable]
        public var label:String = "";
        [Bindable]
        public var description:String = "";
        [Bindable]
        public var value:String = null;
        [Bindable]
        public var icon:String = null;

        private var _match:RegExp = null;
        
        public function isTagMatch(tagValue:String):Boolean {
            if ( _match == null )
                return tagValue == value;
            return _match.test(tagValue);
        }
        
        public function set match(matchStr:String):void {
            if ( matchStr != null && matchStr != "" ) {
                _match = new RegExp("^("+matchStr+")$");
            }
        }
    }

}


