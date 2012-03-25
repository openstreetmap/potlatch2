package net.systemeD.halcyon {

    /**
    * A Stylesheet is a simple object refering to the name and url of the stylesheet.
    */
    public class Stylesheet {

        /** The user-visible name of the stylesheet */
        public var name:String;

        /** The (relative to potlatch2.swf) url of the stylesheet */
        public var url:String;

        /** Should this stylesheet be considered a "core style"? */
        public var coreStyle:Boolean;

        public function Stylesheet(name:String, url:String, coreStyle:Boolean = false) {
            this.name = name;
            this.url = url;
            this.coreStyle = coreStyle;
        }
    }
}