package net.systemeD.potlatch2.utils {

	import org.vanrijkom.shp.*;
	import org.vanrijkom.dbf.*;
	import com.gradoservice.proj4as.*;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.Connection;
	import net.systemeD.halcyon.connection.Node;
	import net.systemeD.halcyon.connection.Way;
	import net.systemeD.potlatch2.tools.Simplify;
	import flash.utils.ByteArray;

	public class ShpImporter extends Importer {

		private var projection:String;

		public function ShpImporter(connection:Connection, map:Map, callback:Function=null, simplify:Boolean=false, options:Object=null) {
			if (options[projection]) this.projection=options[projection];
			super(connection,map,callback,simplify,options);
		}

		override protected function doImport(push:Function): void {
			// we load .shp as files[0], .shx as files[1], .dbf as files[2]
			var shpFile:ByteArray=getFileByName(/.shp$/);
			var dbfFile:ByteArray=getFileByName(/.dbf$/);
			var shp:ShpHeader=new ShpHeader(shpFile);
			var dbf:DbfHeader=new DbfHeader(dbfFile);

			if (projection) {
				var proj:Proj4as=new Proj4as();
				var toProj:ProjProjection=new ProjProjection('EPSG:4326');
				var fromProj:ProjProjection=new ProjProjection('EPSG:27700');
			}

			var nodemap:Object={};
			var key:String, v:String;

			if (shp.shapeType==ShpType.SHAPE_POLYGON || shp.shapeType==ShpType.SHAPE_POLYLINE) {

				// Loop through all polylines in the shape
				var polyArray:Array = ShpTools.readRecords(shpFile);
				for (var i:uint=0; i<polyArray.length; i++) {

					// Get attributes and create a tags hash
					// (note that dr.values is a Dictionary)
					var dr:DbfRecord = DbfTools.getRecord(dbfFile, dbf, i);
					var tags:Object={};
					for (key in dr.values) {
						v=dr.values[key];
						while (v.substr(v.length-1,1)==" ") v=v.substr(0,v.length-1);
						while (v.substr(0,1)==" ") v=v.substr(1);
						if (v!='') tags[key.toLowerCase()]=v;
					}

					// Do each ring in turn, then each point in the ring
					var way:Way;
					var node:Node;
					var x:Number, y:Number;
					for (var j:int=0; j < polyArray[i].shape.rings.length; j++) {
						var nodestring:Array=[];
						var points:Array = polyArray[i].shape.rings[j];
						if (points!=null) {
							for (var k:int=0; k < points.length; k++) {
								var p:ShpPoint = ShpPoint(points[k]);
								
								if (projection) {
									var r:ProjPoint = new ProjPoint(p.x,p.y,0);
									r=proj.transform(fromProj,toProj,r);
									x=r.x; y=r.y;
								} else {
									x=p.x; y=p.y;
								}

								key=x+","+y;
								if (nodemap[key]) { node=nodemap[key]; }
								else { node=connection.createNode({}, y, x, push); nodemap[key]=node; }
								nodestring.push(node);
							}
						}
						if (nodestring.length>0) {
							way=connection.createWay(tags, nodestring, push);
							if (simplify) { Simplify.simplify(way, map, false); }
						}
					}
				}
			}
		}

	}
}
