package {

    import net.systemeD.halcyon.connection.NodeTest;
    import net.systemeD.halcyon.connection.actions.JoinNodeActionTest;
    import net.systemeD.potlatch2.mapfeatures.FeatureTest;

    [Suite]
    [RunWith("org.flexunit.runners.Suite")]
    public class AllHalcyonTests {

        public var nodeTest:NodeTest;
        public var joinNodeActionTest:JoinNodeActionTest;

        //Potlatch2 tests. If anyone wants to separate these out, and / or rename the suite, feel free
        public var featureTest:FeatureTest;

    }
}
