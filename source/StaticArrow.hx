package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class StaticArrow extends FlxSprite {
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside here

	public function new(xx:Float, yy:Float) {
		x = xx;
		y = yy;
		super(x, y);
		updateHitbox();
	}

	override function update(elapsed:Float) {
		if (!modifiedByLua)
			angle = localAngle + modAngle;
		else
			angle = modAngle;

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
