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

                var arrowWidth:Number = getStyle("arrowButtonWidth");
                var itemHeight:Number = textInputReplacement.getExplicitOrMeasuredHeight();
                var itemWidth:Number = textInputReplacement.getExplicitOrMeasuredWidth();

                if (isNaN(arrowWidth))
                    arrowWidth = 0;

                var bm:EdgeMetrics = borderMetrics;
                itemHeight += bm.top + bm.bottom;
                itemWidth += bm.left + bm.right + arrowWidth;

                measuredMinHeight = measuredHeight = Math.max(measuredHeight, itemHeight);
                measuredMinWidth = measuredWidth = Math.max(measuredWidth, itemWidth);
            }
        }

    }
}


