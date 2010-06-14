package net.systemeD.potlatch2.mapfeatures.editors {

    import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.mapfeatures.*;
    import mx.containers.VBox;
    import flash.events.*;

	public class RelationMemberEditor extends VBox {

      protected var _factory:RelationMemberEditorFactory;
      protected var _entity:Entity;
      
      [Bindable(event="factory_set")]
      public function get fieldName():String {
          return _factory == null ? "" : _factory.name;
      }
      
      [Bindable(event="factory_set")]
      public function get fieldDescription():String {
          return _factory == null ? "" : _factory.description;
      }
      
      [Bindable(event="relations_changed")]
      public function get matchedRelations():Array {
          if (_entity == null)
              return [];
          
          var relationTags:Object = _factory.relationTags;
          var matched:Array = [];
          for each(var relation:Relation in _entity.parentRelations) {
              var addable:Boolean = true;
              for ( var k:String in relationTags ) {
                  var relVal:String = relation.getTag(k);
                  if ( relVal != relationTags[k] )
                      addable = false;
              }
              if (addable) {
                  for each( var memberIndex:int in relation.findEntityMemberIndexes(_entity)) {
                      var props:Object = {};
                      props["relation"] = relation;
                      props["id"] = relation.id;
                      props["index"] = memberIndex;
                      props["role"] = relation.getMember(memberIndex).role;
                      props["entity"] = _entity;
                      matched.push(props);
                  }
              }
          }
          return matched;
      }
      
      public function addMember(relation:Relation, role:String):void {
          if (_entity != null && !_entity.hasParent(relation))
              relation.appendMember(new RelationMember(_entity, role));
      }

      public function set factory(factory:RelationMemberEditorFactory):void {
          _factory = factory;
          dispatchEvent(new Event("factory_set"));
      }
      
      public function set entity(entity:Entity):void {
          _entity = entity;
          
          entity.addEventListener(Connection.ADDED_TO_RELATION, relationsChanged);
          entity.addEventListener(Connection.REMOVED_FROM_RELATION, relationsChanged);
          dispatchEvent(new Event("relations_changed"));
      }
      
      protected function relationsChanged(event:Event):void {
          dispatchEvent(new Event("relations_changed"));
      }

    }

}


