package net.systemeD.potlatch2.save {

    import flash.events.*;
    import flash.net.*;
    import mx.managers.PopUpManager;
    import mx.core.Application;
    import mx.core.FlexGlobals;
    import net.systemeD.halcyon.connection.*;
    import org.iotashan.oauth.*;

    public class SaveManager {
    
        private static var instance:SaveManager = new SaveManager();
		private var _connection:Connection;

        public static function saveChanges(connection:Connection):void {
            instance.save(instance.saveData,connection);
        }

        public static function ensureAccess(callback:Function, connection:Connection):void {
            instance.save(callback,connection);
        }

        private function save(callback:Function, connection:Connection):void {
			_connection=connection;
            if (connection.hasAccessToken()) {
                callback();
            } else {
                getNewToken(callback);
            }
        }

        private function getNewToken(onCompletion:Function):void {
            var oauthPanel:OAuthPanel = OAuthPanel(
                PopUpManager.createPopUp(Application(FlexGlobals.topLevelApplication), OAuthPanel, true));
            PopUpManager.centerPopUp(oauthPanel);
			oauthPanel.setConnection(_connection);
            
            var listener:Function = function(event:Event):void {
                var accessToken:OAuthToken = oauthPanel.accessToken;
                if ( oauthPanel.shouldRemember ) {
                    var obj:SharedObject = SharedObject.getLocal("access_token");
                    obj.setProperty("oauth_token", accessToken.key);
                    obj.setProperty("oauth_token_secret", accessToken.secret);
                    obj.flush();
                }
                onCompletion();
            }
            oauthPanel.addEventListener(OAuthPanel.ACCESS_TOKEN_EVENT, listener);
        }
        
        private function saveData():void {
            var saveDialog:SaveDialog = SaveDialog(
                PopUpManager.createPopUp(Application(FlexGlobals.topLevelApplication), SaveDialog, true));
			saveDialog.setConnection(_connection);
            PopUpManager.centerPopUp(saveDialog);

			if (_connection.getActiveChangeset()) saveDialog.dontPrompt();
        }
    }
    
}

