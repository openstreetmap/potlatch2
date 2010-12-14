package net.systemeD.halcyon.connection.actions {

    import org.flexunit.Assert;
    import net.systemeD.halcyon.connection.actions.JoinNodeAction;
    import net.systemeD.halcyon.connection.Node;
    import net.systemeD.halcyon.connection.UndoableAction;

    public class JoinNodeActionTest {

        [Test]
        public function joinTwoNodes():void {
            var n:Node = new Node(1,1,{},true,5,10);
            var n1:Node = new Node(2,1,{},true,5,10);
            var action:UndoableAction = new JoinNodeAction(n, [n1], []);
            action.doAction();
            Assert.assertFalse(n.isDeleted());
            Assert.assertTrue(n1.isDeleted());
        }

    }
}