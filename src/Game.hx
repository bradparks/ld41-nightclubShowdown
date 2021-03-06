import mt.Process;
import mt.deepnight.Tweenie;
import mt.MLib;
import hxd.Key;

typedef HistoryEntry = { t:Int, a:en.Hero.Action } ;

class Game extends mt.Process {
	public static var ME : Game;
	public var scroller : h2d.Layers;
	public var vp : Viewport;
	public var fx : Fx;
	public var level : Level;
	public var hero : en.Hero;
	var clickTrap : h2d.Interactive;
	public var waveId : Int;

	public var isReplay : Bool;
	public var heroHistory : Array<HistoryEntry>;

	public var hud : h2d.Flow;

	public var cm : mt.deepnight.Cinematic;

	public function new(ctx:h2d.Sprite, replayHistory:Array<HistoryEntry>) {
		super(Main.ME);

		ME = this;
		createRoot(ctx);

		if( replayHistory!=null ) {
			isReplay = true;
			heroHistory = replayHistory.copy();
		}
		else {
			heroHistory = [];
			isReplay = false;
		}

		cm = new mt.deepnight.Cinematic(Const.FPS);
		//Console.ME.runCommand("+ bounds");

		scroller = new h2d.Layers(root);
		vp = new Viewport();
		fx = new Fx();

		clickTrap = new h2d.Interactive(1,1,Main.ME.root);
		//clickTrap.backgroundColor = 0x4400FF00;
		clickTrap.onPush = onMouseDown;
		//clickTrap.enableRightButton = true;


		hud = new h2d.Flow();
		root.add(hud, Const.DP_UI);
		hud.horizontalSpacing = 1;

		waveId = -1;
		//#if debug
		//waveId = 5;
		//#end
		level = new Level();
		level.render(0);
		hero = new en.Hero(2,4);

		//#if !debug
		logo();
		if( !Main.ME.cd.hasSetS("intro",Const.INFINITE) ) {
			cd.setS("lockNext",5);
			//cd.setS("lockNext",99999);
			delayer.addS( function() {
				announce("A fast turned-based action game",0x706ACC);
			}, 1);
		}
		//#end

		// Testing
		#if debug
		{
			//cd.setS("lockNext",Const.INFINITE);
			//new en.Cover(5,4);
			//new en.Cover(10,4);
			////new en.m.Grenader(16,4);
			//new en.m.BasicGun(12,4);
			//new en.m.BasicGun(2,4);
			//level.waveMobCount = en.Mob.ALL.length;
		}
		#end

		vp.repos();

		onResize();
	}

	//function updateWave() {
		//var n = 0;
		//for(e in en.Cover.ALL)
			//if( e.isAlive() )
				//n++;
		//for(i in n...2) {
			//var e = new en.Cover(10,0);
		//}
	//}

	public function updateHud() cd.setS("invalidateHud",Const.INFINITE);
	function _updateHud() {
		if( !cd.has("invalidateHud") )
			return;

		hud.removeChildren();
		cd.unset("invalidateHud");


		for( i in 0...MLib.min(hero.maxLife,6) ) {
			var e = Assets.gameElements.h_get("iconHeart", hud);
			e.colorize(i+1<=hero.life ? 0xFFFFFF : 0xFF0000);
			e.alpha = i+1<=hero.life ? 1 : 0.8;
			e.blendMode = Add;
		}

		hud.addSpacing(4);

		for( i in 0...hero.maxAmmo ) {
			var e = Assets.gameElements.h_get("iconBullet", hud);
			e.colorize(i+1<=hero.ammo ? 0xFFFFFF : 0xFF0000);
			e.alpha = i+1<=hero.ammo ? 1 : 0.8;
			e.blendMode = Add;
		}

		onResize();

	}

	function onMouseDown(ev:hxd.Event) {
		var m = getMouse();
		for(e in Entity.ALL)
			e.onClick(m.x, m.y, ev.button);
	}

	override public function onResize() {
		super.onResize();
		clickTrap.width = w();
		clickTrap.height = h();
		hud.x = Std.int( w()*0.5/Const.SCALE - hud.outerWidth*0.5 );
		hud.y = Std.int( level.hei*Const.GRID + 4 );
	}

	override public function onDispose() {
		super.onDispose();

		cm.destroy();

		for(e in Entity.ALL)
			e.destroy();
		gc();

		if( ME==this )
			ME = null;
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
		_updateHud();
	}

