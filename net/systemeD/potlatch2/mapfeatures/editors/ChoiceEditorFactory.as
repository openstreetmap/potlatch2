package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import net.systemeD.halcyon.FileBank;
    import flash.display.*;
    import flash.events.*;

	public class ChoiceEditorFactory extends SingleTagEditorFactory {
	    public var choices:Array;
        
        public function ChoiceEditorFactory(inputXML:XML) {
            super(inputXML,"horizontal");
            
            choices = [];

            var fileBank:FileBank = FileBank.getInstance();
            
            for each( var choiceXML:XML in inputXML.choice ) {
                var choice:Choice = new Choice();
                choice.value = String(choiceXML.@value);
                choice.description = String(choiceXML.@description);
                choice.label = String(choiceXML.@text);
                choice.match = String(choiceXML.@match);
                if (choiceXML.hasOwnProperty("@icon")) {
                    var icon:String = String(choiceXML.@icon);
                    fileBank.addFromFile(icon, choice.imageLoaded);
                }
                choices.push(choice);
            }
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new ChoiceEditor();
        }
    }

}


