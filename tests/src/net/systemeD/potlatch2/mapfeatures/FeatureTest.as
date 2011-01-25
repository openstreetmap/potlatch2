package net.systemeD.potlatch2.mapfeatures {

    import org.flexunit.Assert;
    import net.systemeD.potlatch2.mapfeatures.Feature;
    import net.systemeD.potlatch2.mapfeatures.MapFeatures;
    import org.mockito.integrations.verify;

    [RunWith("org.mockito.integrations.flexunit4.MockitoClassRunner")]
    public class FeatureTest {

        // Running with [Rule] is now 'preferred' instead of using the RunWith statement above,
        // but I couldn't get it to work.
        // [Rule]
        // public var mockitoRule:IMethodRule = new MockitoRule();

        [Mock(type="net.systemeD.potlatch2.mapfeatures.MapFeatures")]
        public var mockMapfeatures:MapFeatures;

        [Test]
        public function testFeature():void {
            // This just tests that the mocking is working properly
            var f:Feature = new Feature(mockMapfeatures, XML("<feature />"));
            Assert.assertNull(f.name);
        }

        [Test]
        public function testFeatureName():void {
            var f:Feature = new Feature(mockMapfeatures, XML('<feature name="my_feature"/>'));
            Assert.assertEquals("my_feature", f.name);
        }

        [Test]
        public function testTagsFromFeature():void {
            var f:Feature = new Feature(mockMapfeatures, XML('<feature><tag k="highway" v="residential" /></feature>'));
            Assert.assertEquals("highway", f.tags[0].k);
        }

        // TODO - test that a feature with an inputSet has the keys from the inputSet available via the tags method.
        // i.e. test that [25133] works, and also test it works for nested inputSets.
    }
}