	public function getMouse() {
		var gx = hxd.Stage.getInstance().mouseX;
		var gy = hxd.Stage.getInstance().mouseY;
		var x = Std.int( gx/Const.SCALE-scroller.x );
		var y = Std.int( gy/Const.SCALE-scroller.y );
		return {
			x : x,
			y : y,
			cx : Std.int(x/Const.GRID),
			cy : Std.int(y/Const.GRID),
		}
	}

	public function logo() {
		var e = Assets.gameElements.h_get("logo",root);
		e.y = 30;
		e.colorize(0x3D65C2);
		e.blendMode = Add;
		tw.createMs(e.x, 500|-e.tile.width>12, 250).onEnd = function() {
			var d = 5000;
			tw.createMs(e.alpha, d|0, 1500).onEnd = e.remove;
		}

	}

	public function announce(txt:String, ?c=0xFFFFFF, ?permanent=false) {
		var tf = new h2d.Text(Assets.font,root);
		tf.text = txt;
		tf.textColor = c;
		tf.y = Std.int( 58 - tf.textHeight );
		tw.createMs(tf.x, 500|-tf.textWidth>12, 200).onEnd = function() {
			if( !permanent ) {
				var d = 1000+txt.length*75;
				tw.createMs(tf.alpha, d|0, 1500).onEnd = tf.remove;
			}
		}
	}

	var lastNotif : Null<h2d.Text>;
	public function notify(txt:String, ?c=0xFFFFFF) {
		if( lastNotif!=null )
			lastNotif.remove();

		var tf = new h2d.Text(Assets.font,root);
		lastNotif = tf;
		tf.text = txt;
		tf.textColor = c;
		tf.y = Std.int( 100 - tf.textHeight );
		tw.createMs(tf.x, -tf.textWidth>12, 200).onEnd = function() {
			var d = 650+txt.length*75;
			tw.createMs(tf.alpha, d|0, 1500).onEnd = function() {
				tf.remove();
				if( lastNotif==tf )
					lastNotif = null;
			}
		}
	}

	public function nextLevel() {
		waveId++;
		level.render(waveId);
		level.waveMobCount = 1;
		if( waveId>6 )
			announce("Thank you for playing ^_^\nA 20h game by Sebastien Benard\ndeepnight.net",true);
		else {
			announce("Wave "+(waveId+1)+"...", 0xFFD11C);
			delayer.addS(function() {
				announce("          Fight!", 0xEF4810);
			}, 0.5);
			delayer.addS(function() {
				level.attacheWaveEntities(waveId);
			}, waveId==0 ? 1 : 1);
		}

	}

	public function isSlowMo() {
		#if debug
		if( Key.isDown(Key.SHIFT) )
			return false;
		#end
		if( isReplay || !hero.isAlive() || hero.controlsLocked() )
			return false;

		for(e in en.Mob.ALL)
			if( e.isAlive() && e.canBeShot() )
				return true;

		return false;
	}

	public function getSlowMoDt() {
		return isSlowMo() ? dt*Const.PAUSE_SLOWMO : dt;
	}

	public function getSlowMoFactor() {
		return isSlowMo() ? Const.PAUSE_SLOWMO : 1;
	}

	override public function update() {
		cm.update(dt);

		super.update();

		// Updates
		for(e in Entity.ALL) {
			e.setDt(dt);
			if( !e.destroyed ) e.preUpdate();
			if( !e.destroyed ) e.update();
			if( !e.destroyed ) e.postUpdate();
		}
		gc();

		if( !cd.has("lockNext") && level.waveMobCount<=0 )
			nextLevel();

		if( Main.ME.keyPressed(hxd.Key.ESCAPE) )
			Main.ME.restartGame();

		if( Main.ME.keyPressed(Key.X) && Key.isDown(Key.CTRL) ) {
			Main.ME.cd.unset("intro");
			Assets.music.stop();
			Main.ME.restartGame();
		}

		if( Main.ME.keyPressed(hxd.Key.S) ) {
			notify("Sounds: "+(mt.deepnight.Sfx.isMuted(0) ? "ON" : "off"));
			mt.deepnight.Sfx.toggleMuteGroup(0);
			Assets.SBANK.grunt0().playOnGroup(0);
		}

		if( Main.ME.keyPressed(hxd.Key.M) ) {
			notify("Music: "+(mt.deepnight.Sfx.isMuted(1) ? "ON" : "off"));
			mt.deepnight.Sfx.toggleMuteGroup(1);
		}

		if( isReplay && heroHistory.length>0 && itime>=heroHistory[0].t )
			hero.executeAction(heroHistory.shift().a);
	}
}
