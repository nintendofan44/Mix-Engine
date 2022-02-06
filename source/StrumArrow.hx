package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StrumArrow extends FlxSprite {
	public var resetAnim:Float = 0;
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside here

	private var noteData:Int = 0;
	private var player:Int;

	// Animation common suffixes
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function new(xx:Float, yy:Float, leData:Int, player:Int) {
		x = xx;
		y = yy;
		this.player = player;
		this.noteData = leData;
		super(x, y);
		reloadNote();
	}

	public function reloadNote() {
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;

		// defaults if no noteStyle was found in chart
		var noteTypeCheck:String = 'normal';

		if (PlayState.SONG.noteStyle == null) {
			switch (PlayState.storyWeek) {
				case 6:
					noteTypeCheck = 'pixel';
			}
		}
		else {
			noteTypeCheck = PlayState.SONG.noteStyle;
		}

		switch (noteTypeCheck) {
			case 'pixel':
				loadGraphic(Paths.image('pixelUI/Arrows-pixel'), true, 17, 17);
				animation.add('green', [6]);
				animation.add('red', [7]);
				animation.add('blue', [5]);
				animation.add('purplel', [4]);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
				antialiasing = false;

				animation.add('static', [noteData]);
				animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
				animation.add('confirm', [12 + noteData, 16 + noteData], 24, false);

				for (j in 0...4) {
					animation.add('dirCon' + j, [12 + j, 16 + j], 24, false);
				}

			default:
				frames = Paths.getSparrowAtlas('Arrows');
				for (j in 0...4) {
					animation.addByPrefix(dataColor[j], 'arrow' + dataSuffix[j]);
					animation.addByPrefix('dirCon' + j, dataSuffix[j].toLowerCase() + ' confirm', 24, false);
				}

				var lowerDir:String = dataSuffix[noteData].toLowerCase();

				animation.addByPrefix('static', 'arrow' + dataSuffix[noteData]);
				animation.addByPrefix('pressed', lowerDir + ' press', 24, false);
				animation.addByPrefix('confirm', lowerDir + ' confirm', 24, false);

				antialiasing = true;
				setGraphicSize(Std.int(width * 0.7));
		}
		updateHitbox();

		if (lastAnim != null) {
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if (!modifiedByLua)
			angle = localAngle + modAngle;
		else
			angle = modAngle;

		if (resetAnim > 0) {
			resetAnim -= elapsed;
			if (resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

		if (animation.curAnim.name == 'confirm' && !PlayState.curStage.startsWith("school")) {
			centerOrigin();
		}

		super.update(elapsed);

		if (FlxG.keys.justPressed.THREE) {
			localAngle += 10;
		}
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if (animation.curAnim.name == 'confirm' && !PlayState.curStage.startsWith("school")) {
			centerOrigin();
		}
	}
}
