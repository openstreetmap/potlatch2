package net.systemeD.potlatch2.save {

    import flash.events.*;
    import flash.net.*;
    import mx.managers.PopUpManager;
    import mx.core.Application;
    import net.systemeD.halcyon.connection.*;
    import org.iotashan.oauth.*;

    public class SaveManager {
    
        private static var instance:SaveManager = new SaveManager();

        public static function saveChanges():void {
            instance.save(instance.saveData);
        }

        public static function ensureAccess(callback:Function):void {
            instance.save(callback);
        }

        private function save(callback:Function):void {
            var conn:Connection = Connection.getConnectionInstance();
            if (conn.hasAccessToken()) {
                callback();
            } else {
                getNewToken(callback);
            }
        }

        private function getNewToken(onCompletion:Function):void {
            var oauthPanel:OAuthPanel = OAuthPanel(
                PopUpManager.createPopUp(Application(Application.application), OAuthPanel, true));
            PopUpManager.centerPopUp(oauthPanel);
            
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
                PopUpManager.createPopUp(Application(Application.application), SaveDialog, true));
            PopUpManager.centerPopUp(saveDialog);

			if (Connection.getConnectionInstance().getActiveChangeset()) {
				saveDialog.dontPrompt();
			}
        }
    }
    
}

