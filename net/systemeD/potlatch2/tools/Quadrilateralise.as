package net.systemeD.potlatch2.tools {
  import net.systemeD.halcyon.connection.Way;
  import net.systemeD.halcyon.connection.Node;
  import flash.geom.Point;

  public class Quadrilateralise {
    const NUM_STEPS:uint = 1000;
    const TOLERANCE:Number = 1.0e-8;

    /**
     * Attempts to make all corners of a way right angles. Returns true if it
     * thought it was successful and false if it failed. If it fails it does not
     * modify the way.
     */
    public static function quadrilateralise(way:Way):Boolean {
      // needs a closed way to work properly.
      if (!way.isArea()) {
	return false;
      }

      var functor:Quadrilateralise = new Quadrilateralise(way);
      var score:Number = functor.goodness;
      for (var i:uint = 0; i < NUM_STEPS; ++i) {
	functor.step();
	var newScore:Number = functor.goodness;
	if (newScore > score) {
	  trace("Quadrilateralise blew up! " + newScore + " > " + score);
	  return false;
	}
	score = newScore;
	if (score < TOLERANCE) {
	  break;
	}
      }

      functor.updateWay();
      return true;
    }

    private var way:Way;
    private var points:Array;
    
    // i wanted this to be private, but AS3 doesn't allow that. so please don't use it outside this package!
    public function Quadrilateralise(way_:Way) {
      way = way_;
      points = way.sliceNodes(0, way.length - 1).map(function (n:Node, i:int, a:Array) : Point {
	  return new Point(n.lon, n.latp);
	});
    }

    /**
     * returns the score of a particular corner, which is constructed so that all corners
     * which are straight lines or 90-degree corners score close to zero and other angles
     * score higher. The goal of this action is to minimise the sum of all scores.
     */
    private function scoreOf(a:Point, b:Point, c:Point):Number {
      var p:Point = a.subtract(b);
      var q:Point = c.subtract(b);
      p.normalize(1.0);
      q.normalize(1.0);
      var dotp:Number = p.x*q.x + p.y*q.y;
      // score is constructed so that +1, -1 and 0 are all scored 0, any other angle
      // is scored higher.
      var score:Number = 2.0 * Math.min(Math.abs(dotp-1.0), Math.min(Math.abs(dotp), Math.abs(dotp+1)));
      return score;
    }

    // get the goodness (sum of scores) of the whole way.
    private function get goodness():Number {
      var g:Number = 0.0;
      for (var i:uint = 1; i < points.length - 1; ++i) {
	var score:Number = scoreOf(points[i-1], points[i], points[i+1]);
	g += score;
      }
      var startScore:Number = scoreOf(points[points.length-1], points[0], points[1]);
      var endScore:Number = scoreOf(points[points.length-2], points[points.length-1], points[0]);
      g += startScore;
      g += endScore;
      return g;
    }

    /**
     * One step of the solver. Moves points towards their neighbours, or away from them, depending on 
     * the angle of that corner.
     */
    private function step():void {
      var motions:Array = points.map(function (b:Point, i:int, array:Array) : Point {
	  var a:Point = array[(i-1+array.length) % array.length];
	  var c:Point = array[(i+1) % array.length];
	  var p:Point = a.subtract(b);
	  var q:Point = c.subtract(b);
	  var scale:Number = p.length + q.length;
	  p.normalize(1.0);
	  q.normalize(1.0);
	  var dotp:Number = p.x*q.x + p.y*q.y;
	  // nasty hack to deal with almost-straight segments (angle is closer to 180 than to 90/270).
	  if (dotp < -0.707106781186547) {
	    dotp += 1.0;
	  }
	  var v:Point = p.add(q);
	  v.normalize(0.1 * dotp * scale);
	  return v;
	});
      for (var i:uint = 0; i < motions.length; ++i) {
	points[i] = points[i].add(motions[i]);
      }
    }

    /**
     * call this only when happy with the result - it writes the positions back to the
     * way, and hence to the DB or whatever.
     */
    private function updateWay():void {
      for (var i:uint = 0; i < points.length; ++i) {
	way.getNode(i).lon = points[i].x;
	way.getNode(i).latp = points[i].y;
      }
    }
  }
}
