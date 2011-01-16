package net.systemeD.halcyon {

    import flash.events.Event;
	import net.systemeD.halcyon.connection.Entity;

    public class AttentionEvent extends Event {

		public static const ATTENTION:String = "attention";
		public static const ALERT:String = "alert";

		public var entity:Entity;
		public var message:String;
		public var priority:uint;

		public var params:Object;

        public function AttentionEvent(eventname:String, entity:Entity, message:String="", priority:uint=0) {
            super(eventname);
			this.entity  =entity;
			this.message =message;
			this.priority=priority;
        }
    }
}
