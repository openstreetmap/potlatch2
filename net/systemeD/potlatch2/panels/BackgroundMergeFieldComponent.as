package net.systemeD.potlatch2.panels {

    import mx.controls.Label;
    import mx.controls.dataGridClasses.*;
    import net.systemeD.potlatch2.panels.BackgroundMergePanel;

    public class BackgroundMergeFieldComponent extends Label {

     override public function set data(value:Object):void
     {
        if(value != null)
        {
            super.data = value;
            textField.background = true;
            textField.backgroundColor = BackgroundMergePanel(listData.owner.parent).getColorFor(listData.rowIndex);
        }
     }
  }

}