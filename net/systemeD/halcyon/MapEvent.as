package net.systemeD.halcyon {

    import flash.events.Event;

    /** Defines map-related events. */
    public class MapEvent extends Event {

		/** Data has been requested for download. */
		public static const DOWNLOAD:String = "download";
		/** Viewport size has changed. */
		public static const RESIZE:String = "resize";
		/** Map has moved relative to viewport. */
		public static const MOVE:String = "move";
		/** Zoom level has changed. */
		public static const SCALE:String = "scale";
		/** Background imagery has moved relative to map. */
		public static const NUDGE_BACKGROUND:String = "nudge_background";
        /** Map has been created and is ready, although data is not yet downloaded. */
        public static const INITIALISED:String = "initialized";
		/** Backrgound imagery has changed to one with attribution that must not be obscured. */
		public static const BUMP:String = "bump";
		public static const MOUSEOVER:String="mouseover";
		public static const TOGGLE_LATLON:String="toggle_latlon";
		public static const ERROR:String = "error";				// ** FIXME - this should be a dedicated ErrorEvent class

		/** Event-specific parameters. */
		public var params:Object;

        /** Creates event with name given by a constant, with event-specific parameters. */
        public function MapEvent(eventname:String, params:Object) {
            super(eventname);
            this.params=params;
        }
    }

}
