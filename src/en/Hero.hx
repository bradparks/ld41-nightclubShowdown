package en;

import mt.MLib;
import mt.deepnight.*;
import mt.heaps.slib.*;

class Hero extends Entity {
	public var target : FPoint;

	public function new(x,y) {
		super(x,y);

		var g = new h2d.Graphics(spr);
		g.beginFill(0x00FF00,1);
		g.drawCircle(0,-radius,radius);

		//initLife(3);
		isAffectBySlowMo = false;
		initLife(Const.INFINITE);
		target = new FPoint(footX, footY);


		// Blind shot
		var s = createSkill("blind");
		s.setTimers(0.2,0,0.1);
		s.onStart = function() setLabel("preparing...");
		s.onProgress = function(t) setLabel("preparing "+Std.int(t*100)+"%");
		s.onInterrupt = function() setLabel("CANCEL!");
		s.onExecute = function(e) {
			dy = -0.1;
			e.hit(1);
			e.dx*=0.3;
			e.dx+=dirTo(e)*rnd(0.06,0.10);
			e.lockMovementsS(0.3);
			e.lockControlsS(0.7);
			setLabel("bang!");
		}
	}

	override function onTouchWall(wallDir:Int) {
		dx = -wallDir*MLib.fabs(dx);
	}

	override public function controlsLocked() {
		for(s in skills)
			if( s.isCharging() )
				return true;

		return super.controlsLocked() || target!=null || !onGround;
	}

	override public function onClick(x:Float, y:Float, bt) {
		super.onClick(x, y, bt);

		if( controlsLocked() )
			return;

		switch(bt) {
			case 0 :
				target = new FPoint(x,footY);

				case 1 :
					var dh = new DecisionHelper(en.Mob.ALL);
					dh.remove( function(e) return e.distPxFree(x,y)>=30 );
					dh.score( function(e) return -e.distPxFree(x,y) );
					var e = dh.getBest();
					if( e!=null && getSkill("blind").isReady() )
						getSkill("blind").prepareOn(e);
			}

	}

	override public function update() {
		super.update();

		if( target!=null && !movementLocked() )
			if( MLib.fabs(centerX-target.x)<=5 ) {
				target = null;
				dx*=0.5;
			}
			else {
				var s = 0.02;
				if( target.x>centerX ) {
					dir = 1;
					dx+=s;
				}
				if( target.x<centerX ) {
					dir = -1;
					dx-=s;
				}
			}
	}
}