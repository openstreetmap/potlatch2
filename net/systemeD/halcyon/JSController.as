package net.systemeD.halcyon {
    import net.systemeD.halcyon.connection.*;
	import flash.events.*;
    import flash.external.ExternalInterface;

	/* JSController provides an interface for Halcyon to call the enclosing page, via JavaScript
	  */

    public class JSController implements MapController {

        private var map:Map;
		private var jsresponder:String;					// JavaScript function called when user clicks

        public function JSController(map:Map, jsresponder:String) {
            this.map = map;
            this.jsresponder = jsresponder;
        }

        public function setActive():void {
            map.setController(this);
        }

        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            if ( event.type == MouseEvent.CLICK )
				ExternalInterface.call(jsresponder, 'click', entity.getType(), entity.id, entity.getTagsCopy());
        }

    }

}

