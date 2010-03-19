package net.systemeD.potlatch2.utils {

	import org.vanrijkom.shp.*;
	import org.vanrijkom.dbf.*;
	import net.systemeD.halcyon.MapPaint;
	import net.systemeD.halcyon.Globals;
	import net.systemeD.halcyon.connection.Node;

	public class ShpImporter extends Importer {

		public function ShpImporter(container:*, paint:MapPaint, filenames:Array) {
			super(container,paint,filenames);
		}

		override protected function doImport(): void {
			// we load .shp as files[0], .shx as files[1], .dbf as files[2]
			var shp:ShpHeader=new ShpHeader(files[0]);
			var dbf:DbfHeader=new DbfHeader(files[2]);

			if (shp.shapeType==ShpType.SHAPE_POLYGON || shp.shapeType==ShpType.SHAPE_POLYLINE) {

				// Loop through all polylines in the shape
				var polyArray:Array = ShpTools.readRecords(files[0]);
				for (var i:uint=0; i<polyArray.length; i++) {

					// Get attributes like this:
					//		var dr:DbfRecord = DbfTools.getRecord(files[2], dbf, i);
					//		var xsID:String = dr.values[idFieldName];

					// Do each ring in turn, then each point in the ring
					for (var j:int=0; j < polyArray[i].shape.rings.length; j++) {
						var nodestring:Array=[];
						var points:Array = polyArray[i].shape.rings[j];
						if (points!=null) {
							for (var k:int=0; k < points.length; k++) {
								var p:ShpPoint = ShpPoint(points[k]);
								nodestring.push(container.createNode({}, p.y, p.x));
							}
						}
						if (nodestring.length>0) {
							paint.createWayUI(container.createWay({}, nodestring));
						}
					}
				}
			}
		}

	}
}
