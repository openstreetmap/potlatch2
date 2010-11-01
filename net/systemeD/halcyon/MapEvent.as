package net.systemeD.halcyon {

    import flash.events.Event;

    public class MapEvent extends Event {

		public static const DOWNLOAD:String = "download";
		public static const RESIZE:String = "resize";
		public static const MOVE:String = "move";
		public static const SCALE:String = "scale";
		public static const NUDGE_BACKGROUND:String = "nudge_background";
		public static const ERROR:String = "error";

		public var params:Object;

        public function MapEvent(eventname:String, params:Object) {
            super(eventname);
            this.params=params;
        }
    }

}
