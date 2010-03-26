package net.systemeD.potlatch2 {

	import flash.events.Event;
	import flash.events.MouseEvent;
	import mx.containers.Panel;
	import net.systemeD.halcyon.connection.*;
    import net.systemeD.potlatch2.controller.*;
    import net.systemeD.potlatch2.tools.*;

	/*
		Floating toolbox palette

		Still to do:
		** Should have a close box, and be able to be activated from the top bar
		** Should be automatically positioned at bottom-right of canvas on init
		** Should float above tagViewer, not beneath it
		** Icons should be disabled depending on what's selected (setEntity can do this)
		** Straighten, circularise, reverse way direction, parallelise
		** Remove annoying Illustrator cruft from SVG icons!

	*/

	public class Toolbox extends Panel{
		
		private var entity:Entity;
		private var controller:EditController;

		public function Toolbox(){
			super();
		}
		
		public function init(controller:EditController):void {
			this.controller=controller;
		}

		override protected function createChildren():void {
			super.createChildren();
			super.titleBar.addEventListener(MouseEvent.MOUSE_DOWN,handleDown);
			super.titleBar.addEventListener(MouseEvent.MOUSE_UP,handleUp);
		}

		public function setEntity(entity:Entity):void {
			this.entity=entity;
		}

		private function handleDown(e:Event):void {
			this.startDrag();
		}

		private function handleUp(e:Event):void {
			this.stopDrag();
		}

		// --------------------------------------------------------------------------------
		// Individual toolbox actions

		public function doDelete():void {
			if (entity is Node) { controller.connection.unregisterPOI(Node(entity)); }
			entity.remove();

			if (controller.state is SelectedWayNode) {
				controller.setState(new SelectedWay(SelectedWayNode(controller.state).selectedWay));
			} else {
				controller.setState(new NoSelection());
			}
		}

		public function doQuadrilateralise():void {
			if (entity is Way) {
				Quadrilateralise.quadrilateralise(Way(entity));
			}
		}

		public function doStraighten():void {
			if (entity is Way) {
				Straighten.straighten(Way(entity),controller.map);
			}
		}

		public function doCircularise():void {
			if (entity is Way) {
				Circularise.circularise(Way(entity),controller.map);
			}
		}

	}
}