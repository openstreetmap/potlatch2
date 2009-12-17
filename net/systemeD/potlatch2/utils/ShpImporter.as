package net.systemeD.potlatch2.utils {

	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.*;
	import org.vanrijkom.shp.*;
	import org.vanrijkom.dbf.*;

	import net.systemeD.halcyon.Globals;

	// SHP class docs and examples:
	//		http://vanrijkom.org/shp/index.html
	//		http://www.boxshapedworld.com/blog/post/Shapefiles-Actionscript-30-and-Google-Maps.aspx
	//		http://web.archive.org/web/20071119113250rn_1/vanrijkom.org/samples/fsd-mexico/srcview/
	// we load .shp as files[0], .shx as files[1], .dbf as files[2]

	// See http://www.actionscript.org/forums/showthread.php3?t=185320 for tips on avoiding time-outs with big files -
	// probably needs to be asynchronous
		
	public class ShpImporter extends Importer  {

		public function ShpImporter(map:Map, filenames:Array) {
			super(map, filenames);
		}
		
		// All data is loaded, so do the import

		override protected function doImport():void {
			Globals.vars.root.addDebug("importing");
			var shp:ShpHeader=new ShpHeader(files[0]);
			var dbf:DbfHeader=new DbfHeader(files[2]);

			if (shp.shapeType==ShpType.SHAPE_POLYGON || shp.shapeType==ShpType.SHAPE_POLYLINE) {

				// Loop through all polylines in the shape
				var polyArray:Array = ShpTools.readRecords(files[0]);
				for (var i:uint=0; i<Math.min(polyArray.length,50); i++) {

					// Get attributes like this:
					//		var dr:DbfRecord = DbfTools.getRecord(files[2], dbf, i);
					//		var xsID:String = dr.values[idFieldName];

					// Do each ring in turn, then each point in the ring
					for (var j:int=0; j < Math.min(polyArray[i].shape.rings.length,50); j++) {
						var nodes:Array=[];
						var points:Array = polyArray[i].shape.rings[j];
						if (points!=null) {
							for (var k:int=0; k < Math.min(points.length,50); k++) {
								var p:ShpPoint = ShpPoint(points[k]);
            					var node:Node = map.connection.createNode({}, p.y, p.x);
								nodes.push(node);
								Globals.vars.root.addDebug("point "+p.x+","+p.y);
							}
						}
						if (nodes.length>0) { var way:Way = map.connection.createWay({}, nodes); }
					}
				}
			}
		}
	}
}
