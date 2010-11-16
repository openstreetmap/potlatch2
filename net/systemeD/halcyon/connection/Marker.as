package net.systemeD.halcyon.connection {


    /**
    * A marker is a generic entity that can be used for representing non-Node point features.
    * For example, it can be used for displaying bug reports or waypoints on VectorBackground layers
    */
    public class Marker extends Entity {
        private var _lat:Number;
        private var _latproj:Number;
        private var _lon:Number;

        public function Marker(id:Number, version:uint, tags:Object, loaded:Boolean, lat:Number, lon:Number) {
            super(id, version, tags, loaded, 0, null);
            this._lat = lat;
            this._latproj = lat2latp(lat);
            this._lon = lon;
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

        public override function within(left:Number,right:Number,top:Number,bottom:Number):Boolean {
            if (_lon<left || _lon>right || _lat<bottom || _lat>top || deleted) { return false; }
            return true;
        }

        public static function lat2latp(lat:Number):Number {
            return 180/Math.PI * Math.log(Math.tan(Math.PI/4+lat*(Math.PI/180)/2));
        }

        public static function latp2lat(a:Number):Number {
            return 180/Math.PI * (2 * Math.atan(Math.exp(a*Math.PI/180)) - Math.PI/2);
        }

        public override function toString():String {
            return "Marker("+id+"@"+version+"): "+lat+","+lon+" "+getTagList();
        }

        public override function getType():String {
            return 'node';
        }
    }
}