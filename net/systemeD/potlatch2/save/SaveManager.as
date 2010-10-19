package net.systemeD.potlatch2.save {

    import flash.events.*;
    import flash.net.*;
    import mx.managers.PopUpManager;
    import mx.core.Application;
    import net.systemeD.halcyon.connection.*;
    import org.iotashan.oauth.*;

    public class SaveManager {
    
        private static var instance:SaveManager = new SaveManager();
        
        private var accessToken:OAuthToken;
        private var consumer:OAuthConsumer;

        public static function saveChanges():void {
            instance.save(instance.saveData);
        }

        public static function getAccessSorted():void {
            // hacky hack of pond-like clarity
            instance.save(instance.doNothing);
        }

        private function doNothing():void {
            //hack hacky hack hack. Please look the other way...
            Connection.getConnectionInstance().setAppID(consumer);
            Connection.getConnectionInstance().setAuthToken(accessToken);
        }

        private function save(callback:Function):void {
            var conn:Connection = Connection.getConnectionInstance();
            if ( consumer == null )
                consumer = getConsumer();
            if ( accessToken == null )
                accessToken = conn.getAccessToken(SharedObject.getLocal("access_token").data);
        
            if ( accessToken == null )
                getNewToken(callback);
            else
                callback();
        }

        private function getConsumer():OAuthConsumer {
            var key:String = Connection.getParam("oauth_consumer_key", null);
            var secret:String = Connection.getParam("oauth_consumer_secret", null);
            
            if ( key == null || secret == null )
                return null;
            else    
                return new OAuthConsumer(key, secret);
        }
        
        private function getNewToken(onCompletion:Function):void {
            var oauthPanel:OAuthPanel = OAuthPanel(
                PopUpManager.createPopUp(Application(Application.application), OAuthPanel, true));
            PopUpManager.centerPopUp(oauthPanel);
            
            var listener:Function = function(event:Event):void {
                accessToken = oauthPanel.accessToken;
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
			} else {
	            Connection.getConnectionInstance().setAppID(consumer);
	            Connection.getConnectionInstance().setAuthToken(accessToken);
			}
        }
    }
    
}

