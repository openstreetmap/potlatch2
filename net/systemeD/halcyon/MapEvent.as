package net.systemeD.halcyon {

    import flash.events.Event;

    public class MapEvent extends Event {

		public static const DOWNLOAD:String = "download";
		public var minlon:Number, maxlon:Number, maxlat:Number, minlat:Number;

        public function MapEvent(eventname:String, minlon:Number, maxlon:Number, maxlat:Number, minlat:Number) {
            super(eventname);
            this.minlat = minlat;
            this.minlon = minlon;
            this.maxlat = maxlat;
            this.maxlon = maxlon;
        }
    }

}
