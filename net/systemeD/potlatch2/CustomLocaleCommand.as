package net.systemeD.potlatch2 {
    import org.babelfx.commands.ExternalLocaleCommand;
    import net.systemeD.halcyon.Globals;

    public class CustomLocaleCommand extends ExternalLocaleCommand {
        public var defaultExternalPath:String;

        override protected function loadLocale(locale:String):void {
            externalPath = defaultExternalPath;

            if (Globals.vars.locale_paths) {
                for each (var path:String in Globals.vars.locale_paths.split(";")) {
                    var args:Array = path.split("=");

                    if (args[0] == locale) {
                        externalPath = args[1];
                    }
                }
            }

            super.loadLocale(locale);
        }
    }
}
