package net.systemeD.potlatch2.collections {

    import flash.events.Event;

    public class CollectionEvent extends Event {

		public static const SELECT:String = "select";

		public var data:Object;

        public function CollectionEvent(eventname:String, data:Object) {
            super(eventname);
			this.data=data;
        }
    }

}
