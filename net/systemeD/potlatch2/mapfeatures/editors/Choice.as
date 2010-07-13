package net.systemeD.potlatch2.mapfeatures.editors {

    import flash.events.*;
    import flash.utils.ByteArray;

	public class Choice extends EventDispatcher {

        [Bindable]
        public var label:String = "";
        [Bindable]
        public var description:String = "";
        [Bindable]
        public var value:String = null;
        [Bindable(event="iconLoaded")]
        public var icon:ByteArray = null;

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
        
        public function imageLoaded(url:String, data:ByteArray):void {
            icon = data;
            dispatchEvent(new Event("iconLoaded"));
        }
    }

}


