import mt.Process;
import mt.MLib;

class Game extends mt.Process {
	public static var ME : Game;
	public var scroller : h2d.Layers;
	//public var vp : Viewport;
	//public var fx : Fx;
	public var level : Level;
	public var hero : en.Hero;

	public function new(ctx:h2d.Sprite) {
		super(Main.ME);

		ME = this;
		createRoot(ctx);

		trace("new game");

		scroller = new h2d.Layers(root);
		//vp = new Viewport();
		//fx = new Fx();

		level = new Level();

		hero = new en.Hero(5,0);
		new en.m.GunGuy(8,0);

		//vp.target = hero;
		//vp.repos();
	}

	override public function onDispose() {
		super.onDispose();
		trace("game killed");
		if( ME==this )
			ME = null;
		for(e in Entity.ALL)
			e.destroy();
		gc();
	}

	function gc() {
		var i = 0;
		while( i<Entity.ALL.length )
			if( Entity.ALL[i].destroyed )
				Entity.ALL[i].dispose();
			else
				i++;
	}

	override function postUpdate() {
		super.postUpdate();
	}

	public function getMouse() {
		var gx = hxd.Stage.getInstance().mouseX;
		var gy = hxd.Stage.getInstance().mouseY;
		var x = (gx-scroller.x)/Const.SCALE;
		var y = (gy-scroller.y)/Const.SCALE;
		return {
			x : x,
			y : y,
			cx : Std.int(x/Const.GRID),
			cy : Std.int(y/Const.GRID),
		}
	}

	override public function update() {
		super.update();

		// Updates
		for(e in Entity.ALL) {
			@:privateAccess e.dt = dt;
			if( !e.destroyed ) e.preUpdate();
			if( !e.destroyed ) e.update();
			if( !e.destroyed ) e.postUpdate();
		}
		gc();

		if( Main.ME.keyPressed(hxd.Key.R) )
			Main.ME.restartGame();
	}
}
