package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.Connection;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.potlatch2.tools.Simplify;

    /**
    * Implements parsing and loading of GPX files.
    * For loading GPX traces from the OSM API, see halcyon/connection/Trace.as
    */
	public class GpxImporter extends Importer {

		public function GpxImporter(connection:Connection, map:Map, filenames:Array, callback:Function=null, simplify:Boolean=false) {
			super(connection,map,filenames,callback,simplify);
		}

		override protected function doImport(push:Function): void {
			var file:XML = new XML(files[0]);
			for each (var ns:Namespace in file.namespaceDeclarations()) {
				if (ns.uri.match(/^http:\/\/www\.topografix\.com\/GPX\/1\/[01]$/)) {
					default xml namespace = ns;
				}
			}

			for each (var trkseg:XML in file..trkseg) {
				var way:Way;
                var nodestring:Array = [];
                for each (var trkpt:XML in trkseg.trkpt) {
					nodestring.push(connection.createNode({}, trkpt.@lat, trkpt.@lon, push));
				}
                if (nodestring.length > 0) {
					way = connection.createWay({}, nodestring, push);
					if (simplify) { Simplify.simplify(way, map, false); }
				}
			}

            for each (var wpt:XML in file.wpt) {
				var tags:Object = {};
				for each (var tag:XML in wpt.children()) {
					tags[tag.name().localName]=tag.toString();
				}
				var node:Node = connection.createNode(tags, wpt.@lat, wpt.@lon, push);
				connection.registerPOI(node);
			}

			default xml namespace = new Namespace("");
		}
	}
}
