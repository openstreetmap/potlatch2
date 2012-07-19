package net.systemeD.potlatch2.utils {

	import org.vanrijkom.shp.*;
	import org.vanrijkom.dbf.*;
	import com.gradoservice.proj4as.*;
	import net.systemeD.halcyon.Map;
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.potlatch2.tools.Simplify;
	import flash.utils.*;

	public class ShpImporter extends Importer {

		private var projection:String;
		
		private var timeout:uint;
		private var position:uint=0;

		private var polyArray:Array;
		private var shpFile:ByteArray;
		private var dbfFile:ByteArray;
		private var shp:ShpHeader;
		private var dbf:DbfHeader;
		private var proj:Proj4as;
		private var toProj:ProjProjection;
		private var fromProj:ProjProjection;

		private static var MAX_ITEMS:uint=10000;		// maximum number of shapes to process in each pass

		public function ShpImporter(connection:Connection, map:Map, callback:Function=null, simplify:Boolean=false, options:Object=null) {
			if (options['projection']) this.projection=options['projection'];
			super(connection,map,callback,simplify,options);
		}

		override protected function doImport():void {
			// we load .shp as files[0], .shx as files[1], .dbf as files[2]
			shpFile=getFileByName(/.shp$/); shp=new ShpHeader(shpFile);
			dbfFile=getFileByName(/.dbf$/); dbf=new DbfHeader(dbfFile);
			if (shp.shapeType!=ShpType.SHAPE_POLYGON && shp.shapeType!=ShpType.SHAPE_POLYLINE) { return; }

			if (projection) {
				proj=new Proj4as();
				toProj=new ProjProjection('EPSG:4326');
				fromProj=new ProjProjection('EPSG:27700');
			}

			polyArray = ShpTools.readRecords(shpFile);
			timeout=setTimeout(runProcess,50);
			trace("Begin processing");
		}
		
		private function runProcess():void {
			var nodemap:Object={};
			var key:String, v:String;
			clearTimeout(timeout);
			var action:CompositeUndoableAction = new CompositeUndoableAction("Import layer "+connection.name);

			trace("Starting at position "+position);
			for (var i:uint=position; i<Math.min(position+MAX_ITEMS,polyArray.length); i++) {
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
							else { node=connection.createNode({}, y, x, action.push); nodemap[key]=node; }
							nodestring.push(node);
						}
					}
					if (nodestring.length>0) {
						way=connection.createWay(tags, nodestring, action.push);
						if (simplify) { Simplify.simplify(way, map, false); }
					}
				}
			}

			// Set next iteration to run after a short delay
			action.doAction();
			if (i<polyArray.length) {
				position=i;
				timeout=setTimeout(runProcess,50);
			} else {
				trace("Finished");
				finish();
			}
		}
	}
}
