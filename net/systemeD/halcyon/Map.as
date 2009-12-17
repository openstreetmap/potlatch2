package net.systemeD.halcyon {

	import flash.text.TextField;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.text.Font;
	import flash.utils.ByteArray;
	import flash.events.*;
	import flash.net.*;

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.halcyon.connection.EntityEvent;
	import net.systemeD.halcyon.styleparser.*;
	import net.systemeD.halcyon.Globals;
	
//	for experimental export function:
//	import flash.net.FileReference;
//	import com.adobe.images.JPGEncoder;

    public class Map extends Sprite {

		public const MASTERSCALE:Number=5825.4222222222;// master map scale - how many Flash pixels in 1 degree longitude
														// (for Landsat, 5120)
		public const MINSCALE:uint=13;					// don't zoom out past this
		public const MAXSCALE:uint=19;					// don't zoom in past this

		public var ruleset:RuleSet;						// rules
		
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
		public var centre_lat:Number;					// centre lat/lon
		public var centre_lon:Number;					//  |

		public var baselon:Number;						// urllon-xradius/masterscale;
		public var basey:Number;						// lat2lat2p(urllat)+yradius/masterscale;
		public var mapwidth:uint;						// width (Flash pixels)
		public var mapheight:uint;						// height (Flash pixels)

		public var dragstate:uint=NOT_DRAGGING;			// dragging map
		private var lastxmouse:Number;					//  |
		private var lastymouse:Number;					//  |
		private var downX:Number;						//  |
		private var downY:Number;						//  |
		public const NOT_DRAGGING:uint=0;				//  |
		public const NOT_MOVED:uint=1;					//  |
		public const DRAGGING:uint=2;					//  |
		
		public var initparams:Object;					// object containing 

		public var backdrop:Object;						// reference to backdrop sprite
		public var tileset:TileSet;						// 900913 tile background
		public var showall:Boolean=true;				// show all objects, even if unstyled?
		
		public var connection:Connection;				// server connection

		public const TILESPRITE:uint=0;
		public const GPSSPRITE:uint=1;
		public const WAYSPRITE:uint=2;
		public const NAMESPRITE:uint=13;
		
		// ------------------------------------------------------------------------------------------
		// Map constructor function

        public function Map(initparams:Object) {
			this.initparams=initparams;
			connection = Connection.getConnection(initparams);
            connection.addEventListener(Connection.NEW_WAY, newWayCreated);
            connection.addEventListener(Connection.NEW_POI, newPOICreated);
			gotEnvironment(null);

			addEventListener(Event.ENTER_FRAME, everyFrame);
        }

		// Set up layering
		// [layer][3]			- names
		// [layer][2][sublayer]	- stroke
		// [layer][1]			- casing
		// [layer][0]			- fill

		private function createSprites():void {
			tileset=new TileSet(this);					// 0 - 900913 background
			addChild(tileset);							//      |
			addChild(new Sprite());						// 1 - GPS

			for (var l:int=0; l<13; l++) {				// 11 layers (12 is +5, 2 is -5)
				var s:Sprite = getHitSprite();      	//  |
				s.addChild(getPaintSprite());			//	| 0 fill
				s.addChild(getPaintSprite());			//	| 1 casing
				var t:Sprite = getPaintSprite();		//  | 2 stroke
				for (var j:int=0; j<11; j++) {			//	|  | ten sublayers
					t.addChild(getPaintSprite());		//  |  |  |
				}										//  |  |  |
				s.addChild(t);							//  |  |
				s.addChild(getPaintSprite());			//	| 3 names
				s.addChild(getPaintSprite());			//	| 4 nodes
				s.addChild(getHitSprite());			    //	| 5 entity hit tests
				addChild(s);							//  |
			}
			addChild(getPaintSprite());     			// 13 - name sprite
		}
		
		private function removeSprites():void {
			while (numChildren) { removeChildAt(0); }
		}

        private function getPaintSprite():Sprite {
            var s:Sprite = new Sprite();
            s.mouseEnabled = false;
            s.mouseChildren = false;
            return s;
        }

        private function getHitSprite():Sprite {
            var s:Sprite = new Sprite();
            return s;
        }

		public function gotEnvironment(r:Object):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, gotFont);
			loader.load(new URLRequest("FontLibrary.swf"));
		}
		
		public function gotFont(r:Event):void {
			var FontLibrary:Class = r.target.applicationDomain.getDefinition("FontLibrary") as Class;
			Font.registerFont(FontLibrary.DejaVu);

			if (initparams['lat'] != null) {
				// parameters sent from HTML
				init(initparams['lat'],
					 initparams['lon'],
					 initparams['zoom'],
					 initparams['style'],
					 initparams['tileurl']);

			} else {
				// somewhere innocuous
				init(53.09465,-2.56495,17,"test.css?d="+Math.random(),"");
			}
		}

		// ------------------------------------------------------------------------------------------
		// Initialise map at a given lat/lon

        public function init(startlat:Number,startlon:Number,startscale:uint=0,style:String=null,tileurl:String=''):void {
			removeSprites();
			createSprites();
			tileset.init(tileurl);

			if (style) {
				ruleset=new RuleSet(this,redrawPOIs);
				ruleset.loadFromCSS(style);
			}
			if (startscale>0) { scale=startscale; }

			scalefactor=MASTERSCALE/Math.pow(2,13-scale);
			baselon    =startlon          -(mapwidth /2)/scalefactor;
			basey      =lat2latp(startlat)+(mapheight/2)/scalefactor;
			addDebug("Baselon "+baselon+", basey "+basey);
			updateCoords(0,0);
			download();
			
        }

		// ------------------------------------------------------------------------------------------
		// Recalculate co-ordinates from new Flash origin

		public function updateCoords(tx:Number,ty:Number):void {
			x=tx; y=ty;

			edge_t=coord2lat(-y          );
			edge_b=coord2lat(-y+mapheight);
			edge_l=coord2lon(-x          );
			edge_r=coord2lon(-x+mapwidth );
			setCentre();
//			addDebug("Lon "+edge_l+"-"+edge_r);
//			addDebug("Lat "+edge_b+"-"+edge_t);

			tileset.update();
		}
		
		public function updateCoordsFromLatLon(lat:Number,lon:Number):void {
			var cy:Number=-(lat2coord(lat)-mapheight/2);
			var cx:Number=-(lon2coord(lon)-mapwidth/2);
			updateCoords(cx,cy);
		}
		
		private function setCentre():void {
			centre_lat=coord2lat(-y+mapheight/2);
			centre_lon=coord2lon(-x+mapwidth/2);
			this.dispatchEvent(new MapEvent(MapEvent.MOVE, {lat:centre_lat, lon:centre_lon, scale:scale}));
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

		public function updateSize(w:uint, h:uint):void {
			this.dispatchEvent(new MapEvent(MapEvent.RESIZE, {width:w, height:h}));
			
			mapwidth = w;
			mapheight= h;
            if ( backdrop != null ) {
                backdrop.width=mapwidth;
                backdrop.height=mapheight;
            }
            if ( mask != null ) {
                mask.width=mapwidth;
                mask.height=mapheight;
            }
		}

		// ------------------------------------------------------------------------------------------
		// Download map data
		// (typically from whichways, but will want to add more connections)

		public function download():void {
			this.dispatchEvent(new MapEvent(MapEvent.DOWNLOAD, {minlon:edge_l, maxlon:edge_r, maxlat:edge_t, minlat:edge_b} ));
			
			if (edge_l>=bigedge_l && edge_r<=bigedge_r &&
				edge_b>=bigedge_b && edge_t<=bigedge_t) { return; } 	// we have already loaded this area, so ignore
			bigedge_l=edge_l; bigedge_r=edge_r;
			bigedge_b=edge_b; bigedge_t=edge_t;
			addDebug("Calling download with "+edge_l+"-"+edge_r+", "+edge_t+"-"+edge_b);
			connection.loadBbox(edge_l,edge_r,edge_t,edge_b);
		}



        private function newWayCreated(event:EntityEvent):void {
            var way:Way = event.entity as Way;
			if (!way.loaded) { return; }
            ways[way.id] = new WayUI(way, this);
        }

        private function newPOICreated(event:EntityEvent):void {
            var node:Node = event.entity as Node;
            pois[node.id] = new NodeUI(node, this);
			pois[node.id].redraw();
        }

        public function setHighlight(entity:Entity, settings:Object):void {
			var stateType:String;
			var ui:EntityUI=null;
			if      ( entity is Way  ) { ui = ways[entity.id]; }
			else if ( entity is Node ) { ui = pois[entity.id]; }
			if (ui==null) { return; }
			for (stateType in settings) {
				ui.setHighlight(stateType, settings[stateType]);
			}
			ui.redraw();
        }

        // Handle mouse events on ways/nodes
        private var mapController:MapController = null;

        public function setController(controller:MapController):void {
            this.mapController = controller;
        }

        public function entityMouseEvent(event:MouseEvent, entity:Entity):void {
            if ( mapController != null )
                mapController.entityMouseEvent(event, entity);
				
        }

		// ------------------------------------------------------------------------------------------
		// Redraw all items, zoom in and out
		
		public function redraw():void {
			for each (var w:WayUI in ways) { w.recalculate(); w.redraw(); }
			for each (var p:NodeUI in pois) { p.redraw(); }
		}

		public function redrawPOIs():void {
			for each (var p:NodeUI in pois) { p.redraw(); }
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
			scalefactor=MASTERSCALE/Math.pow(2,13-scale);
			updateCoordsFromLatLon((edge_t+edge_b)/2,(edge_l+edge_r)/2);	// recentre
			tileset.changeScale(scale);
			download();
			redraw();
		}

		private function reportPosition():void {
			addDebug("lon "+coord2lon(mouseX)+", lat "+coord2lat(mouseY));
		}

		// ------------------------------------------------------------------------------------------
		// Export (experimental)
		// ** just a bit of fun for now!
		// really needs to take a bbox, and make sure that the image is correctly cropped/resized 
		// to that area (will probably require creating a new DisplayObject with a different origin
		// and mask)
/*		
		public function export():void {
			addDebug("size is "+this.width+","+this.height);
			var jpgSource:BitmapData = new BitmapData(800,800); // (this.width, this.height);
			jpgSource.draw(this);
			var jpgEncoder:JPGEncoder = new JPGEncoder(85);
			var jpgStream:ByteArray = jpgEncoder.encode(jpgSource);
			var fileRef:FileReference = new FileReference();
//			fileRef.save(jpgStream,'map.jpeg');
		}

*/

		// ==========================================================================================
		// Events
		
		// ------------------------------------------------------------------------------------------
		// Mouse events
		
		public function mouseDownHandler(event:MouseEvent):void {
			dragstate=NOT_MOVED;
			lastxmouse=downX=mouseX;
			lastymouse=downY=mouseY;
		}
        
		public function mouseUpHandler(event:MouseEvent):void {
			if (dragstate==DRAGGING) {
				updateCoords(x,y);
				download();
			}
			dragstate=NOT_DRAGGING;
		}
        
		public function mouseMoveHandler(event:MouseEvent):void {
			if (dragstate==NOT_DRAGGING) {
				return;
			}
			
			if (dragstate==NOT_MOVED && Math.abs(downX - mouseX) < 3 && Math.abs(downY - mouseY) < 3) {
				return;
			}
			
			dragstate=DRAGGING;
			x+=mouseX-lastxmouse;
			y+=mouseY-lastymouse;
			lastxmouse=mouseX; lastymouse=mouseY;
			setCentre();
		}
        
		// ------------------------------------------------------------------------------------------
		// Do every frame

		private function everyFrame(event:Event):void {
			if (tileset) { tileset.serviceQueue(); }
		}

		// ------------------------------------------------------------------------------------------
		// Miscellaneous events
		
		public function keyUpHandler(event:KeyboardEvent):void {
// addDebug("pressed "+event.keyCode);
            if ( !event.ctrlKey ) return;
			if (event.keyCode==82) { this.redraw(); }			// R - redraw
			if (event.keyCode==73) { this.zoomIn(); }			// I - zoom in
			if (event.keyCode==79) { this.zoomOut(); } 			// O - zoom out
			if (event.keyCode==76) { this.reportPosition(); }	// L - report lat/long
//			if (event.keyCode==69) { this.export(); }			// E - export
		}

		public function connectionError(err:Object=null): void {
			addDebug("got error"); 
		}

		// ------------------------------------------------------------------------------------------
		// Debugging
		
		public function addDebug(text:String):void {
			if (!Globals.vars.hasOwnProperty('debug')) return;
			if (!Globals.vars.debug.visible) return;
			Globals.vars.debug.appendText(text+"\n");
			Globals.vars.debug.scrollV=Globals.vars.debug.maxScrollV;
		}
		
	}
}
