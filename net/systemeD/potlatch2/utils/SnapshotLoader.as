package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.potlatch2.utils.SnapshotConnection;

    public class SnapshotLoader {

        private var map:Map;
        private var _layer:MapPaint;
        private static const STYLESHEET:String="stylesheets/snapshot.css"; //TODO take from xml
        private var connection:SnapshotConnection;


        public function SnapshotLoader(map:Map, url:String, name:String):void {
            this.map = map;
            connection = new SnapshotConnection(name, url, '');
        }

        public function load():void {
            if (!_layer) {
                _layer = map.addLayer(connection, STYLESHEET);
            }
            connection.loadBbox(map.edge_l, map.edge_r, map.edge_t, map.edge_b);
        }
    }
}