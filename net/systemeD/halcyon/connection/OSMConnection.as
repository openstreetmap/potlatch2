package net.systemeD.halcyon.connection {

    import flash.events.*;
	import flash.net.*;
	import flash.utils.Dictionary;
	import flash.system.Security;

	import net.systemeD.halcyon.ExtendedURLLoader;
	import net.systemeD.halcyon.Globals;

    /**
    * Read-only connection from local OSM-XML format (.osm) files.
    * This is used by Halcyon; Potlatch 2 needs a full server connection
    * of the type provided by XMLConnection
    */

	// For a limited set of arbitrary files, invoke it like this:
	//		fo.addVariable("api","http://127.0.0.1/~richard/potlatch2");		// base URL
	//		fo.addVariable("connection","OSM");
	//		fo.addVariable("files","-1.5_-1.4_52.1_52.2.osm");

	// For evenly arranged tiles, invoke it like this:
	//		fo.addVariable("api","http://127.0.0.1/~richard/potlatch2");		// base URL
	//		fo.addVariable("connection","OSM");
	//		fo.addVariable("tile_resolution","0.2");
	// and it'll then look for '-1.4_-1.2_52_52.2.osm', '-1.2_-1_52_52.2.osm', and so on
	// (this needs some more testing)

	public class OSMConnection extends XMLBaseConnection {

		private var filemode:uint;
		private static const NAMED:uint=0;
		private static const TILED:uint=1;
		// are we running from a limited set of files, or can we request tiles for any bbox?

		private var bboxes:Dictionary=new Dictionary();
		private static const AVAILABLE:uint=0;
		private static const LOADED:uint=1;
		private static const LOADING:uint=2;
		private static const UNAVAILABLE:uint=3;
		// a hash of known files [left,right,top,bottom], and their current status

		private var tileResolution:Number;
		// degree resolution for tiles (e.g. 0.2)

		private static const FILENAME:RegExp=/([\-\d\.]+)_([\-\d\.]+)_([\-\d\.]+)_([\-\d\.]+)\./i;

		public function OSMConnection() {

			if (Connection.policyURL!='')
                Security.loadPolicyFile(Connection.policyURL);

            tileResolution = Number(Connection.getParam("tile_resolution", "0.2"));

			var o:Object = new Object();
			var files:String = Connection.getParam("files","");
			if (files=="") {
				filemode=TILED;
			} else {
				filemode=NAMED;
				for each (var file:String in files.split(/,/)) {
					if ((o=FILENAME.exec(file))) {
						bboxes[[o[1],o[2],o[3],o[4]]]=AVAILABLE;
					}
				}
			}
		}
		
		override public function loadBbox(left:Number,right:Number,
								top:Number,bottom:Number):void {
			var l:Number, r:Number, t:Number, b:Number, x:Number, y:Number, k:Array;

			// look through bboxes, assemble any within the requested bbox that are AVAILABLE
			for (var box:* in bboxes) {
				k=box as Array;
				l=k[0]; r=k[1]; t=k[2]; b=k[3];
				if ( ( (left>=l && left<=r) || (right>=l && right<=r) || (left<l && right>r) ) &&
					 ( (top>=b && top<=t) || (bottom>=b && bottom<=t) || (bottom<b && top>t) ) ) {
					// yay, it intersects
					if (bboxes[box]==AVAILABLE) { loadFile(box); }
				}
			}
			if (filemode==NAMED) { return; }
			
			// look through tiles for any areas that are not covered
			for (x=roundDown(left, tileResolution); x<=roundUp(right, tileResolution); x+=tileResolution) {
				for (y=roundDown(bottom, tileResolution); y<=roundUp(top, tileResolution); y+=tileResolution) {
					k=[x,x+tileResolution,y,y+tileResolution];
					if (bboxes[k]) { 
						if (bboxes[k]==AVAILABLE) { loadFile(k); }
					} else {
						loadFile(k);
					}
				}
			}
		}
		
		private function loadFile(box:Array):void {
			Globals.vars.root.addDebug("called loadFile for "+box);
			bboxes[box]=LOADING;

            var mapRequest:URLRequest = new URLRequest(Connection.apiBaseURL+"/"+box[0]+"_"+box[1]+"_"+box[2]+"_"+box[3]+".osm");
			var mapLoader:ExtendedURLLoader = new ExtendedURLLoader();
			mapLoader.info['bbox']=box;
			mapLoader.addEventListener(Event.COMPLETE, markMapLoaded);
			mapLoader.addEventListener(IOErrorEvent.IO_ERROR, markMapUnloadable);
			mapLoader.load(mapRequest);
			dispatchEvent(new Event(LOAD_STARTED));
		}
		
		private function markMapLoaded(e:Event):void {
			bboxes[e.target.info['bbox']]=LOADED;
			loadedMap(e);
		}
		
		private function markMapUnloadable(e:Event):void {
			bboxes[e.target.info['bbox']]=UNAVAILABLE;
		}

		override public function purgeOutside(left:Number, right:Number, top:Number, bottom:Number):void {
			// we don't purge in an OSMConnection
		}

		private function roundUp(a:Number,i:Number):Number {
			if (a/i==Math.floor(a/i)) { return a/i; }
			return Math.floor(a/i+1)*i;
		}
		private function roundDown(a:Number,i:Number):Number {
			return Math.floor(a/i)*i;
		}

	}
}
