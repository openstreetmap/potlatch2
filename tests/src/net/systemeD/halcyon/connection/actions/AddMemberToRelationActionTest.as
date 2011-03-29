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

            //This throws an error, but JoinNodeActionTest doesn't. Why?

            //rel.appendMember(member, function(action:UndoableAction):void { action.doAction(); })
            //Assert.assertEquals(rel.length,1);

            //Assert.assertNotNull(Connection.getConnectionInstance()) <- this fails, and is the cause of the above failing. Why?
        }

        [Test]
        public function spliceStuff():void {

            var arr:Array = ["a", "b", "c", "d"];
            Assert.assertEquals(arr.length, 4);

            arr.splice(-1, 0, "e");
            Assert.assertEquals(arr.length, 5);

            arr.splice(-1, 1);
            Assert.assertEquals(arr.length, 4);
        }
    }
}