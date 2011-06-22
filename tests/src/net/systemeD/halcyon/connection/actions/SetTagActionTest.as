package net.systemeD.halcyon.connection.actions {

    import org.flexunit.Assert;
    import net.systemeD.halcyon.connection.actions.SetTagAction;
    import net.systemeD.halcyon.connection.UndoableAction;
    import net.systemeD.halcyon.connection.Entity;
    import net.systemeD.halcyon.connection.Connection;

    public class SetTagActionTest {

        [Before]
        public function setUp():void {
            //Instantiate the connection first to prevent errors
            Connection.getConnection();
        }

        [Test]
        public function setTag():void {
            var e:Entity = new Entity(1,1,{},true,1,"");
            var action:UndoableAction = new SetTagAction(e, "foo", "bar");
            action.doAction();

            Assert.assertEquals("bar", e.getTag("foo"));
        }

        [Test]
        public function setNullTag():void {
            var e:Entity = new Entity(1,1,{foo: "bar"},true,1,"");
            var action:UndoableAction = new SetTagAction(e, "foo", null);
            action.doAction();

            Assert.assertNull(e.getTag("foo"));
        }

    }
}