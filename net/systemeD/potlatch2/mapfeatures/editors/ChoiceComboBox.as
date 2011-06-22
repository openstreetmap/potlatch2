package net.systemeD.potlatch2.mapfeatures.editors {

    import mx.controls.*;
    import mx.containers.*;
    import mx.core.*;
    import flash.display.*;
    import flash.events.*;
    import mx.events.*;
    import mx.utils.*;

	public class ChoiceComboBox extends ComboBox {

        protected var textInputReplacement:UIComponent;

        override protected function createChildren():void {
                super.createChildren();

                if ( !textInputReplacement ) {
                        if ( itemRenderer != null ) {
                                //remove the default textInput
                                removeChild(textInput);

                                //create a new itemRenderer to use in place of the text input
                                textInputReplacement = itemRenderer.newInstance();
                                IDataRenderer(textInputReplacement).data = selectedItem;
                                textInputReplacement.mouseChildren = false;
                                textInputReplacement.mouseEnabled = false;
                                addChild(textInputReplacement);
                        }
                }
        }

        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
            super.updateDisplayList(unscaledWidth, unscaledHeight);

            if ( textInputReplacement ) {
                IDataRenderer(textInputReplacement).data = selectedItem;

                var arrowWidth:Number = getStyle("arrowButtonWidth");
                var itemHeight:Number = textInputReplacement.getExplicitOrMeasuredHeight();
                var itemWidth:Number = textInputReplacement.getExplicitOrMeasuredWidth();

                if (isNaN(arrowWidth))
                    arrowWidth = 0;

                var bm:EdgeMetrics = borderMetrics;

                textInputReplacement.setActualSize(unscaledWidth - arrowWidth, itemHeight);
                textInputReplacement.move(bm.left, bm.top);
            }
        }

        override protected function measure():void {
            super.measure();

            if ( textInputReplacement ) {
                IDataRenderer(textInputReplacement).data = selectedItem;
                var prefSize:Object = calculatePreferredSizeFromData(collection.length);

                var arrowWidth:Number = getStyle("arrowButtonWidth");
                var itemHeight:Number = textInputReplacement.getExplicitOrMeasuredHeight();
                var itemWidth:Number = textInputReplacement.getExplicitOrMeasuredWidth();

                if (isNaN(arrowWidth))
                    arrowWidth = 0;

                var bm:EdgeMetrics = borderMetrics;
                itemHeight += bm.top + bm.bottom;
                itemWidth += bm.left + bm.right + arrowWidth + 8;
                prefSize.height += bm.top + bm.bottom;
                prefSize.width += bm.left + bm.right + arrowWidth + 8;

                measuredMinHeight = measuredHeight = Math.max(prefSize.height, itemHeight);
                measuredMinWidth = measuredWidth = Math.max(prefSize.width, itemWidth);
            }
        }

        override protected function calculatePreferredSizeFromData(numItems:int):Object {
            if ( collection == null ) return { width: 0, height: 0 };
            
            var maxWidth:Number = 0;
            var maxHeight:Number = 0;
            
            var test:UIComponent = itemRenderer.newInstance();
            addChild(test)
            for ( var i:int = 0; i < numItems; i++ ) {
                IDataRenderer(test).data = collection[i];
                test.validateDisplayList();
                test.validateSize(true);
                maxWidth = Math.max(maxWidth, test.getExplicitOrMeasuredWidth());
                maxHeight = Math.max(maxHeight, test.getExplicitOrMeasuredHeight());
            }
            removeChild(test);
            return {width: maxWidth, height: maxHeight};
        }
    }
}


