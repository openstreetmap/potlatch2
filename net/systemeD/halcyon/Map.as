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
		public const MAXSCALE:uint=23;					// don't zoom in past this

		public var paint:MapPaint;						// sprite for ways and (POI/tagged) nodes in core layer
		public var vectorbg:Sprite;						// sprite for vector background layers

		public var scale:uint=14;						// map scale
		public var scalefactor:Number=MASTERSCALE;		// current scaling factor for lon/latp
		public var bigedge_l:Number= 999999;			// area of largest whichways
		public var bigedge_r:Number=-999999;			//  |
		public var bigedge_b:Number= 999999;			//  |
		public var bigedge_t:Number=-999999;			//  |

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
		private var _draggable:Boolean=true;			//  |
		private var lastxmouse:Number;					//  |
		private var lastymouse:Number;					//  |
		private var downX:Number;						//  |
		private var downY:Number;						//  |
		private var downTime:Number;					//  |
		public const NOT_DRAGGING:uint=0;				//  |
		public const NOT_MOVED:uint=1;					//  |
		public const DRAGGING:uint=2;					//  |
		public const TOLERANCE:uint=7;					//  |
		
		public var initparams:Object;					// object containing HTML page parameters

		public var backdrop:Object;						// reference to backdrop sprite
		public var tileset:TileSet;						// 900913 tile background
		private var tileurl:String='';					// internal tile URL
		private var styleurl:String='';					// internal style URL
		public var showall:Boolean=true;				// show all objects, even if unstyled?
		
		public var connection:Connection;				// server connection
		public var vectorlayers:Object={};				// VectorLayer objects 

		public const TILESPRITE:uint=0;
		public const VECTORSPRITE:uint=1;
		public const WAYSPRITE:uint=2;
		public const NAMESPRITE:uint=13;
		
		// ------------------------------------------------------------------------------------------
		// Map constructor function

        public function Map(initparams:Object) {

			this.initparams=initparams;
			connection = Connection.getConnection(initparams);
            connection.addEventListener(Connection.NEW_WAY, newWayCreated);
            connection.addEventListener(Connection.NEW_POI, newPOICreated);
            connection.addEventListener(Connection.WAY_RENUMBERED, wayRenumbered);
            connection.addEventListener(Connection.NODE_RENUMBERED, nodeRenumbered);
			gotEnvironment(null);

			addEventListener(Event.ENTER_FRAME, everyFrame);
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
					 initparams['zoom']);

			} else {
				// somewhere innocuous
				init(53.09465,-2.56495,17);
			}
		}

		// ------------------------------------------------------------------------------------------
		// Initialise map at a given lat/lon

        public function init(startlat:Number,startlon:Number,startscale:uint=0):void {
			while (numChildren) { removeChildAt(0); }

			tileset=new TileSet(this);					// 0 - 900913 background
			addChild(tileset);							//   |
			tileset.init(tileurl);						//   |

			vectorbg = new Sprite();					// 1 - vector background layers
			addChild(vectorbg);							//   |

 			paint = new MapPaint(this,-5,5);			// 2 - core paint object
			addChild(paint);							//   |
			paint.isBackground=false;					//   |

			if (styleurl) {								// if we've only just set up paint, then setStyle won't have created the RuleSet
				paint.ruleset=new RuleSet(MINSCALE,MAXSCALE,redraw,redrawPOIs);
				paint.ruleset.loadFromCSS(styleurl);
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
		
		public function nudgeBackground(x:Number,y:Number):void {
			this.dispatchEvent(new MapEvent(MapEvent.NUDGE_BACKGROUND, { x: x, y: y }));
		}

		private function moveMap(dx:Number,dy:Number):void {
			updateCoords(x+dx,y+dy);
			updateEntityUIs(false, false);
			download();
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
			mapwidth = w; centre_lon=coord2lon(-x+w/2);
			mapheight= h; centre_lat=coord2lat(-y+h/2);

			this.dispatchEvent(new MapEvent(MapEvent.RESIZE, {width:w, height:h}));
			
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
			if (connection.waycount>1000) {
				connection.purgeOutside(edge_l,edge_r,edge_t,edge_b);
			}
			addDebug("Calling download with "+edge_l+"-"+edge_r+", "+edge_t+"-"+edge_b);
			connection.loadBbox(edge_l,edge_r,edge_t,edge_b);
		}

        private function newWayCreated(event:EntityEvent):void {
            var way:Way = event.entity as Way;
			if (!way.loaded || !way.within(edge_l,edge_r,edge_t,edge_b)) { return; }
			paint.createWayUI(way);
        }

        private function newPOICreated(event:EntityEvent):void {
            var node:Node = event.entity as Node;
			if (!node.within(edge_l,edge_r,edge_t,edge_b)) { return; }
			paint.createNodeUI(node);
        }

		private function wayRenumbered(event:EntityRenumberedEvent):void {
            var way:Way = event.entity as Way;
			paint.renumberWayUI(way,event.oldID);
		}

		private function nodeRenumbered(event:EntityRenumberedEvent):void {
            var node:Node = event.entity as Node;
			paint.renumberNodeUI(node,event.oldID);
		}

        public function setHighlight(entity:Entity, settings:Object):void {
			if      ( entity is Way  && paint.wayuis[entity.id] ) { paint.wayuis[entity.id].setHighlight(settings);  }
			else if ( entity is Node && paint.nodeuis[entity.id]) { paint.nodeuis[entity.id].setHighlight(settings); }
        }

        public function setHighlightOnNodes(way:Way, settings:Object):void {
			paint.wayuis[way.id].setHighlightOnNodes(settings);
        }

		public function setPurgable(entity:Entity, purgable:Boolean):void {
			if ( entity is Way  ) {
				var way:Way=entity as Way;
				paint.wayuis[way.id].purgable=purgable;
				for (var i:uint=0; i<way.length; i++) {
					if (paint.nodeuis[way.getNode(i).id]) {
						paint.nodeuis[way.getNode(i).id].purgable=purgable;
					}
				}
			} else if ( entity is Node ) { 
				paint.nodeuis[entity.id].purgable=purgable;
			}
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
		// Add vector layer
		
		public function addVectorLayer(layer:VectorLayer):void {
			vectorlayers[layer.name]=layer;
			vectorbg.addChild(layer.paint);
		}

		// ------------------------------------------------------------------------------------------
		// Redraw all items, zoom in and out
		
		public function updateEntityUIs(redraw:Boolean,remove:Boolean):void {
			paint.updateEntityUIs(connection.getObjectsByBbox(edge_l, edge_r, edge_t, edge_b), redraw, remove);
			for each (var v:VectorLayer in vectorlayers) {
				v.paint.updateEntityUIs(v.getObjectsByBbox(edge_l, edge_r, edge_t, edge_b), redraw, remove);
			}
		}
		public function redraw():void {
			paint.redraw();
			for each (var v:VectorLayer in vectorlayers) { v.paint.redraw(); }
		}
		public function redrawPOIs():void { 
			paint.redrawPOIs();
			for each (var v:VectorLayer in vectorlayers) { v.paint.redrawPOIs(); }
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
			updateEntityUIs(true,true);
			download();
		}

		private function reportPosition():void {
			addDebug("lon "+coord2lon(mouseX)+", lat "+coord2lat(mouseY));
		}
		
		public function setStyle(url:String):void {
			styleurl=url;
			if (paint) { 
				paint.ruleset=new RuleSet(MINSCALE,MAXSCALE,redraw,redrawPOIs);
				paint.ruleset.loadFromCSS(url);
			}
        }

		public function setBackground(url:String):void {
			tileurl=url;
			if (tileset) { tileset.init(url, url!=''); }
		}

		public function setDimming(dim:Boolean):void {
			if (tileset) { tileset.setDimming(dim); }
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
		
		public function set draggable(draggable:Boolean):void {
			_draggable=draggable;
			dragstate=NOT_DRAGGING;
		}

		public function mouseDownHandler(event:MouseEvent):void {
			if (!_draggable) { return; }
			dragstate=NOT_MOVED;
			lastxmouse=mouseX; downX=stage.mouseX;
			lastymouse=mouseY; downY=stage.mouseY;
			downTime=new Date().getTime();
		}
        
		public function mouseUpHandler(event:MouseEvent=null):void {
			if (dragstate==DRAGGING) { moveMap(0,0); }
			dragstate=NOT_DRAGGING;
		}
        
		public function mouseMoveHandler(event:MouseEvent):void {
			if (!_draggable) { return; }
			if (dragstate==NOT_DRAGGING) { return; }
			
			if (dragstate==NOT_MOVED) {
				if (new Date().getTime()-downTime<300) {
					if (Math.abs(downX-stage.mouseX)<=TOLERANCE   && Math.abs(downY-stage.mouseY)<=TOLERANCE  ) return;
				} else {
					if (Math.abs(downX-stage.mouseX)<=TOLERANCE/2 && Math.abs(downY-stage.mouseY)<=TOLERANCE/2) return;
				}
				dragstate=DRAGGING;
			}
			
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
			if (event.target is TextField) return;				// not meant for us
			switch (event.keyCode) {
				case 33:	zoomIn(); break;					// Page Up - zoom in
				case 34:	zoomOut(); break;					// Page Down - zoom out
				case 37:	moveMap(mapwidth/2,0); break;		// left cursor
				case 38:	moveMap(0,mapheight/2); break;		// up cursor
				case 39:	moveMap(-mapwidth/2,0); break;		// right cursor
				case 40:	moveMap(0,-mapheight/2); break;		// down cursor
//				case 76:	reportPosition(); break;			// L - report lat/long
			}
		}

		public function connectionError(err:Object=null): void {
			addDebug("got error"); 
		}

		// ------------------------------------------------------------------------------------------
		// Debugging
		
		public function clearDebug():void {
			if (!Globals.vars.hasOwnProperty('debug')) return;
			Globals.vars.debug.text='';
		}
			
		public function addDebug(text:String):void {
			if (!Globals.vars.hasOwnProperty('debug')) return;
			if (!Globals.vars.debug.visible) return;
			Globals.vars.debug.appendText(text+"\n");
			Globals.vars.debug.scrollV=Globals.vars.debug.maxScrollV;
		}

	}
}
