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
            instance.save();
        }
        
        private function save():void {
            if ( consumer == null )
                consumer = getConsumer();
            if ( accessToken == null )
                accessToken = getAccessToken();
        
            if ( accessToken == null )
                getNewToken(saveData);
            else
                saveData();
        }
    
        private function getAccessToken():OAuthToken {
            var key:String = Connection.getParam("oauth_token", null);
            var secret:String = Connection.getParam("oauth_token_secret", null);
            
            if ( key == null || secret == null ) {
                var data:Object = SharedObject.getLocal("access_token", "/potlatch2.swf").data;
                key = data["oauth_token"];
                secret = data["oauth_token_secret"];
            }
            
            if ( key == null || secret == null )
                return null;
            else    
                return new OAuthToken(key, secret);
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
                    var obj:SharedObject = SharedObject.getLocal("access_token", "/potlatch2.swf");
                    obj.setProperty("oauth_token", accessToken.key);
                    obj.setProperty("oauth_token_secret", accessToken.secret);
                    obj.flush();
                }
                onCompletion();
            }
            oauthPanel.addEventListener(OAuthPanel.ACCESS_TOKEN_EVENT, listener);
        }
        
        private function saveData():void {
            Connection.getConnectionInstance().setAppID(consumer);
            Connection.getConnectionInstance().setAuthToken(accessToken);
            
            var saveDialog:SaveDialog = SaveDialog(
                PopUpManager.createPopUp(Application(Application.application), SaveDialog, true));
            PopUpManager.centerPopUp(saveDialog);
        }
    }
    
}

