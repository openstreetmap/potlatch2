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

      [Test]
      public function within():void {
          var n:Node = new Node(1,1,{},true,5,10);
          Assert.assertTrue(n.within(9,11,6,4));
          Assert.assertFalse(n.within(9,11,1,2));
          Assert.assertFalse(n.within(11,12,6,4));
          n.remove(function(action:UndoableAction):void { action.doAction(); });
          Assert.assertFalse(n.within(9,11,6,4));
      }

    }
}
