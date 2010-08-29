package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import mx.containers.Box;
    import flash.events.*;

    public class SingleTagEditor extends Box {

      protected var _factory:SingleTagEditorFactory;
      protected var _entity:Entity;
      
      [Bindable(event="factory_set")]
      public function get fieldName():String {
          return _factory == null ? "" : _factory.name;
      }
      
      [Bindable(event="factory_set")]
      public function get fieldDescription():String {
          return _factory == null ? "" : _factory.description;
      }

      [Bindable(event="factory_set")]
      public function get fieldDirection():String {
          return _factory == null ? "" : _factory.direction;
      }
      
      [Bindable(event="tag_changed")]
      public function get value():String {
          return _entity == null ? null : _entity.getTag(_factory.key);
      }
      
      public function set value(val:String):void {
          if ( _entity != null )
              _entity.setTag(_factory.key, val, MainUndoStack.getGlobalStack().addAction);
      }

      public function set factory(factory:SingleTagEditorFactory):void {
          _factory = factory;
          dispatchEvent(new Event("factory_set"));
      }
      
      public function set entity(entity:Entity):void {
          _entity = entity;
          entity.addEventListener(Connection.TAG_CHANGED, tagChanged, false, 0, true);
          dispatchEvent(new Event("tag_changed"));
      }
      
      private function tagChanged(event:TagEvent):void {
          var tagVal:String = _entity.getTag(_factory.key);
          dispatchEvent(new Event("tag_changed"));
      }

    }

}


