package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.MapPaint;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.Way;
    import net.systemeD.halcyon.connection.Relation;
    import net.systemeD.halcyon.connection.RelationMember;
    import net.systemeD.potlatch2.tools.Simplify;

    /**
     * Implements parsing and loading of KML files.
     */
    public class KmlImporter extends Importer {

        public function KmlImporter(container:*, paint:MapPaint, filenames:Array, callback:Function=null, simplify:Boolean=false) {
            super(container, paint, filenames, callback, simplify);
        }

        override protected function doImport(): void {
            var kml:XML = new XML(files[0]);

            for each (var ns:Namespace in kml.namespaceDeclarations()) {
                if
                (ns.uri.match(/^http:\/\/earth\.google\.com\/kml\/[0-9]+\.[0-9]+$/) ||
                 ns.uri.match(/^http:\/\/www\.opengis\.net\/kml\/[0-9]+\.[0-9]+$/)) {
                    default xml namespace = ns;
                }
            }

            for each (var placemark:XML in kml..Placemark) {
                var tags:Object = {};

                if (placemark.name.length() > 0) {
                    tags["name"] = placemark.name;
                }

                if (placemark.description.length() > 0) {
                    tags["description"] = placemark.description;
                }

                for each (var point:XML in placemark.Point) {
                    importNode(point.coordinates, tags);
                }

                for each (var linestring:XML in placemark.LineString) {
                    importWay(linestring.coordinates, tags, false);
                }

                for each (var linearring:XML in placemark.LinearRing) {
                    importWay(linearring.coordinates, tags, true);
                }

                for each (var polygon:XML in placemark.Polygon) {
                    if (polygon.innerBoundaryIs.length() > 0) {
                        var members:Array = [];
                        var way:Way;

                        way = importWay(polygon.outerBoundaryIs.LinearRing.coordinates, {}, true);
                        members.push(new RelationMember(way, "outer"));

                        for each (var inner:XML in polygon.innerBoundaryIs) {
                            way = importWay(inner.LinearRing.coordinates, {}, true);
                            members.push(new RelationMember(way, "inner"));
                        }

                        tags["type"] = "multipolygon";

                        container.createRelation(tags, members);
                    } else {
                        importWay(polygon.outerBoundaryIs.LinearRing.coordinates, tags, true);
                    }
                }
            }
			default xml namespace = new Namespace("");
        }

        private function importNode(coordinates:String, tags:Object): Node {
            var coords:Array = coordinates.split(",");
            var lon:Number = coords[0];
            var lat:Number = coords[1];
            //var ele:Number = coords[2];

            var node:Node = container.createNode(tags, lat, lon);

            container.registerPOI(node);

            return node;
        }

        private function importWay(coordinates:String, tags:Object, polygon:Boolean): Way {
            var way:Way;
            var nodestring:Array = [];

            if (polygon) {
                coordinates = coordinates.slice(0, coordinates.lastIndexOf(" "));
            }

            for each (var tuple:String in coordinates.split(" ")) {
                var coords:Array = tuple.split(",");
                var lon:Number = coords[0];
                var lat:Number = coords[1];
                //var ele:Number = coords[2];

                nodestring.push(container.createNode({}, lat, lon));
            }

            if (polygon) {
                nodestring.push(nodestring[0]);
            }

            if (nodestring.length > 0) {
                way = container.createWay(tags, nodestring);
                if (simplify) { Simplify.simplify(way, paint.map, false); }
            }

            return way;
        }
    }
}
