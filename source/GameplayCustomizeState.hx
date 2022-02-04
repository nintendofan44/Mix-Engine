import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.FlxObject;
#if windows
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.ui.Keyboard;
import flixel.FlxSprite;
import flixel.FlxG;

class GameplayCustomizeState extends MusicBeatState {
	var defaultX:Float = FlxG.width * 0.55 - 135;
	var defaultY:Float = FlxG.height / 2 - 50;

	var background:FlxSprite;
	var curt:FlxSprite;
	var front:FlxSprite;

	var sick:FlxSprite;

	var text:FlxText;
	var blackBorder:FlxSprite;

	var bf:Boyfriend;
	var dad:Character;

	var strumLine:FlxSprite;
	var strumLineNotes:FlxTypedGroup<StaticArrow>;
	var playerStrums:FlxTypedGroup<StaticArrow>;
	private var camHUD:FlxCamera;

	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public override function create() {
		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Customizing Gameplay", null);
		#end

		sick = new FlxSprite().loadGraphic(Paths.image('sick', 'shared'));
		sick.scrollFactor.set();
		background = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
		curt = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', 'shared'));
		front = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));

		//Conductor.changeBPM(102);
		persistentUpdate = true;

		super.create();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		background.scrollFactor.set(0.9, 0.9);
		curt.scrollFactor.set(0.9, 0.9);
		front.scrollFactor.set(0.9, 0.9);

		add(background);
		add(front);
		add(curt);

		var camFollow = new FlxObject(0, 0, 1, 1);

		dad = new Character(100, 100, 'dad');

		bf = new Boyfriend(770, 450, 'bf');

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x + 400, dad.getGraphicMidpoint().y);

		camFollow.setPosition(camPos.x, camPos.y);

		add(bf);
		add(dad);

		add(sick);

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = 0.9;
		FlxG.camera.focusOn(camFollow.getPosition());

		strumLine = new FlxSprite(0, FlxG.save.data.strumline).makeGraphic(FlxG.width, 14);
		strumLine.scrollFactor.set();
		strumLine.alpha = 0.4;

		add(strumLine);

		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<StaticArrow>();

		sick.cameras = [camHUD];
		strumLine.cameras = [camHUD];
		playerStrums.cameras = [camHUD];

		generateStaticArrows(0);
		generateStaticArrows(1);

		text = new FlxText(5, FlxG.height + 40, 0, "Drag around gameplay elements, R to reset, Escape to go back.", 12);
		text.scrollFactor.set();
		text.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		blackBorder = new FlxSprite(-30, FlxG.height + 40).makeGraphic((Std.int(text.width + 900)), Std.int(text.height + 600), FlxColor.BLACK);
		blackBorder.alpha = 0.5;

		add(blackBorder);

		add(text);

		FlxTween.tween(text, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});
		FlxTween.tween(blackBorder, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});

		if (!FlxG.save.data.changedHit) {
			FlxG.save.data.changedHitX = defaultX;
			FlxG.save.data.changedHitY = defaultY;
		}

		sick.x = FlxG.save.data.changedHitX;
		sick.y = FlxG.save.data.changedHitY;

		FlxG.mouse.visible = true;
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		FlxG.camera.zoom = FlxMath.lerp(0.9, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);

		if (FlxG.mouse.overlaps(sick) && FlxG.mouse.pressed) {
			sick.x = FlxG.mouse.x - sick.width / 2;
			sick.y = FlxG.mouse.y - sick.height;
		}

		for (i in playerStrums)
			i.y = strumLine.y;
		for (i in strumLineNotes)
			i.y = strumLine.y;

		if (FlxG.mouse.overlaps(sick) && FlxG.mouse.justReleased) {
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = true;
		}

		if (FlxG.keys.justPressed.R) {
			sick.x = defaultX;
			sick.y = defaultY;
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = false;
		}

		if (controls.BACK) {
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new OptionsMenu());
		}
	}

	override function beatHit() {
		super.beatHit();

		bf.playAnim('idle');
		dad.dance();

		FlxG.camera.zoom += 0.015;
		camHUD.zoom += 0.010;

		trace('beat');
	}

	// ripped from play state cuz im lazy

	private function generateStaticArrows(player:Int):Void {
		for (i in 0...4) {
			// FlxG.log.add(i);
			var babyArrow:StaticArrow = new StaticArrow(0, strumLine.y);

			babyArrow.frames = Paths.getSparrowAtlas('Arrows', 'shared');
			for (j in 0...4) {
				babyArrow.animation.addByPrefix(dataColor[j], 'arrow' + dataSuffix[j]);
				babyArrow.animation.addByPrefix('dirCon' + j, dataSuffix[j].toLowerCase() + ' confirm', 24, false);
			}

			var lowerDir:String = dataSuffix[i].toLowerCase();

			babyArrow.animation.addByPrefix('static', 'arrow' + dataSuffix[i]);
			babyArrow.animation.addByPrefix('pressed', lowerDir + ' press', 24, false);
			babyArrow.animation.addByPrefix('confirm', lowerDir + ' confirm', 24, false);

			babyArrow.x += Note.swagWidth * i;

			babyArrow.antialiasing = true;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.ID = i;

			if (player == 1)
				playerStrums.add(babyArrow);

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}
}
