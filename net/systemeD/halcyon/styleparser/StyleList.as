package net.systemeD.halcyon.styleparser {

	public class StyleList {

		/*
			A StyleList object is the full list of all styles applied to 
			a drawn entity (i.e. node/way).
			
			Each array element applies to that sublayer (z-index). If there
			is no element, nothing is drawn on that sublayer.

		*/

		public var shapeStyles:Array=[];
		public var textStyles:Array=[];
		public var pointStyles:Array=[];
		public var shieldStyles:Array=[];

	}
}