package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.halcyon.connection.Connection;
    import net.systemeD.halcyon.connection.Marker;
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
        private var _layer:MapPaint;
        private var connection:Connection;
        private static const STYLESHEET:String="stylesheets/bikeshops.css";

        public function BikeShopLoader(map:Map, url:String, name:String) {
            this.map = map;
            this.bikeShopBaseURL = url;
            this.name = name;
            this.connection = new BikeShopConnection(name,url,bikeShopBaseURL+"crossdomain.xml",null);
            _layer = map.addLayer(connection, STYLESHEET);
            _layer.visible = false;
        }

        public function load():void {
            _layer.visible = true;
            connection.loadBbox(map.edge_l, map.edge_r, map.edge_t, map.edge_b);
        }
    }
}