package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.potlatch2.tools.Simplify;

    /**
    * Implements parsing and loading of GPX files.
    * For loading GPX traces from the OSM API, see halcyon/connenction/Trace.as
    */
	public class GpxImporter extends Importer {

		public function GpxImporter(container:*, paint:MapPaint, filenames:Array, callback:Function=null, simplify:Boolean=false) {
			super(container,paint,filenames,callback,simplify);
		}

		override protected function doImport(): void {
			var xmlnsPattern:RegExp = new RegExp("xmlns[^\"]*\"[^\"]*\"", "gi");
			var xsiPattern:RegExp = new RegExp("xsi[^\"]*\"[^\"]*\"", "gi");
			files[0] = String(files[0]).replace(xmlnsPattern, "").replace(xsiPattern, "");
			var file:XML=new XML(files[0]);

			for each (var trk:XML in file.child("trk")) {
				for each (var trkseg:XML in trk.child("trkseg")) {
					var way:Way;
					var nodestring:Array=[];
					for each (var trkpt:XML in trkseg.child("trkpt")) {
						nodestring.push(container.createNode({}, trkpt.@lat, trkpt.@lon));
					}
					if (nodestring.length>0) {
						way=container.createWay({}, nodestring);
						if (simplify) { Simplify.simplify(way, paint.map, false); }
					}
				}
			}
			for each (var wpt:XML in file.child("wpt")) {
				var tags:Object={};
				for each (var tag:XML in wpt.children()) {
					tags[tag.name()]=tag.toString();
				}
				container.createNode(tags, wpt.@lat, wpt.@lon);
			}
		}
	}
}
