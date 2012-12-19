package net.systemeD.potlatch2.save {

    import flash.events.*;
    import flash.net.*;
    import mx.managers.PopUpManager;
    import mx.core.Application;
    import mx.core.FlexGlobals;
    import mx.controls.Alert;
    import mx.events.CloseEvent;
    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.controller.*;
    import org.iotashan.oauth.*;

    public class SaveManager {
    
        private static var instance:SaveManager = new SaveManager();
		private var _connection:Connection;

        public static function saveChanges(connection:Connection, accept:Boolean=false):void {
			if (connection.changesAreDestructive() && !accept) {
				var check:String=connection.getParam('user_check','');
				if (check=='warn') {
					Alert.show("You are deleting data from OpenStreetMap. Remember, you are changing the map everyone sees, not just your own private map. Are you really sure?","Are you sure?",
						Alert.CANCEL | Alert.YES, null, function(e:CloseEvent):void {
							if (e.detail==Alert.CANCEL) return;
							SaveManager.saveChanges(connection,true);
						}, null, Alert.CANCEL);
					return;
				} else if (check=='prevent') {
					Alert.show("You are deleting too much data from OpenStreetMap - remember your changes affect the map everyone sees. If the data genuinely needs to be removed, please ask an experienced user to do it.","Deleting data",Alert.CANCEL);
					return;
				}
			}
            instance.save(instance.saveData,connection);
        }

        public static function ensureAccess(callback:Function, connection:Connection):void {
            instance.save(callback,connection);
        }

        private function save(callback:Function, connection:Connection):void {
			FlexGlobals.topLevelApplication.theController.setState(new NoSelection());
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
                    var obj:SharedObject = SharedObject.getLocal("access_token","/");
                    obj.setProperty("oauth_token", accessToken.key);
                    obj.setProperty("oauth_token_secret", accessToken.secret);
                    try { obj.flush(); } catch (e:Error) {}
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

