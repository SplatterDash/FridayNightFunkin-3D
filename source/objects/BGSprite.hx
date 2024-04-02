package objects;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;
	private var danced:Bool = false;
	private var alts:Bool = false;
	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false) {
		super(x, y);

		if (animArray != null) {
			frames = Paths.getSparrowAtlas(image);
			for (i in 0...animArray.length) {
				var anim:String = animArray[i];
				animation.addByPrefix(anim.toLowerCase(), anim, 24, loop);
				if(idleAnim == null) {
					if(anim.trim().substr(anim.length - 4).toLowerCase() == 'left' || anim.trim().substr(anim.length - 5).toLowerCase() == 'right') {
						idleAnim = (anim.trim().substr(anim.length - 4).toLowerCase() == 'left' ? anim.trim().substr(0, anim.length - 4) : anim.trim().substr(0, anim.length - 5));
						alts = true;
					} else idleAnim = anim;
					animation.play(anim);
				}
			}
		} else {
			if(image != null) {
				loadGraphic(Paths.image(image));
			}
			active = false;
		}
		scrollFactor.set(scrollX, scrollY);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function dance(?forceplay:Bool = false) {
		if(idleAnim != null) {
			if(alts) {
				animation.play(idleAnim + (danced ? 'left' : 'right'), forceplay);
				danced = !danced;
			}
			else animation.play(idleAnim, forceplay);
		}
	}
}