package net.systemeD.halcyon {

	import flash.text.TextField;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.*;
	import net.systemeD.halcyon.styleparser.*;
	import flash.net.*;
	
    public class Map extends Sprite {

		public const MASTERSCALE:Number=5825.4222222222;// master map scale - how many Flash pixels in 1 degree longitude
														// (for Landsat, 5120)
		public const MINSCALE:uint=13;					// don't zoom out past this
		public const MAXSCALE:uint=19;					// don't zoom in past this

		public var ruleset:RuleSet=new RuleSet();		// rules
		
		public var ways:Object=new Object();			// geodata
		public var nodes:Object=new Object();			//  |
		public var pois:Object=new Object();			//  |
		public var relations:Object=new Object();		//  |

		public var scale:uint=14;						// map scale
		public var scalefactor:Number=MASTERSCALE;		// current scaling factor for lon/latp
		public var bigedge_l:Number= 999999;			// area of largest whichways
		public var bigedge_r:Number=-999999;			//  |
		public var bigedge_b:Number= 999999;			//  |
		public var bigedge_t:Number=-999999;			//  |

		public var waycount:uint=0;						// ways:		number currently loaded
		public var waysrequested:uint=0;				// 				total number requested
		public var waysreceived:uint=0;					// 				total number received
		public var relcount:uint=0;						// relations:	number currently loaded
		public var relsrequested:uint=0;				// 				total number requested
		public var relsreceived:uint=0;					// 				total number received
		public var poicount:uint=0;						// POIs:		number currently loaded
		public var whichrequested:uint=0;				// whichways:	total number requested
		public var whichreceived:uint=0;				// 				total number received

		public var edge_l:Number;						// current bounding box
		public var edge_r:Number;						//  |
		public var edge_t:Number;						//  |
		public var edge_b:Number;						//  |

		public var baselon:Number;						// urllon-xradius/masterscale;
		public var basey:Number;						// lat2lat2p(urllat)+yradius/masterscale;
		public var mapwidth:uint;						// width (Flash pixels)
		public var mapheight:uint;						// height (Flash pixels)

		private var dragging:Boolean=false;				// dragging map?
		private var lastxmouse:Number;					//  |
		private var lastymouse:Number;					//  |
		
		public var backdrop:Object;						// reference to backdrop sprite
		
		public var connection:AMFConnection;			// server connection

		// ------------------------------------------------------------------------------------------
		// Map constructor function

        public function Map() {

			for (var l:int=0; l<11; l++) {				// 11 layers (10 is +5, 0 is -5)
				var s:Sprite=new Sprite();
				s.addChild(new Sprite());				// [layer][0]=fill, [1]=stroke, [2]=names
				s.addChild(new Sprite());
				s.addChild(new Sprite());
				addChild(s);
			}

			connection=new AMFConnection(
				"http://127.0.0.1:3000/api/0.6/amf/read",
				"http://127.0.0.1:3000/api/0.6/amf/write",
				"http://127.0.0.1:3000/api/crossdomain.xml");
			connection.getEnvironment(new Responder(gotEnvironment,connectionError));

        }

		public function gotEnvironment(r:Object):void {
			init(52.022,-1.2745);
		}

		// ------------------------------------------------------------------------------------------
		// Initialise map at a given lat/lon

        public function init(startlat:Number,startlon:Number):void {

			ruleset.load("test.yaml?d="+Math.random());
//			rules.initExample();		// initialise dummy rules

			updateSize();
			baselon  =startlon			-(mapwidth /2)/MASTERSCALE;
			basey    =lat2latp(startlat)+(mapheight/2)/MASTERSCALE;
			addDebug("Baselon "+baselon+", basey "+basey);
			updateCoords(0,0);
			download();
			
        }

		// ------------------------------------------------------------------------------------------
		// Recalculate co-ordinates from new Flash origin

		public function updateCoords(tx:Number,ty:Number):void {
			x=tx; y=ty;

			// ** calculate tile_l etc.
			edge_t=coord2lat(-y          );
			edge_b=coord2lat(-y+mapheight);
			edge_l=coord2lon(-x          );
			edge_r=coord2lon(-x+mapwidth );
			addDebug("Lon "+edge_l+"-"+edge_r);
			addDebug("Lat "+edge_b+"-"+edge_t);
		}
		
		public function updateCoordsFromLatLon(lat:Number,lon:Number):void {
			var cy:Number=-(lat2coord(lat)-mapheight/2);
			var cx:Number=-(lon2coord(lon)-mapwidth/2);
			updateCoords(cx,cy);
		}


		// Co-ordinate conversion functions

		public function latp2coord(a:Number):Number	{ return -(a-basey)*scalefactor; }
		public function coord2latp(a:Number):Number	{ return a/-scalefactor+basey; }
		public function lon2coord(a:Number):Number	{ return (a-baselon)*scalefactor; }
		public function coord2lon(a:Number):Number	{ return a/scalefactor+baselon; }

		public function latp2lat(a:Number):Number	{ return 180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2); }
		public function lat2latp(a:Number):Number	{ return 180/Math.PI * Math.log(Math.tan(Math.PI/4+a*(Math.PI/180)/2)); }

		public function lat2coord(a:Number):Number	{ return -(lat2latp(a)-basey)*scalefactor; }
		public function coord2lat(a:Number):Number	{ return latp2lat(a/-scalefactor+basey); }

//		public function centrelat(o) { return coord2lat((yradius-_root.map._y-o)/Math.pow(2,_root.scale-13)); }
//		public function centrelon(o) { return coord2lon((xradius-_root.map._x-o)/Math.pow(2,_root.scale-13)); }


		// ------------------------------------------------------------------------------------------
		// Resize map size based on current stage and height

		public function updateSize():void {
			mapwidth =stage.stageWidth; mask.width=mapwidth; backdrop.width=mapwidth;
			mapheight=stage.stageHeight; mask.height=mapheight; backdrop.height=mapheight;
		}

		// ------------------------------------------------------------------------------------------
		// Download map data
		// (typically from whichways, but will want to add more connections)

		public function download():void {
			if (edge_l>=bigedge_l && edge_r<=bigedge_r &&
				edge_b>=bigedge_b && edge_t<=bigedge_t) { return; } 	// we have already loaded this area, so ignore
			bigedge_l=edge_l; bigedge_r=edge_r;
			bigedge_b=edge_b; bigedge_t=edge_t;
			addDebug("Calling with "+edge_l+"-"+edge_r+", "+edge_t+"-"+edge_b);
			connection.getBbox(edge_l,edge_r,edge_t,edge_b,new Responder(gotBbox,connectionError));
		}

		public function gotBbox(r:Object):void {
			addDebug("got whichways");
			var code:uint         =r.shift(); if (code) { connectionError(); return; }
			var message:String    =r.shift();
			var waylist:Array     =r[0];
			var pointlist:Array   =r[1];
			var relationlist:Array=r[2];
			var i:uint, v:uint;

			for each (var w:Array in waylist) {
				i=w[0]; v=w[1];
				if (ways[i] && ways[i].version==v) { continue; }
				ways[i]=new Way(i,v,this);
				ways[i].load(connection);
			}

			for each (var p:Array in pointlist) {
				i=w[0]; v=w[4];
				if (pois[i] && pois[i].version==v) { continue; }
				pois[i]=new POI(i,v,w[1],w[2],w[3],this);
			}

			addDebug("waylist is "+waylist);
		}


		// ------------------------------------------------------------------------------------------
		// Redraw all items, zoom in and out
		
		public function redraw():void {
			addDebug("redrawing");
			var s:String='';
			for each (var w:Way in ways) { w.redraw(); s+=w.id+","; }
			addDebug(s);
			// ** do POIs, etc.
		}

		public function zoomIn():void {
			if (scale==MAXSCALE) { return; }
			changeScale(scale+1);
		}

		public function zoomOut():void {
			if (scale==MINSCALE) { return; }
			changeScale(scale-1);
		}

		private function changeScale(newscale:uint):void {
			addDebug("new scale "+newscale);
			scale=newscale;
			scalefactor=MASTERSCALE/Math.pow(2,14-scale);
			updateCoordsFromLatLon((edge_t+edge_b)/2,(edge_l+edge_r)/2);	// recentre
			download();
			redraw();
		}

		private function reportPosition():void {
			addDebug("lon "+coord2lon(mouseX)+", lat "+coord2lat(mouseY));
		}


		// ==========================================================================================
		// Events
		
		// ------------------------------------------------------------------------------------------
		// Mouse events
		
		public function mouseDownHandler(event:MouseEvent):void {
			dragging=true;
			lastxmouse=mouseX; lastymouse=mouseY;
		}
        
		public function mouseUpHandler(event:MouseEvent):void {
			if (!dragging) { return; }
			dragging=false;
			updateCoords(x,y);
			download();
		}
        
		public function mouseMoveHandler(event:MouseEvent):void {
			if (!dragging) { return; }
			x+=mouseX-lastxmouse;
			y+=mouseY-lastymouse;
			lastxmouse=mouseX; lastymouse=mouseY;
		}
        
		// ------------------------------------------------------------------------------------------
		// Miscellaneous events
		
		public function keyUpHandler(event:KeyboardEvent):void {
addDebug("pressed "+event.keyCode);
			if (event.keyCode==82) { this.redraw(); }			// R - redraw
			if (event.keyCode==73) { this.zoomIn(); }			// I - zoom in
			if (event.keyCode==79) { this.zoomOut(); } 			// O - zoom out
			if (event.keyCode==76) { this.reportPosition(); }	// L - report lat/long
		}

		public function connectionError(err:Object=null): void {
			addDebug("got error"); 
		}

		// ------------------------------------------------------------------------------------------
		// Debugging
		
		public function addDebug(text:String):void {
			Globals.vars.debug.appendText(text+"\n");
			Globals.vars.debug.scrollV=Globals.vars.debug.maxScrollV;
		}
		
	}
}
