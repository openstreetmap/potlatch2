package net.systemeD.halcyon.connection {

    import flash.events.Event;

    public class SaveCompleteEvent extends Event {
        private var _saveOK:Boolean;

        public function SaveCompleteEvent(type:String, saveOK:Boolean) {
            super(type);
            this._saveOK = saveOK;
        }

        public function get saveOK():Boolean {
            return _saveOK;
        }
    }

}
