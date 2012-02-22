package net.systemeD.halcyon.connection.actions {

    import org.flexunit.Assert;
    import net.systemeD.halcyon.connection.actions.JoinNodeAction;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.UndoableAction;
    import net.systemeD.halcyon.connection.Connection;

    [RunWith("org.mockito.integrations.flexunit4.MockitoClassRunner")]
    public class JoinNodeActionTest {

      [Mock(type="net.systemeD.halcyon.connection.Connection", argsList="constructorArgs")]
      public var connection:Connection;
      public var constructorArgs:Array = ["name", "api", "policy"];

        [Test]
        public function joinTwoNodes():void {
            var n:Node = new Node(connection,1,1,{},true,5,10);
            var n1:Node = new Node(connection,2,1,{},true,5,10);
            var action:UndoableAction = new JoinNodeAction(n, [n1], []);
            action.doAction();
            Assert.assertFalse(n.isDeleted());
            Assert.assertTrue(n1.isDeleted());
        }

    }
}