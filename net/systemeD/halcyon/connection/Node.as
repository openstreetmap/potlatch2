package net.systemeD.halcyon.connection {

    public class Node extends Entity {
        private var _lat:Number;
        private var _latproj:Number;
        private var _lon:Number;

        public function Node(id:Number, version:uint, tags:Object, lat:Number, lon:Number) {
            super(id, version, tags);
            this.lat = lat;
            this.lon = lon;
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
            this._lat = lat;
            this._latproj = lat2latp(lat);
        }

        public function set lon(lon:Number):void {
            this._lon = lon;
        }

        public function toString():String {
            return "Node("+id+"@"+version+"): "+lat+","+lon+" "+getTagList();
        }

        public static function lat2latp(lat:Number):Number {
            return 180/Math.PI * Math.log(Math.tan(Math.PI/4+lat*(Math.PI/180)/2));
        }
    }

}
