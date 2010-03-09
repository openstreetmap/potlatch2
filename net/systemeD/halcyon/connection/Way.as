package net.systemeD.halcyon.connection {
    import flash.geom.Point;
	import net.systemeD.halcyon.Globals;

    public class Way extends Entity {
        private var nodes:Array;
		public static var entity_type:String = 'way';

        public function Way(id:Number, version:uint, tags:Object, loaded:Boolean, nodes:Array) {
            super(id, version, tags, loaded);
            this.nodes = nodes;
			for each (var node:Node in nodes) { node.addParent(this); }
        }

		public function update(version:uint, tags:Object, loaded:Boolean, nodes:Array):void {
			var node:Node;
			for each (node in this.nodes) { node.removeParent(this); }
			updateEntityProperties(version,tags,loaded); this.nodes=nodes;
			for each (node in nodes) { node.addParent(this); }
		}
		
        public function get length():uint {
            return nodes.length;
        }
        
        public function getNode(index:uint):Node {
            return nodes[index];
        }

		public function getLastNode():Node {
			return nodes[nodes.length-1];
		}

        public function insertNode(index:uint, node:Node):void {
			node.addParent(this);
            nodes.splice(index, 0, node);
            markDirty();
            dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, this, index));
        }

        public function appendNode(node:Node):uint {
			node.addParent(this);
            nodes.push(node);
            markDirty();
            dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, this, nodes.length - 1));
            return nodes.length;
        }
        
        public function prependNode(node:Node):uint {
			node.addParent(this);
            nodes.unshift(node);
            markDirty();
            dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_ADDED, node, this, 0));
            return nodes.length;
        }
        
        public function indexOfNode(node:Node):uint {
            return nodes.indexOf(node);
        }

		public function removeNode(node:Node):void {
			var i:int;
			while ((i=nodes.indexOf(node))>-1) {
				nodes.splice(i,1);
            	dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, node, this, i));
			}
			node.removeParent(this);
			markDirty();
		}

        public function removeNodeByIndex(index:uint):void {
            var removed:Array=nodes.splice(index, 1);
			if (nodes.indexOf(removed[0])==-1) { removed[0].removeParent(this); }
			markDirty();
            dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, removed[0], this, index));
        }

		public function sliceNodes(start:int,end:int):Array {
			return nodes.slice(start,end);
		}

		public function deleteNodesFrom(start:int):void {
			nodes.splice(start);
		}

		public function mergeWith(way:Way,topos:int,frompos:int):void {
			var i:int;

			// merge relations
			for each (var r:Relation in way.parentRelations) {
				// ** needs to copy roles as well
				if (r.findEntityMemberIndex(this)==-1) {
					r.appendMember(new RelationMember(this, ''));
				}
			}

			// merge tags
			var t:Object=way.getTagsHash();
			for (var k:String in t) {
				if (getTag(k) && getTag(k)!=t[k]) {
					setTag(k,getTag(k)+"; "+t[k]);
					// ** send a warning about tags not matching
				} else {
					setTag(k,t[k]);
				}
			}

			// merge nodes
			if (frompos==0) { for (i=0; i<way.length;    i++) { addToEnd(topos,way.getNode(i)); } }
					   else { for (i=way.length-1; i>=0; i--) { addToEnd(topos,way.getNode(i)); } }

			// delete way
			way.remove();
		}
		
		private function addToEnd(topos:int,node:Node):void {
			if (topos==0) {
				if (nodes[0]==node) { return; }
				prependNode(node);
			} else {
				if (nodes[nodes.length-1]==node) { return; }
				appendNode(node);
			}
		}



        /**
         * Finds the 1st way segment which intersects the projected
         * coordinate and adds the node to that segment. If snap is
         * specified then the node is moved to exactly bisect the
         * segment.
         */
        public function insertNodeAtClosestPosition(newNode:Node, isSnap:Boolean):int {
            var closestProportion:Number = 1;
            var newIndex:uint = 0;
            var nP:Point = new Point(newNode.lon, newNode.latp);
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
            
            // splice in new node
            if ( isSnap ) {
                newNode.latp = snapped.y;
                newNode.lon = snapped.x;
            }
            insertNode(newIndex, newNode);
            return newIndex;
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
			return (nodes[0].id==nodes[nodes.length-1].id && nodes.length>2);
		}
		
		public override function remove():void {
			var node:Node;
			removeFromParents();
			while (nodes.length) { 
				node=nodes.pop();
				dispatchEvent(new WayNodeEvent(Connection.WAY_NODE_REMOVED, node, this, 0));
				// ** the event mechanism calls redraw once per wayNodeRemoved, which isn't too efficient
				//    so we should probably add a 'redraw' flag to WayNodeEvent
				node.removeParent(this);
				if (!node.hasParents) { node.remove(); }
			}
			deleted=true;
            dispatchEvent(new EntityEvent(Connection.WAY_DELETED, this));
		}

		internal override function isEmpty():Boolean {
			return (deleted || (nodes.length==0));
		}

		public override function getType():String {
			return 'way';
		}
    }

}
