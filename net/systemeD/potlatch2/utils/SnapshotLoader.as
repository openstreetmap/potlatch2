package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.potlatch2.utils.SnapshotConnection;

    /**
    * Loads a Snapshot layer. Uses lazy-loading such that only when the load() function is
    * called will the layer be created and added to the map
    *
    * @see SnapShotConnection
    */
    public class SnapshotLoader {

        private var map:Map;
        private var _layer:MapPaint;
        private static const STYLESHEET:String="stylesheets/snapshot.css";
        private var connection:SnapshotConnection;
        private var _stylesheet:String;

        /**
        * Create a new SnapshotLoader
        * @param map The map object to attach the layer to
        * @param url The url of the snapshot server. This should be to the api base and
                     end in a forward slash, e.g. http://example.com/snapshot/api/
        * @param name The name to give to the layer/connection
        * @param stylesheet The url of the stylesheet to use for styling the layer
        */
        public function SnapshotLoader(map:Map, url:String, name:String, stylesheet:String = null):void {
            this.map = map;
            connection = new SnapshotConnection(name, url, '');
            _stylesheet = (stylesheet && stylesheet != '') ? stylesheet : STYLESHEET;
            _layer = map.addLayer(connection, _stylesheet, true, true);
            _layer.visible = false;
        }

        /**
        * Load the layer.
        * Call this the first time you wish to load the layer. After this it will respond
        * automatically to pan / zooming of the associated Map
        */
        public function load():void {
            _layer.visible = true;
            connection.loadBbox(map.edge_l, map.edge_r, map.edge_t, map.edge_b);
        }
    }
}