#if desktop
package;

import lime.app.Application;
#if desktop
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import flixel.ui.FlxBar;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if desktop
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;

using StringTools;

class Caching extends MusicBeatState
{
	var toBeDone = 0;
	var done = 0;

	var loaded = false;

	var timeTxt:FlxText;
	var timeBarBG:AttachedSprite;
	var timeBar:FlxBar;

	var gfDance:FlxSprite;
	var danceLeft:Bool = false;

	public static var bitmapData:Map<String, FlxGraphic>;

	//var images = []; TO DO: eh
	var music = [];
	var charts = [];

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	override function create()
	{
		FlxG.sound.playMusic(Paths.music('breakfast', 'shared'), 0);
		FlxG.sound.music.fadeIn(2, 0, 0.55);

		bgColor = FlxColor.GRAY;

		//FlxG.game.focusLostFramerate = ClientPrefs.framerate;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;

		PlayerSettings.init();

		FlxG.mouse.visible = false;

		FlxG.worldBounds.set(0, 0);

		bitmapData = new Map<String, FlxGraphic>();

		timeTxt = new FlxText(0, 20, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.screenCenter(X);
		//timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.y = FlxG.height - 45;

		timeBarBG = new AttachedSprite('timeBar', 'shared');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		//timeBarBG.alpha = 0;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;

		#if desktop
		/*if (FlxG.save.data.cacheImages) TO DO: eh
		{
			// TODO: Refactor this to use OpenFlAssets.
			for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/characters")))
			{
				if (!i.endsWith(".png"))
					continue;
				images.push(i);
			}
			for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/noteskins")))
			{
				if (!i.endsWith(".png"))
					continue;
				images.push(i);
			}
		}*/

		// TODO: Get the song list from OpenFlAssets.
		music = Paths.listSongsToCache();
		#end

		toBeDone = /*Lambda.count(images) + */Lambda.count(music); // TO DO: eh

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'done', 0, toBeDone);
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBarBG.sprTracker = timeBar;

		add(gfDance);
		add(timeBarBG);
		add(timeBar);
		add(timeTxt);

		trace('started caching.');

		#if cpp
		// update thread

		sys.thread.Thread.create(() ->
		{
			while (!loaded)
			{
				if (toBeDone != 0 && done != toBeDone)
				{
					var alpha = Highscore.floorDecimal(done / toBeDone * 100, 2) / 100;
					timeTxt.text = "Loading.. | " + done + "/" + toBeDone;
				}
			}
		});

		// cache thread
		sys.thread.Thread.create(() ->
		{
			cache();
		});
		#end

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');
		KadeEngineData.initSave();

		Conductor.changeBPM(108);

		#if desktop
		DiscordClient.initialize();
		Application.current.onExit.add(function(exitCode) {
			DiscordClient.shutdown();
		});
		#end
	}

	var calledDone = false;

	override function update(elapsed)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	override function beatHit() {
		super.beatHit();

		if (gfDance != null) {
			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}
	}

	function cache()
	{
		#if desktop
		trace("LOADING: " + toBeDone + " OBJECTS.");

		/*for (i in images) TO DO: eh
		{
			var replaced = i.replace(".png", "");
			// var data:BitmapData = BitmapData.fromFile("assets/shared/images/characters/" + i);
			var imagePath = Paths.image('characters/$i', 'shared');
			var data = OpenFlAssets.getBitmapData(imagePath);
			var graph = FlxGraphic.fromBitmapData(data);
			graph.persist = true;
			graph.destroyOnNoUse = false;
			bitmapData.set(replaced, graph);
			done++;
		}*/

		for (i in music)
		{
			var inst = Paths.inst(i);
			if (Paths.doesSoundAssetExist(inst))
			{
				FlxG.sound.cache(inst);
			}

			var voices = Paths.voices(i);
			if (Paths.doesSoundAssetExist(voices))
			{
				FlxG.sound.cache(voices);
			}

			done++;
		}

		trace('finished caching.');

		loaded = true;

		//trace(OpenFlAssets.cache.hasBitmapData('GF_assets'));
		#end

		timeTxt.text = "Done!";

		new FlxTimer().start(1, function(tmr:FlxTimer) {
			FlxG.sound.music.stop();
			MusicBeatState.switchState(new TitleState());
		});
	}
}
#end