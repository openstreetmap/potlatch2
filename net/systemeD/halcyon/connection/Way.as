package net.systemeD.halcyon.connection {
    import flash.geom.Point;
    
    import net.systemeD.halcyon.connection.actions.*;

    public class Way extends Entity {
        private var nodes:Array;
		private var edge_l:Number;
		private var edge_r:Number;
		private var edge_t:Number;
		private var edge_b:Number;
		public static var entity_type:String = 'way';

        public function Way(connection:Connection, id:Number, version:uint, tags:Object, loaded:Boolean, nodes:Array, uid:Number = NaN, timestamp:String = null, user:String = null) {
            super(connection, id, version, tags, loaded, uid, timestamp, user);
            this.nodes = nodes;
			for each (var node:Node in nodes) { node.addParent(this); }
			calculateBbox();
        }

		public function update(version:uint, tags:Object, loaded:Boolean, parentsLoaded:Boolean, nodes:Array, uid:Number = NaN, timestamp:String = null, user:String = null):void {
			var node:Node;
			for each (node in this.nodes) { node.removeParent(this); }
			updateEntityProperties(version,tags,loaded,parentsLoaded,uid,timestamp,user); this.nodes=nodes;
			for each (node in nodes) { node.addParent(this); }
			calculateBbox();
		}
		
        public function get length():uint {
            return nodes.length;
        }

		public function get nodeList():Array {
			var arr:Array=[];
			for each (var node:Node in nodes) { arr.push(node.id); }
			return arr;
		}

		private function calculateBbox():void {
			edge_l=999999; edge_r=-999999;
			edge_b=999999; edge_t=-999999;
			for each (var node:Node in nodes) { expandBbox(node); }
		}

		public function expandBbox(node:Node):void {
			edge_l=Math.min(edge_l,node.lon);
			edge_r=Math.max(edge_r,node.lon);
			edge_b=Math.min(edge_b,node.lat);
			edge_t=Math.max(edge_t,node.lat);
		}
		
		public override function within(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			if (!edge_l ||
				(edge_l<left   && edge_r<left  ) ||
			    (edge_l>right  && edge_r>right ) ||
			    (edge_b<bottom && edge_t<bottom) ||
			    (edge_b>top    && edge_b>top   ) || deleted) { return false; }
			return true;
		}

        public function getNode(index:uint):Node {
            return nodes[index];
        }

        public function getFirstNode():Node {
            return nodes[0];
        }

		public function getLastNode():Node {
			return nodes[nodes.length-1];
		}
		
		/** Given one node, return the next in sequence, cycling around a loop if necessary. */
		// TODO make behave correctly for P-shaped topologies?
		public function getNextNode(node:Node):Node {
			// If the last node in a loop is selected, this behaves correctly.
		    var i:uint = indexOfNode(node);
		    if(i < length-1)
	            return nodes[i+1];
	        return null;
	        // What should happen for very short lengths?      
		}
        
        // TODO make behave correctly for P-shaped topologies?
        /** Given one node, return the previous, cycling around a loop if necessary. */
        public function getPrevNode(node:Node):Node {
            var i:uint = indexOfNode(node);
            if(i > 0)
                return nodes[i-1];
            if(i == 0 && isArea() )
                return nodes[nodes.length - 2]
            return null;
            // What should happen for very short lengths?      
        }

        public function insertNode(index:uint, node:Node, performAction:Function):void {
			if (index>0 && getNode(index-1)==node) return;
			if (index<nodes.length-1 && getNode(index)==node) return;
			performAction(new AddNodeToWayAction(this, node, nodes, index, false));
        }

        public function appendNode(node:Node, performAction:Function):uint {
			if (node!=getLastNode()) performAction(new AddNodeToWayAction(this, node, nodes, -1));
            return nodes.length + 1;
        }
        
        public function prependNode(node:Node, performAction:Function):uint {
			if (node!=getFirstNode()) performAction(new AddNodeToWayAction(this, node, nodes, 0));
            return nodes.length + 1;
        }
        
        // return the index of the Node, or -1 if not found
        public function indexOfNode(node:Node):int {
            return nodes.indexOf(node);
        }

		public function hasOnceOnly(node:Node):Boolean {
			return nodes.indexOf(node)==nodes.lastIndexOf(node);
		}
		
		public function hasLockedNodes():Boolean {
			for each (var node:Node in nodes) {
				if (node.locked) { return true; }
			}
			return false;
		}

		public function removeNode(node:Node, performAction:Function):void {
			performAction(new RemoveNodeFromWayAction(this, node, nodes));
		}

        public function removeNodeByIndex(index:uint, performAction:Function, fireEvent:Boolean=true):void {
            performAction(new RemoveNodeByIndexAction(this, nodes, index, fireEvent));
        }

		public function sliceNodes(start:int,end:int):Array {
			return nodes.slice(start,end);
		}

        public function deleteNodesFrom(start:int, performAction:Function):void {
            for (var i:int=nodes.length-1; i>=start; i--) {
              performAction(new RemoveNodeByIndexAction(this, nodes, i));
            }
            markDirty();
        }

		/** Merges another way into this one, removing the other one. */
		public function mergeWith(way:Way,topos:int,frompos:int, performAction:Function):void {
			performAction(new MergeWaysAction(this, way, topos, frompos));
		}
		
		public function addToEnd(topos:int,node:Node, performAction:Function):void {
			if (topos==0) {
				if (nodes[0]==node) { return; }
				prependNode(node, performAction);
			} else {
				if (nodes[nodes.length-1]==node) { return; }
				appendNode(node, performAction);
			}
		}

        public function reverseNodes(performAction:Function):void {
            performAction(new ReverseNodesAction(this, nodes));
        }
        
        /** Check for, and remove, consecutive series of the same node */ 
        public function removeRepeatedNodes(performAction:Function):void {
        	var n: Node = nodes[0];
        	for (var i:int = 1; i < nodes.length; i++) {
        		if (nodes[i] == nodes[i-1]) {
        			removeNodeByIndex(i, performAction);
        		}
        	}
        } 

		
		/** Is a point within this way?
		* From http://as3.miguelmoraleda.com/2009/10/28/point-in-polygon-with-actionscript-3punto-dentro-de-un-poligono-con-actionscript-3/
		*/

		public function pointWithin(lon:Number,lat:Number):Boolean {
			if (!isArea()) return false;
			
			var counter:uint = 0;
			var p1x:Number = nodes[0].lon;
			var p1y:Number = nodes[0].lat;
			var p2x:Number, p2y:Number;
 
			for (var i:uint = 1; i <= length; i++) {
				p2x = nodes[i % length].lon;
				p2y = nodes[i % length].lat;
				if (lat > Math.min(p1y, p2y)) {
					if (lat <= Math.max(p1y, p2y)) {
						if (lon <= Math.max(p1x, p2x)) {
							if (p1y != p2y) {
								var xinters:Number = (lat - p1y) * (p2x - p1x) / (p2y - p1y) + p1x;
								if (p1x == p2x || lon <= xinters) counter++;
							}
						}
					}
				}
				p1x = p2x;
				p1y = p2y;
			}
			if (counter % 2 == 0) { return false; }
			else { return true; }
		}

		/**
		 * Finds the 1st way segment which intersects the projected
		 * coordinate and adds the node to that segment. If snap is
		 * specified then the node is moved to exactly bisect the
		 * segment.
		 */
		public function insertNodeAtClosestPosition(newNode:Node, isSnap:Boolean, performAction:Function):int {
			var o:Object=indexOfClosestNode(newNode.lon, newNode.latp);
			if (isSnap) { newNode.setLonLatp(o.snapped.x, o.snapped.y, performAction); }
			insertNode(o.index, newNode, performAction);
			return o.index;
		}

		/* Variant of insertNodeAtClosestPosition that will move an existing node if available,
		   rather than creating a new one. Used for 'improve way accuracy' click.
		   
		   Ideally, rather than using 0.15/0.85, we should be sensitive to actual distance and to zoom level.
		   Could maybe also do with being bent to fix the issue at concave angles. */
		public function insertNodeOrMoveExisting(lat:Number, lon:Number, performAction:Function):void {
			var latp:Number=Node.lat2latp(lat);
			var o:Object=distanceFromWay2(lon,latp);
			if (o.proportion<0.15) {
				nodes[o.index-1].setLatLon(lat,lon,performAction);
			} else if (o.proportion>0.85) {
				nodes[o.index  ].setLatLon(lat,lon,performAction);
			} else {
				var node:Node = connection.createNode({}, lat, lon, performAction);
				insertNode(o.index, node, performAction);
			}
		}

		/* Find which node is closest to a given lat/lon. */
		private function indexOfClosestNode(lon:Number, latp:Number):Object {
            var closestProportion:Number = Infinity;
            var newIndex:uint = 0;
            var nP:Point = new Point(lon, latp);
            var snapped:Point = null;
            
            for ( var i:uint; i < length - 1; i++ ) {
                var node1:Node = getNode(i);
                var node2:Node = getNode(i+1);
                var p1:Point = new Point(node1.lon, node1.latp);
                var p2:Point = new Point(node2.lon, node2.latp);
                
                var directDist:Number = Point.distance(p1, p2);
                var viaNewDist:Number = Point.distance(p1, nP) + Point.distance(nP, p2);
                        
                var proportion:Number = Math.abs(viaNewDist/directDist - 1);
                if ( proportion < closestProportion ) {
                    newIndex = i+1;
                    closestProportion = proportion;
                    snapped = calculateSnappedPoint(p1, p2, nP);
                }
            }
            return { index: newIndex, snapped: snapped };
        }
        
        private function calculateSnappedPoint(p1:Point, p2:Point, nP:Point):Point {
            var w:Number = p2.x - p1.x;
            var h:Number = p2.y - p1.y;
            var u:Number = ((nP.x-p1.x) * w + (nP.y-p1.y) * h) / (w*w + h*h);
            return new Point(p1.x + u*w, p1.y+u*h);
        }
        
        public override function toString():String {
            return "Way("+id+"@"+version+"): "+getTagList()+
                     " "+nodes.map(function(item:Node,index:int, arr:Array):String {return item.id.toString();}).join(",");
        }

		public function isArea():Boolean {
			if (nodes.length==0) { return false; }
			return (nodes[0].id==nodes[nodes.length-1].id && nodes.length>2);
		}
		
		public function endsWith(node:Node):Boolean {
			return (nodes[0]==node || nodes[nodes.length-1]==node);
		}
		
		public override function remove(performAction:Function):void {
			performAction(new DeleteWayAction(this, setDeletedState, nodes));
		}

		public override function nullify():void {
			nullifyEntity();
			nodes=[];
			edge_l=edge_r=edge_t=edge_b=NaN;
		}
		
		public function get clockwise():Boolean {
			var lowest:uint=0;
			var xmin:Number=-999999; var ymin:Number=-999999;
			for (var i:uint=0; i<nodes.length; i++) {
				if      (nodes[i].latp> ymin) { lowest=i; xmin=nodes[i].lon; ymin=nodes[i].latp; }
				else if (nodes[i].latp==ymin
					  && nodes[i].lon > xmin) { lowest=i; xmin=nodes[i].lon; ymin=nodes[i].latp; }
			}
			return (this.onLeft(lowest)>0);
		}
		
		private function onLeft(j:uint):Number {
			var left:Number=0;
			var i:int, k:int;
			if (nodes.length>=3) {
				i=j-1; if (i==-1) { i=nodes.length-2; }
				k=j+1; if (k==nodes.length) { k=1; }
				left=((nodes[j].lon-nodes[i].lon) * (nodes[k].latp-nodes[i].latp) -
					  (nodes[k].lon-nodes[i].lon) * (nodes[j].latp-nodes[i].latp));
			}
			return left;
		}

        public function get angle():Number {
            var dx:Number = nodes[nodes.length-1].lon - nodes[0].lon;
            var dy:Number = nodes[nodes.length-1].latp - nodes[0].latp;
            if (dx != 0 || dy != 0) {
                return Math.atan2(dx,dy)*(180/Math.PI);
            } else {
                return 0;
            }
        }

		internal override function isEmpty():Boolean {
			return (deleted || (nodes.length==0));
		}

		public override function getType():String {
			return 'way';
		}
		
		public override function isType(str:String):Boolean {
			if (str=='way') return true;
			if (str=='line' && !isArea()) return true;
			if (str=='area' &&  isArea()) return true;
			return false;
		}
		
		/** Whether the way has a loop that joins back midway along its length */
		public function isPShape():Boolean {
			return getFirstNode() != getLastNode() && (!hasOnceOnly(getFirstNode()) || !hasOnceOnly(getLastNode()) );
		}
		
		/** Given a P-shaped way, return the index of midway node that one end connects back to. */
		public function getPJunctionNodeIndex():uint {
			if (isPShape()) {
			    if (hasOnceOnly(getFirstNode())) {
			        // nodes[0] is the free end
			        return nodes.indexOf(getLastNode());
			    } else {
			        // nodes[0] is in the loop
			        return nodes.lastIndexOf(getFirstNode());
			    }
			}
			return null;
		}

		public function intersects(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			// simple test first: are any nodes contained?
			for (var i:uint=0; i<nodes.length; i++) {
				if (nodes[i].within(left,right,top,bottom)) return true;
			}
			// more complex test: do any segments cross?
			for (i=0; i<nodes.length-1; i++) {
				if (lineIntersectsRectangle(
					nodes[i  ].lon, nodes[i  ].lat,
					nodes[i+1].lon, nodes[i+1].lat,
					left,right,top,bottom)) return true;
			}
			return false;
		}
		
		private function lineIntersectsRectangle(x0:Number, y0:Number, x1:Number, y1:Number, l:Number, r:Number, b:Number, t:Number):Boolean {
			// from http://sebleedelisle.com/2009/05/super-fast-trianglerectangle-intersection-test/
			// note that t and b are transposed above because we're dealing with lat (top=90), not AS3 pixels (top=0)
			var m:Number = (y1-y0) / (x1-x0);
			var c:Number = y0 -(m*x0);
			var top_intersection:Number, bottom_intersection:Number;
			var toptrianglepoint:Number, bottomtrianglepoint:Number;

			if (m>0) {
				top_intersection = (m*l  + c);
				bottom_intersection = (m*r  + c);
			} else {
				top_intersection = (m*r  + c);
				bottom_intersection = (m*l  + c);
			}

			if (y0<y1) {
				toptrianglepoint = y0;
				bottomtrianglepoint = y1;
			} else {
				toptrianglepoint = y1;
				bottomtrianglepoint = y0;
			}

			var topoverlap:Number = top_intersection>toptrianglepoint ? top_intersection : toptrianglepoint;
			var botoverlap:Number = bottom_intersection<bottomtrianglepoint ? bottom_intersection : bottomtrianglepoint;
			return (topoverlap<botoverlap) && (!((botoverlap<t) || (topoverlap>b)));
		}

		public function distanceFromWay(lon:Number, latp:Number, startAt:uint=0, endAt:int=-1):Object {
			var i:uint, ax:Number, ay:Number, bx:Number, by:Number, l:Number;
			var ad:Number, bd:Number;
			var r:Number, d:Number, px:Number, py:Number;
			var furthdist:Number=-1; var furthsgn:int=1;
			var bestIndex:uint;
			if (endAt==-1) { endAt=nodes.length-1; }
			for (i=startAt; i<endAt; i++) {
				ax=nodes[i  ].lon; ay=nodes[i  ].latp;
				bx=nodes[i+1].lon; by=nodes[i+1].latp;

				ad=Math.sqrt(Math.pow(lon-ax,2)+Math.pow(latp-ay,2));	// distance to ax,ay
				bd=Math.sqrt(Math.pow(bx-lon,2)+Math.pow(by-latp,2));	// distance to bx,by
				l =Math.sqrt(Math.pow(bx-ax ,2)+Math.pow(by-ay  ,2));	// length of segment
				r =ad/(ad+bd);											// proportion along segment
				px=ax+r*(bx-ax); py=ay+r*(by-ay);						// nearest point on line
				d=Math.sqrt(Math.pow(px-lon,2)+Math.pow(py-latp,2));	// distance from px,py to lon,latp

				if (furthdist<0 || furthdist>d) {
					furthdist=d;
					furthsgn=sgn((bx-ax)*(latp-ay)-(by-ay)*(lon-ax));
					bestIndex=i+1;
				}
			}
			return { index: bestIndex, distance: furthdist*furthsgn };
		}

		/* This is a better algorithm than the above (doesn't screw up when near to vertices),
		   but we need to backport the furthsgn calculation. */
		public function distanceFromWay2(lon:Number, latp:Number):Object {
			var q:Point = new Point(lon,latp);		// q is the point
			var dist:Number = Infinity;

			var a:Point, b:Point, daq:Point, dbq:Point, dab:Point, currentDist:Number, index:uint, u:Number;
			for (var i:uint=1; i<nodes.length; i++) {
				a = new Point(nodes[i-1].lon, nodes[i-1].latp);
				b = new Point(nodes[i  ].lon, nodes[i  ].latp);
				daq = new Point(a.x-q.x, a.y-q.y);
				dbq = new Point(b.x-q.x, b.y-q.y);
				dab = new Point(a.x-b.x, a.y-b.y);
				var inv:Number=1/(Math.pow(dab.x,2)+Math.pow(dab.y,2));
				var t:Number=(dab.x*daq.x + dab.y*daq.y)*inv;
				if (t>=0) {
					if (t<=1) {
						currentDist = Math.pow(dab.x*dbq.y - dab.y*dbq.x, 2)*inv;
					} else {
						currentDist = Math.pow(dbq.x,2)+Math.pow(dbq.y,2);
					}
					if (currentDist<dist) { dist=currentDist; index=i; u=t; }
				}
			}
			return { index: index, distance: dist, proportion: u };
		}

		private function sgn(a:Number):Number {
			if (a==0) return 0;
			if (a<0) return -1;
			return 1;
		}
    }
}
