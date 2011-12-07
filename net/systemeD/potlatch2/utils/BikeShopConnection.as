package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.connection.Connection;
    import net.systemeD.halcyon.connection.Marker;
    import com.adobe.serialization.json.JSON;
    import flash.system.Security;
    import flash.net.*;
    import flash.events.*;

    public class BikeShopConnection extends Connection {

        public function BikeShopConnection(cname:String,api:String,policy:String,initparams:Object=null) {
            super(cname,api,policy,initparams);
        }

        public override function loadBbox(left:Number, right:Number, top:Number, bottom:Number):void {

            // Should be guarded against multiple calls really.
            if (policyURL != "") { Security.loadPolicyFile(policyURL); }

            var loader:URLLoader = new URLLoader();
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, balls);
            loader.addEventListener(Event.COMPLETE, parseKML);
            loader.load(new URLRequest(apiBaseURL+"shop/missing.kml?bbox="+left+","+bottom+","+right+","+top));
        }

        public function balls(event:SecurityErrorEvent):void {
        }

        private function parseKML(event:Event):void {
            //trace(event.target.data);
            default xml namespace = new Namespace("http://www.opengis.net/kml/2.2");
            var kml:XML = new XML(event.target.data);
            //trace(kml.attributes());
            //var document:XMLList = kml.Document;
            for each (var placemark:XML in kml..Placemark) {
              trace("name:"+placemark.name);
              var coords:Array = placemark..coordinates.split(",");
              var lon:Number = coords[0];
              var lat:Number = coords[1];
              //var ele:Number = coords[2];
              var tags:Object = {};
              tags["name"] = String(placemark.name);
              tags["description"] = String(placemark.description);
              var marker:Marker = createMarker(tags, lat, lon);
            }
            default xml namespace = new Namespace("");
        }
    }
}