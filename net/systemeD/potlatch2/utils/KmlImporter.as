package net.systemeD.potlatch2.utils {

    import net.systemeD.halcyon.Map;
    import net.systemeD.halcyon.connection.Connection;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.Way;
    import net.systemeD.halcyon.connection.Relation;
    import net.systemeD.halcyon.connection.RelationMember;
    import net.systemeD.potlatch2.tools.Simplify;

    /**
     * Implements parsing and loading of KML files.
     */
    public class KmlImporter extends Importer {

        public function KmlImporter(connection:Connection, map:Map, callback:Function=null, simplify:Boolean=false, options:Object=null) {
            super(connection, map, callback, simplify, options);
        }

        override protected function doImport(push:Function): void {
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
                    tags["name"] = placemark.name.substr(0,255);
                }

                if (placemark.description.length() > 0) {
                    tags["description"] = placemark.description.substr(0,255);
                }

                for each (var point:XML in placemark.Point) {
                    importNode(point.coordinates, tags, push);
                }

                for each (var linestring:XML in placemark.LineString) {
                    importWay(linestring.coordinates, tags, false, push);
                }

                for each (var linearring:XML in placemark.LinearRing) {
                    importWay(linearring.coordinates, tags, true, push);
                }

                for each (var polygon:XML in placemark.Polygon) {
                    if (polygon.innerBoundaryIs.length() > 0) {
                        var members:Array = [];
                        var way:Way;

                        way = importWay(polygon.outerBoundaryIs.LinearRing.coordinates, {}, true, push);
                        members.push(new RelationMember(way, "outer"));

                        for each (var inner:XML in polygon.innerBoundaryIs) {
                            way = importWay(inner.LinearRing.coordinates, {}, true, push);
                            members.push(new RelationMember(way, "inner"));
                        }

                        tags["type"] = "multipolygon";

                        connection.createRelation(tags, members, push);
                    } else {
                        importWay(polygon.outerBoundaryIs.LinearRing.coordinates, tags, true, push);
                    }
                }
            }
			default xml namespace = new Namespace("");
        }

        private function importNode(coordinates:String, tags:Object, push:Function): Node {
            var coords:Array = coordinates.split(",");
            var lon:Number = coords[0];
            var lat:Number = coords[1];
            //var ele:Number = coords[2];

            var node:Node = connection.createNode(tags, lat, lon, push);

            connection.registerPOI(node);

            return node;
        }

        private function importWay(coordinates:String, tags:Object, polygon:Boolean, push:Function): Way {
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

                nodestring.push(connection.createNode({}, lat, lon, push));
            }

            if (polygon) {
                nodestring.push(nodestring[0]);
            }

            if (nodestring.length > 0) {
                way = connection.createWay(tags, nodestring, push);
                if (simplify) { Simplify.simplify(way, map, false); }
            }

            return way;
        }
    }
}
