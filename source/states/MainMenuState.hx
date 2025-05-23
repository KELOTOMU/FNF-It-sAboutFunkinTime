package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import options.OptionsState;
import states.editors.MasterEditorMenu;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = ['story_mode', 'options', 'credits'];

	var selectorLeft:FlxSprite;
	var selectorRight:FlxSprite;

	var selectorLeftTween:FlxTween;
	var selectorRightTween:FlxTween;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		for (i in 1...3)
		{
			var layer:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/Layer$i'));
			layer.antialiasing = ClientPrefs.data.antialiasing;
			layer.scrollFactor.set();
			layer.setGraphicSize(1280, 720);
			layer.updateHitbox();
			layer.screenCenter();
			add(layer);
			if (i == 2)
				layer.blend = ADD;
		}

		var mic:FlxSprite = new FlxSprite(1000, 400).loadGraphic(Paths.image('mainmenu/mic'));
		mic.antialiasing = ClientPrefs.data.antialiasing;
		mic.setGraphicSize(mic.width * 0.7);
		mic.updateHitbox();
		mic.scrollFactor.set();
		add(mic);
		mic.angularVelocity = -20;
		FlxTween.tween(mic, {y: mic.y + 30}, 2.5, {ease: FlxEase.quadInOut, type: PINGPONG});

		var spirals:FlxSpriteGroup = new FlxSpriteGroup();
		add(spirals);

		var spiral1:FlxSprite = new FlxSprite(118, 534);
		spirals.add(spiral1);

		var spiral2:FlxSprite = new FlxSprite(119, 134);
		spirals.add(spiral2);

		var spiral3:FlxSprite = new FlxSprite(1114, 588);
		spirals.add(spiral3);

		spirals.forEach(function(spiral:FlxSprite)
		{
			for (i in 1...4)
				spiral.loadGraphic(Paths.image('mainmenu/spiral$i'));
			spiral.antialiasing = ClientPrefs.data.antialiasing;
			spiral.blend = ADD;
			spiral.angularVelocity = FlxG.random.int(-10, 10);
		});

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, ((i * 100) + offset) + 200).loadGraphic(Paths.image('mainmenu/menu_' + optionShit[i]));
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.setGraphicSize(Std.int(menuItem.width * 0.6));
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
		}

		for (i in 3...5)
		{
			var layer:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/Layer$i'));
			layer.antialiasing = false;
			layer.scrollFactor.set();
			layer.setGraphicSize(1280, 720);
			layer.updateHitbox();
			layer.screenCenter();
			add(layer);

			if (i == 3)
				layer.blend = ADD;
		}

		selectorLeft = new FlxSprite().loadGraphic(Paths.image('mainmenu/ArrowLeft'));
		selectorLeft.setGraphicSize(selectorLeft.width * 0.65);
		selectorLeft.updateHitbox();
		selectorLeft.offset.y -= 15;
		add(selectorLeft);
		selectorRight = new FlxSprite().loadGraphic(Paths.image('mainmenu/ArrowRight'));
		selectorRight.setGraphicSize(selectorRight.width * 0.65);
		selectorRight.updateHitbox();
		selectorRight.offset.y -= 15;
		add(selectorRight);

		var logo:FlxSprite = new FlxSprite(0, -FlxG.height).loadGraphic(Paths.image('mainmenu/Logo'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.scrollFactor.set();
		logo.setGraphicSize(logo.width * 0.65);
		logo.updateHitbox();
		logo.screenCenter(X);
		add(logo);
		new FlxTimer().start(0.5, function(tmr:FlxTimer) FlxTween.tween(logo, {y: 20}, 1, {ease: FlxEase.expoOut}));

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		Paths.music('freeplayMenu');

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;

					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (optionShit[curSelected])
						{
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());
								FlxG.sound.music.fadeOut();

							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end

							#if ACHIEVEMENTS_ALLOWED
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							#end

							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								MusicBeatState.switchState(new OptionsState());
								OptionsState.onPlayState = false;
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
									PlayState.stageUI = 'normal';
								}
						}
					});

					FlxFlicker.flicker(selectorLeft, 1, 0.1, false, false);
					FlxFlicker.flicker(selectorRight, 1, 0.1, false, false);

					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected)
							continue;
						FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								menuItems.members[i].kill();
							}
						});
					}
				}
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].updateHitbox();
		menuItems.members[curSelected].screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].centerOffsets();
		menuItems.members[curSelected].screenCenter(X);

		for (selected => item in menuItems)
		{
			if (selected == curSelected)
			{
				selectorLeft.screenCenter(X);
				selectorRight.screenCenter(X);
				selectorLeft.x -= item.width;
				selectorLeft.y = item.y;
				selectorRight.x += item.width;
				selectorRight.y = item.y;

				selectorLeftTween?.cancel();
				selectorRightTween?.cancel();

				selectorLeftTween = FlxTween.tween(selectorLeft, {x: selectorLeft.x + 10}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
				selectorRightTween = FlxTween.tween(selectorRight, {x: selectorRight.x - 10}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
			}
		}
	}

	override function destroy()
	{
		super.destroy();

		if (selectedSomethin && optionShit[curSelected] == 'freeplay')
		{
			FlxG.sound.playMusic(Paths.music('freeplayMenu'), 0);
			FlxG.sound.music.fadeIn();
		}
	}
}
