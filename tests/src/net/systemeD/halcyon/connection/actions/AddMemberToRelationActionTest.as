package net.systemeD.halcyon.connection.actions {

    import org.flexunit.Assert;
    import net.systemeD.halcyon.connection.actions.AddMemberToRelationAction;
    import net.systemeD.halcyon.connection.Relation;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.RelationMember;
    import net.systemeD.halcyon.connection.UndoableAction;
    import net.systemeD.halcyon.connection.*;

    public class AddMemberToRelationActionTest {

        [Test]
        public function addMember():void {

            var n:Node = new Node(1,1,{},true,5,10);

            var rel:Relation = new Relation(1,1,{},true,[]);
            var member:RelationMember = new RelationMember(n, "foo");

            //Instantiate the connection first to prevent errors
            Connection.getConnection();
            rel.appendMember(member, function(action:UndoableAction):void { action.doAction(); })
            Assert.assertEquals(1, rel.length);

        }

        [Test]
        public function spliceStuff():void {

            // create an array
            var arr:Array = ["a", "b", "c", "d"];
            Assert.assertEquals(4, arr.length);

            // doesn't actually splice onto the end, inserts at position 4
            arr.splice(-1, 0, "e");
            Assert.assertEquals(5, arr.length);
            Assert.assertEquals("e", arr[3]);
            Assert.assertEquals("d", arr[4]);
        }
    }
}