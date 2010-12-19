package net.systemeD.halcyon {

    import flash.events.Event;

    /** Defines map-related events. */
    public class MapEvent extends Event {

		public static const DOWNLOAD:String = "download";
		public static const RESIZE:String = "resize";
		public static const MOVE:String = "move";
		public static const SCALE:String = "scale";
		public static const NUDGE_BACKGROUND:String = "nudge_background";
        public static const INITIALISED:String = "initialized";
		public static const BUMP:String = "bump";
		public static const ERROR:String = "error";				// ** FIXME - this should be a dedicated ErrorEvent class
		public static const ATTENTION:String = "attention";		// ** FIXME - this should be a dedicated AttentionEvent class

		public var params:Object;

        public function MapEvent(eventname:String, params:Object) {
            super(eventname);
            this.params=params;
        }
    }

}
