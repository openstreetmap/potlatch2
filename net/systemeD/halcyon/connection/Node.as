package net.systemeD.halcyon.connection {

    public class Node extends Entity {
        private var _lat:Number;
        private var _latproj:Number;
        private var _lon:Number;

        public function Node(id:Number, version:uint, tags:Object, loaded:Boolean, lat:Number, lon:Number) {
            super(id, version, tags, loaded);
            this._lat = lat;
            this._latproj = lat2latp(lat);
            this._lon = lon;
        }

		public function update(version:uint, tags:Object, loaded:Boolean, lat:Number, lon:Number):void {
			updateEntityProperties(version,tags,loaded); this.lat=lat; this.lon=lon;
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

        public function set lat(lat:Number):void {
            var oldLat:Number = this._lat;
            this._lat = lat;
            this._latproj = lat2latp(lat);
            markDirty();
            dispatchEvent(new NodeMovedEvent(Connection.NODE_MOVED, this, oldLat, _lon));
        }

        public function set latp(latproj:Number):void {
            var oldLat:Number = this._lat;
            this._latproj = latproj;
            this._lat = latp2lat(latproj);
            markDirty();
            dispatchEvent(new NodeMovedEvent(Connection.NODE_MOVED, this, oldLat, _lon));
         }

        public function set lon(lon:Number):void {
            var oldLon:Number = this._lon;
            this._lon = lon;
            markDirty();
            dispatchEvent(new NodeMovedEvent(Connection.NODE_MOVED, this, _lat, oldLon));
         }

        public override function toString():String {
            return "Node("+id+"@"+version+"): "+lat+","+lon+" "+getTagList();
        }

		public override function remove():void {
			removeFromParents();
			deleted=true;
            dispatchEvent(new EntityEvent(Connection.NODE_DELETED, this));
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
