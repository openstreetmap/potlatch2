package net.systemeD.halcyon.connection.actions {

    import org.flexunit.Assert;
    import net.systemeD.halcyon.connection.actions.AddMemberToRelationAction;
    import net.systemeD.halcyon.connection.Relation;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.RelationMember;
    import net.systemeD.halcyon.connection.UndoableAction;
    import net.systemeD.halcyon.connection.*;

    [RunWith("org.mockito.integrations.flexunit4.MockitoClassRunner")]
    public class AddMemberToRelationActionTest {

        [Mock(type="net.systemeD.halcyon.connection.Connection", argsList="constructorArgs")]
        public var connection:Connection;
        public var constructorArgs:Array = ["name", "api", "policy"];

        [Before]
        public function setUp():void {
            //Instantiate the connection first to prevent errors
            //Connection.getConnection();
        }


        [Test]
        public function addMember():void {

            var n:Node = new Node(connection,1,1,{},true,5,10);

            var rel:Relation = new Relation(connection,1,1,{},true,[]);
            var member:RelationMember = new RelationMember(n, "foo");

            rel.appendMember(member, function(action:UndoableAction):void { action.doAction(); });
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

        [Test]
        public function appendMember():void {
            var n:Node = new Node(connection,1,1,{},true,5,10);
            var n2:Node = new Node(connection,2,1,{},true,5,10);
            var n3:Node = new Node(connection,3,1,{},true,5,10);

            var member1:RelationMember = new RelationMember(n, "first");
            var member2:RelationMember = new RelationMember(n2, "second");
            var member3:RelationMember = new RelationMember(n3, "third");

            var rel:Relation = new Relation(connection,1,1,{},true, [member1, member2]);
            Assert.assertEquals(2, rel.length);

            rel.appendMember(member3, function(action:UndoableAction):void { action.doAction(); });
            Assert.assertEquals(member3, rel.getMember(2));
        }

        [Test]
        public function setMember():void {
            var n:Node = new Node(connection,1,1,{},true,5,10);
            var n2:Node = new Node(connection,2,1,{},true,5,10);
            var n3:Node = new Node(connection,3,1,{},true,5,10);

            var member1:RelationMember = new RelationMember(n, "first");
            var member2:RelationMember = new RelationMember(n2, "second");
            var member3:RelationMember = new RelationMember(n3, "third");

            var rel:Relation = new Relation(connection,1,1,{},true, [member1, member2]);
            Assert.assertEquals(2, rel.length);

            rel.setMember(1, member3, function(action:UndoableAction):void { action.doAction(); });
            Assert.assertEquals(member3, rel.getMember(1));

            Assert.assertEquals(2, rel.length);
        }
    }
}