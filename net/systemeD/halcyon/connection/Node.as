package net.systemeD.halcyon.connection {

    import net.systemeD.halcyon.connection.actions.*;

    public class Node extends Entity {
        private var _lat:Number;
        private var _latproj:Number;
        private var _lon:Number;

        public function Node(id:Number, version:uint, tags:Object, loaded:Boolean, lat:Number, lon:Number, uid:Number = NaN, timestamp:String = null) {
            super(id, version, tags, loaded, uid, timestamp);
            this._lat = lat;
            this._latproj = lat2latp(lat);
            this._lon = lon;
        }

		public function update(version:uint, tags:Object, loaded:Boolean, lat:Number, lon:Number, uid:Number = NaN, timestamp:String = null):void {
			updateEntityProperties(version,tags,loaded,uid,timestamp); setLatLonImmediate(lat,lon);
		}

        public function get lat():Number {
            return _lat;
        }

        public function get latp():Number {
            return _latproj;
        }

        public function get lon():Number {
            return _lon;
        }

        private function setLatLonImmediate(lat:Number, lon:Number):void {
            var connection:Connection = Connection.getConnection();
            connection.removeDupe(this);
            this._lat = lat;
            this._latproj = lat2latp(lat);
            this._lon = lon;
            connection.addDupe(this);
			for each (var way:Way in this.parentWays) {
				way.expandBbox(this);
			}
        }
        
        public function set lat(lat:Number):void {
            MainUndoStack.getGlobalStack().addAction(new MoveNodeAction(this, lat, _lon, setLatLonImmediate));
        }

        public function set latp(latproj:Number):void {
            MainUndoStack.getGlobalStack().addAction(new MoveNodeAction(this, latp2lat(latproj), _lon, setLatLonImmediate));
        }

        public function set lon(lon:Number):void {
            MainUndoStack.getGlobalStack().addAction(new MoveNodeAction(this, _lat, lon, setLatLonImmediate));
        }
        
        public function setLatLon(lat:Number, lon:Number, performAction:Function):void {
            performAction(new MoveNodeAction(this, lat, lon, setLatLonImmediate));
        } 

		public function setLonLatp(lon:Number,latproj:Number, performAction:Function):void {
		    performAction(new MoveNodeAction(this, latp2lat(latproj), lon, setLatLonImmediate));
		}

        public override function toString():String {
            return "Node("+id+"@"+version+"): "+lat+","+lon+" "+getTagList();
        }

		public override function remove(performAction:Function):void {
			performAction(new DeleteNodeAction(this, setDeletedState));
		}

		public override function within(left:Number,right:Number,top:Number,bottom:Number):Boolean {
			if (_lon<left || _lon>right || _lat<bottom || _lat>top || deleted) { return false; }
			return true;
		}

        public function unjoin(selectedWay:Way, performAction:Function):void {
            if (parentWays.length > 1) {
              performAction(new UnjoinNodeAction(this, selectedWay));
            } else {
              trace("not enough ways");
            }
        }

        /**
        * Insert this node into the list of ways, and remove dupes at the same time.
        * Please, don't call this on a node from a vector background, chaos will ensue.
        */
        public function join(ways:Array, performAction:Function):void {
            if (this.isDupe() || ways.length > 0) {
              var connection:Connection = Connection.getConnection();
              var nodes:Array = connection.getNodesAtPosition(lat,lon);
              // filter the nodes array to remove any occurances of this.
              // Pass "this" as thisObject to get "this" into the callback function
              var dupes:Array = nodes.filter(
                  function(element:*, index:int, arr:Array):Boolean {
                    return (element != this);
                  },
                  this
                );
              performAction(new JoinNodeAction(this, dupes, ways));
            }
        }

        /**
        * Replace all occurances of this node with the given target node
        */
        public function replaceWith(target:Node, performAction:Function):void {
            performAction(new ReplaceNodeAction(this, target));
        }

        public function isDupe():Boolean {
            var connection:Connection = Connection.getConnection();
            if (connection.getNode(this.id) == this // node could be part of a vector layer
                && connection.nodesAtPosition(lat, lon) > 1) {
              return true;
            }
            return false;
        }

		internal override function isEmpty():Boolean {
			return deleted;
		}

        public static function lat2latp(lat:Number):Number {
            return 180/Math.PI * Math.log(Math.tan(Math.PI/4+lat*(Math.PI/180)/2));
        }

		public static function latp2lat(a:Number):Number {
		    return 180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2);
		}
		
		public override function getType():String {
			return 'node';
		}
    }

}
