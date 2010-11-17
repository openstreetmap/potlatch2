package net.systemeD.potlatch2 {

    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.connection.Marker;
    import flash.net.*;
    import flash.events.*;

    public class BugLayer extends VectorLayer {

        private var baseUrl:String;
        private var apiKey:String;

        // as strings, since that's how they are in tags and http calls
        private var BUG_STATUS_OPEN:String = "1";
        private var BUG_STATUS_FIXED:String = "2";
        private var BUG_STATUS_INVALID:String = "3"; // or 'non-reproduceable'

        public function BugLayer(n:String, map:Map, s:String, baseUrl:String, apiKey:String) {
            this.baseUrl = baseUrl;
            this.apiKey = apiKey;
            super(n,map,s);
        }

        public function closeBug(m:Marker):void {
            var id:String = m.getTag('bug_id');
            var status:String = BUG_STATUS_FIXED;
            var comment:String = "no comment";
            var nickname:String = "NoName";

            //TODO make this a post request
            var loader:URLLoader = new URLLoader();
            loader.load(new URLRequest(baseUrl+"changeBugStatus?&id="+id+"&status="+status+"&comment="+comment+"&nickname="+nickname+"&key="+apiKey));
            loader.addEventListener(Event.COMPLETE, bugClosed);
        }

        private function bugClosed(event:Event):void {
            trace("bug closed");
            // remove it from the layer, redraw, fix selection etc.
        }
    }
}
