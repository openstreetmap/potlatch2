package net.systemeD.halcyon {

	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.net.*;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import net.systemeD.halcyon.connection.*;
	import net.systemeD.halcyon.styleparser.*;

//	for experimental export function:
//	import flash.net.FileReference;
//	import com.adobe.images.JPGEncoder;

    /** The representation of part of the map on the screen, including information about coordinates, background imagery, paint properties etc. */
    public class Map extends Sprite {

		/** master map scale - how many Flash pixels in 1 degree longitude (for Landsat, 5120) */
		public const MASTERSCALE:Number=5825.4222222222; 
												
		/** don't zoom out past this */
		public const MINSCALE:uint=13; 
		/** don't zoom in past this */
		public const MAXSCALE:uint=23; 

		/** sprite for ways and (POI/tagged) nodes in core layer */
		public var paint:MapPaint;						 
		/** sprite for vector background layers */
		public var vectorbg:Sprite;

		/** map scale */
		public var scale:uint=14;						 
		/** current scaling factor for lon/latp */
		public var scalefactor:Number=MASTERSCALE;
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

		/** urllon-xradius/masterscale; */ 
		public var baselon:Number;
		/** lat2lat2p(urllat)+yradius/masterscale; */
		public var basey:Number; 
		/** width (Flash pixels) */
		public var mapwidth:uint; 
		/** height (Flash pixels) */
		public var mapheight:uint; 

		/** Is the map being panned */
		public var dragstate:uint=NOT_DRAGGING;			// dragging map (panning)
		/** Can the map be panned */
		private var _draggable:Boolean=true;			//  |
		private var lastxmouse:Number;					//  |
		private var lastymouse:Number;					//  |
		private var downX:Number;						//  |
		private var downY:Number;						//  |
		private var downTime:Number;					//  |
		public const NOT_DRAGGING:uint=0;				//  |
		public const NOT_MOVED:uint=1;					//  |
		public const DRAGGING:uint=2;					//  |
		/** How far the map can be dragged without actually triggering a pan. */
		public const TOLERANCE:uint=7;					//  |
		
		/** object containing HTML page parameters */
		public var initparams:Object; 

		/** reference to backdrop sprite */
		public var backdrop:Object; 
		/** background tile object */
		public var tileset:TileSet; 
		/** background tile URL, name and scheme */
		private var tileparams:Object={ url:'' }; 
		/** internal style URL */
		private var styleurl:String=''; 
		/** show all objects, even if unstyled? */
		public var showall:Boolean=true; 
		
		/** server connection */
		public var connection:Connection; 
		/** VectorLayer objects */
		public var vectorlayers:Object={};  
		
		/** Should the position of mouse cursor be shown to the user? */
		private var showingLatLon:Boolean=false;  
		
		// ------------------------------------------------------------------------------------------
		/** Map constructor function */
        public function Map(initparams:Object) {

			this.initparams=initparams;
			connection = Connection.getConnection(initparams);
            connection.addEventListener(Connection.NEW_WAY, newWayCreated);
            connection.addEventListener(Connection.NEW_POI, newPOICreated);
            connection.addEventListener(Connection.WAY_RENUMBERED, wayRenumbered);
            connection.addEventListener(Connection.NODE_RENUMBERED, nodeRenumbered);
			gotEnvironment(null);

			addEventListener(Event.ENTER_FRAME, everyFrame);
			scrollRect=new Rectangle(0,0,800,600);
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
		/** Initialise map at a given lat/lon */
        public function init(startlat:Number, startlon:Number, startscale:uint=0):void {
			while (numChildren) { removeChildAt(0); }

			tileset=new TileSet(this);					// 0 - 900913 background
			if (initparams['tileblocks']) {				//   | option to block dodgy tile sources
				tileset.blocks=initparams['tileblocks'];//   |
			}											//   |
			addChild(tileset);							//   |
			tileset.init(tileparams, false, 
			             initparams['background_dim']    ==null ? true  : initparams['background_dim'],
			             initparams['background_sharpen']==null ? false : initparams['background_sharpen']);

			vectorbg = new Sprite();					// 1 - vector background layers
			addChild(vectorbg);							//   |

 			paint = new MapPaint(this,-5,5);			// 2 - core paint object
			addChild(paint);							//   |
			paint.isBackground=false;					//   |

			if (styleurl) {								// if we've only just set up paint, then setStyle won't have created the RuleSet
				paint.ruleset=new RuleSet(MINSCALE,MAXSCALE,redraw,redrawPOIs);
				paint.ruleset.loadFromCSS(styleurl);
			}
			if (startscale>0) {
				scale=startscale;
				this.dispatchEvent(new MapEvent(MapEvent.SCALE, {scale:scale}));
			}

			scalefactor=MASTERSCALE/Math.pow(2,13-scale);
			baselon    =startlon          -(mapwidth /2)/scalefactor;
			basey      =lat2latp(startlat)+(mapheight/2)/scalefactor;
			addDebug("Baselon "+baselon+", basey "+basey);
			updateCoords(0,0);
            this.dispatchEvent(new Event(MapEvent.INITIALISED));
			download();

            if (ExternalInterface.available) {
              ExternalInterface.addCallback("setPosition", function (lat:Number,lon:Number,zoom:uint):void {
                  updateCoordsFromLatLon(lat, lon);
                  changeScale(zoom);
              });
            }
        }

		// ------------------------------------------------------------------------------------------
		/** Recalculate co-ordinates from new Flash origin */

		public function updateCoords(tx:Number,ty:Number):void {
			setScrollRectXY(tx,ty);

			edge_t=coord2lat(-ty          );
			edge_b=coord2lat(-ty+mapheight);
			edge_l=coord2lon(-tx          );
			edge_r=coord2lon(-tx+mapwidth );
			setCentre();

			tileset.update();
		}
		
		/** Move the map to centre on a given latitude/longitude. */
		public function updateCoordsFromLatLon(lat:Number,lon:Number):void {
			var cy:Number=-(lat2coord(lat)-mapheight/2);
			var cx:Number=-(lon2coord(lon)-mapwidth/2);
			updateCoords(cx,cy);
		}
		
		private function setScrollRectXY(tx:Number,ty:Number):void {
			var w:Number=scrollRect.width;
			var h:Number=scrollRect.height;
			scrollRect=new Rectangle(-tx,-ty,w,h);
		}
		private function setScrollRectSize(width:Number,height:Number):void {
			var sx:Number=scrollRect.x ? scrollRect.x : 0;
			var sy:Number=scrollRect.y ? scrollRect.y : 0;
			scrollRect=new Rectangle(sx,sy,width,height);
		}
		
		private function getX():Number { return -scrollRect.x; }
		private function getY():Number { return -scrollRect.y; }
		
		private function setCentre():void {
			centre_lat=coord2lat(-getY()+mapheight/2);
			centre_lon=coord2lon(-getX()+mapwidth/2);
			this.dispatchEvent(new MapEvent(MapEvent.MOVE, {lat:centre_lat, lon:centre_lon, scale:scale, minlon:edge_l, maxlon:edge_r, minlat:edge_b, maxlat:edge_t}));
		}
		
		/** Sets the offset between the background imagery and the map. */
		public function nudgeBackground(x:Number,y:Number):void {
			this.dispatchEvent(new MapEvent(MapEvent.NUDGE_BACKGROUND, { x: x, y: y }));
		}

		private function moveMap(dx:Number,dy:Number):void {
			updateCoords(getX()+dx,getY()+dy);
			updateEntityUIs(false, false);
			download();
		}
		
		/** Recentre map at given lat/lon, updating the UI and downloading entities. */
		public function moveMapFromLatLon(lat:Number,lon:Number):void {
			updateCoordsFromLatLon(lat,lon);
			updateEntityUIs(false,false);
			download();
		}
		
		/** Recentre map at given lat/lon, if that point is currently outside the visible area. */
		public function scrollIfNeeded(lat:Number,lon:Number): void{
            if (lat> edge_t || lat < edge_b || lon < edge_l || lon > edge_r) {
                moveMapFromLatLon(lat, lon);
            }

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


		// ------------------------------------------------------------------------------------------
		/** Resize map size based on current stage and height */

		public function updateSize(w:uint, h:uint):void {
			mapwidth = w; centre_lon=coord2lon(-getX()+w/2);
			mapheight= h; centre_lat=coord2lat(-getY()+h/2);
			setScrollRectSize(w,h);

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

        /** Download map data. Data is downloaded for the connection and the vector layers, where supported.
        * The bounding box for the download is taken from the current map edges.
        */
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

            // Do the same for vector layers
            for each (var layer:VectorLayer in vectorlayers) {
              layer.loadBbox(edge_l,edge_r,edge_t,edge_b);
            }
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

        /** Visually mark an entity as highlighted. */
        public function setHighlight(entity:Entity, settings:Object):void {
			if      ( entity is Way  && paint.wayuis[entity.id] ) { paint.wayuis[entity.id].setHighlight(settings);  }
			else if ( entity is Node && paint.nodeuis[entity.id]) { paint.nodeuis[entity.id].setHighlight(settings); }
        }

        public function setHighlightOnNodes(way:Way, settings:Object):void {
			if (paint.wayuis[way.id]) paint.wayuis[way.id].setHighlightOnNodes(settings);
        }

		public function protectWay(way:Way):void {
			if (paint.wayuis[way.id]) paint.wayuis[way.id].protectSprites();
		}

		public function unprotectWay(way:Way):void {
			if (paint.wayuis[way.id]) paint.wayuis[way.id].unprotectSprites();
		}
		
		public function limitWayDrawing(way:Way,except:Number=NaN,only:Number=NaN):void {
			if (!paint.wayuis[way.id]) return;
			paint.wayuis[way.id].drawExcept=except;
			paint.wayuis[way.id].drawOnly  =only;
			paint.wayuis[way.id].redraw();
		}

		/** Protect Entities and EntityUIs against purging. This prevents the currently selected items
		   from being purged even though they're off-screen. */

		public function setPurgable(entities:Array, purgable:Boolean):void {
			for each (var entity:Entity in entities) {
				entity.locked=!purgable;
				if ( entity is Way  ) {
					var way:Way=entity as Way;
					if (paint.wayuis[way.id]) { paint.wayuis[way.id].purgable=purgable; }
					for (var i:uint=0; i<way.length; i++) {
						var node:Node=way.getNode(i)
						node.locked=!purgable;
						if (paint.nodeuis[node.id]) { paint.nodeuis[node.id].purgable=purgable; }
					}
				} else if ( entity is Node && paint.nodeuis[entity.id]) { 
					paint.nodeuis[entity.id].purgable=purgable;
				}
			}
		}

        // Handle mouse events on ways/nodes
        private var mapController:MapController = null;

        /** Assign map controller. */
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
		/** Redraw everything, including in every vector layer. */
		public function redraw():void {
			paint.redraw();
			for each (var v:VectorLayer in vectorlayers) { v.paint.redraw(); }
		}
		/** Redraw POI's, including in every vector layer. */
		public function redrawPOIs():void { 
			paint.redrawPOIs();
			for each (var v:VectorLayer in vectorlayers) { v.paint.redrawPOIs(); }
		}
		
		/** Increase scale. */
		public function zoomIn():void {
			if (scale==MAXSCALE) { return; }
			changeScale(scale+1);
		}

		/** Decrease scale. */
		public function zoomOut():void {
			if (scale==MINSCALE) { return; }
			changeScale(scale-1);
		}

		private function changeScale(newscale:uint):void {
			addDebug("new scale "+newscale);
			scale=newscale;
			this.dispatchEvent(new MapEvent(MapEvent.SCALE, {scale:scale}));
			scalefactor=MASTERSCALE/Math.pow(2,13-scale);
			updateCoordsFromLatLon((edge_t+edge_b)/2,(edge_l+edge_r)/2);	// recentre
			tileset.changeScale(scale);
			updateEntityUIs(true,true);
			download();
		}

		private function reportPosition():void {
			addDebug("lon "+coord2lon(mouseX)+", lat "+coord2lat(mouseY));
		}

        private function toggleReportPosition():void {
            showingLatLon = !showingLatLon;
            this.dispatchEvent(new MapEvent(MapEvent.TOGGLE_LATLON, {latlon: showingLatLon}));
        }
		
		/** Switch to new MapCSS. */
		public function setStyle(url:String):void {
			styleurl=url;
			if (paint) { 
				paint.ruleset=new RuleSet(MINSCALE,MAXSCALE,redraw,redrawPOIs);
				paint.ruleset.loadFromCSS(url);
			}
        }

		/** Select a new background imagery. */
		public function setBackground(bg:Object):void {
			tileparams=bg;
			if (tileset) { tileset.init(bg, bg.url!=''); }
		}

		/** Set background dimming on/off. */
		public function setDimming(dim:Boolean):void {
			if (tileset) { tileset.setDimming(dim); }
		}
		
		/** Return background dimming. */
		public function getDimming():Boolean {
			if (tileset) { return tileset.getDimming(); }
			return true;
		}

		/** Set background sharpening on/off. */
		public function setSharpen(sharpen:Boolean):void {
			if (tileset) { tileset.setSharpen(sharpen); }
		}
		/** Return background sharpening. */
		public function getSharpen():Boolean {
			if (tileset) { return tileset.getSharpen(); }
			return false;
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
		
		/** Should map be allowed to pan? */
		public function set draggable(draggable:Boolean):void {
			_draggable=draggable;
			dragstate=NOT_DRAGGING;
		}

		/** Prepare for being dragged by recording start time and location of mouse. */
		public function mouseDownHandler(event:MouseEvent):void {
			if (!_draggable) { return; }
			dragstate=NOT_MOVED;
			lastxmouse=stage.mouseX; downX=stage.mouseX;
			lastymouse=stage.mouseY; downY=stage.mouseY;
			downTime=new Date().getTime();
		}
        
		/** Respond to mouse up by possibly moving map. */
		public function mouseUpHandler(event:MouseEvent=null):void {
			if (dragstate==DRAGGING) { moveMap(x,y); }
			dragstate=NOT_DRAGGING;
		}
        
		/** Respond to mouse movement, dragging the map if tolerance threshold met. */
		public function mouseMoveHandler(event:MouseEvent):void {
			if (!_draggable) { return; }
			if (dragstate==NOT_DRAGGING) { 
			   this.dispatchEvent(new MapEvent(MapEvent.MOUSEOVER, { x: coord2lon(mouseX), y: coord2lat(mouseY) }));
               return; 
            }
			
			if (dragstate==NOT_MOVED) {
				if (new Date().getTime()-downTime<300) {
					if (Math.abs(downX-stage.mouseX)<=TOLERANCE   && Math.abs(downY-stage.mouseY)<=TOLERANCE  ) return;
				} else {
					if (Math.abs(downX-stage.mouseX)<=TOLERANCE/2 && Math.abs(downY-stage.mouseY)<=TOLERANCE/2) return;
				}
				dragstate=DRAGGING;
			}
			
			setScrollRectXY(getX()+stage.mouseX-lastxmouse,getY()+stage.mouseY-lastymouse);
			lastxmouse=stage.mouseX; lastymouse=stage.mouseY;
			setCentre();
		}
        
		// ------------------------------------------------------------------------------------------
		// Do every frame

		private function everyFrame(event:Event):void {
			if (tileset) { tileset.serviceQueue(); }
		}

		// ------------------------------------------------------------------------------------------
		// Miscellaneous events
		
		/** Respond to cursor movements and zoom in/out.*/
		public function keyUpHandler(event:KeyboardEvent):void {
			if (event.target is TextField) return;				// not meant for us
			switch (event.keyCode) {
				case Keyboard.PAGE_UP:	zoomIn(); break;                 // Page Up - zoom in
				case Keyboard.PAGE_DOWN:	zoomOut(); break;            // Page Down - zoom out
				case Keyboard.LEFT:	moveMap(mapwidth/2,0); break;        // left cursor
				case Keyboard.UP:	moveMap(0,mapheight/2); break;		 // up cursor
				case Keyboard.RIGHT:	moveMap(-mapwidth/2,0); break;   // right cursor
				case Keyboard.DOWN:	moveMap(0,-mapheight/2); break;      // down cursor
				case 76:	toggleReportPosition(); break;			// L - report lat/long
			}
		}

		/** What to do if an error with the network connection happens. */
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
			trace(text);
			if (!Globals.vars.hasOwnProperty('debug')) return;
			if (!Globals.vars.debug.visible) return;
			Globals.vars.debug.appendText(text+"\n");
			Globals.vars.debug.scrollV=Globals.vars.debug.maxScrollV;
		}

	}
}
