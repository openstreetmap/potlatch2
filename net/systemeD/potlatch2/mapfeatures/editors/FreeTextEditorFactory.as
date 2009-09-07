package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import flash.display.*;

	public class FreeTextEditorFactory extends SingleTagEditorFactory {
	    private var notPresentText:String;
        
        public function FreeTextEditorFactory(inputXML:XML) {
            super(inputXML);
            notPresentText = inputXML.@absenceHTMLText;
        }
        
        override protected function createSingleTagEditor():SingleTagEditor {
            return new FreeTextEditor();
        }
    }

}


