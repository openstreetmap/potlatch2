package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.VectorLayer;
    import net.systemeD.halcyon.connection.Marker;
    import net.systemeD.potlatch2.BugLayer;
    import flash.net.*;
    import flash.events.*;
    import com.adobe.serialization.json.JSON;
    import flash.system.Security;

    /**
    * The BikeShopLoader loads data regarding missing bike shops in the UK from the "bike-shop-locator" project.
    * It was a quick hack undertaken during the WhereCampUK meeting in Nottingham in November 2010. It served partly
    * as a demonstration of improving QA feedback loops within the OSM universe, but mainly as an indication
    * that we need to rethink how these things are handled in P2. The amount of copy/paste coding going on is too
    * high, and we should be able to make something along the lines of "imagery.xml" to define and load generic
    * kml/geojson/georss feeds from multiple sources without having to code *Loader classes for each one.
    *
    * Oh, and it's possible to handle xml Namespaces without resorting to blanking them out of the raw data :-)
    */

    public class BikeShopLoader {

        private var map:Map;
        private var bikeShopBaseURL:String;
        private var name:String;
        private var _layer:VectorLayer;
        private static const STYLESHEET:String="bikeshops.css";

        public function BikeShopLoader(map:Map, url:String, name:String) {
            this.map = map;
            this.bikeShopBaseURL = url;
            this.name = name;
        }

        public function load():void {
            var loader:URLLoader = new URLLoader();
            loader.load(new URLRequest(bikeShopBaseURL+"shop/missing.kml?bbox="+map.edge_l+","+map.edge_b+","+map.edge_r+","+map.edge_t));
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, balls);
            loader.addEventListener(Event.COMPLETE, parseKML);
        }

        public function balls(event:SecurityErrorEvent):void {
            trace(event);
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
              var marker:Marker = layer.createMarker(tags, lat, lon);
            }
			default xml namespace = new Namespace("");
            layer.paint.updateEntityUIs(layer.getObjectsByBbox(map.edge_l,map.edge_r,map.edge_t,map.edge_b), true, false);
        }

        private function get layer():VectorLayer {
            if (!_layer) {
                var policyFile:String = bikeShopBaseURL+"crossdomain.xml";
                Security.loadPolicyFile(policyFile);

                _layer=new VectorLayer(name,map,STYLESHEET);
                map.addVectorLayer(_layer);
            }
            return _layer;
        }
    }
}