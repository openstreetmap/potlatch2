package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.potlatch2.utils.SnapshotConnection;

    public class SnapshotLoader {

        private var map:Map;
        private var _layer:MapPaint;
        private static const STYLESHEET:String="stylesheets/snapshot.css";
        private var connection:SnapshotConnection;
        private var _stylesheet:String;


        public function SnapshotLoader(map:Map, url:String, name:String, stylesheet:String = null):void {
            trace("*"+stylesheet+"*")
            this.map = map;
            connection = new SnapshotConnection(name, url, '');
            _stylesheet = (stylesheet && stylesheet != '') ? stylesheet : STYLESHEET;
        }

        public function load():void {
            if (!_layer) {
                _layer = map.addLayer(connection, _stylesheet, true, true);
            }
            connection.loadBbox(map.edge_l, map.edge_r, map.edge_t, map.edge_b);
        }
    }
}