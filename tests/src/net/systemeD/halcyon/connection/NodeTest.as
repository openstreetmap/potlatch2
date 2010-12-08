package net.systemeD.halcyon.connection {

    import org.flexunit.Assert;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.UndoableAction;

    public class NodeTest {

    
      [Test]
      public function dummy():void {
          Assert.assertEquals(10,10);
      }

      [Test]
      public function newNode():void {
          var n:Node = new Node(1,1,{},true,5,10);
          Assert.assertEquals(n.lat, 5);
      }

      [Test]
      public function moveNode():void {
          var n:Node = new Node(1,1,{},true,5,10);
          n.setLatLon(14,41, function(action:UndoableAction):void { action.doAction(); });
          Assert.assertEquals(n.lat, 14);
          Assert.assertEquals(n.lon, 41);
      }
     
    }
}
