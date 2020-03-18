/*================================================================================
	
	-----------------------------------
	-*- [ZP] Ghost: Round: Countdown -*-
	-----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/
#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#define LIBRARY_ZP50_CORE "zp50_core"
#include <zp50_core>
#define LIBRARY_ZP50_GAMEMODES "zp50_gamemodes"
#include <zp50_gamemodes>
#define LIBRARY_CLASS_GHOST "zp50_class_ghost"
#include <zp50_class_ghost>

#define MAXPLAYERS 32
#define SOUND_MAX_LENGTH 64
#define COUNTDOWN_MAX 10

new g_varCountdown;
new g_varOtherCountdown;
new g_fZpGamemodDelay;
new g_iSecondsMax = COUNTDOWN_MAX;
new g_bIsGhostMod = false;
new Array:g_sound_ghost_start;
new Array:g_sound_other_start;
new Array:g_sound_ghost_countdown;
new Array:g_sound_other_countdown;

// 配置文件
new const ZP_SETTINGS_FILE[] = "zombieplague_mod_ghost.ini";

// 声音文件
new const sound_ghost_start[][] = {
	"zombie_plague/ghost/roundstart/ghost_roundstart.mp3"
};

new const sound_other_start[][] = {
	"zombie_plague/ghost/roundstart/other_roundstart.mp3"
};

new zp_sounds_ghost_countdown[COUNTDOWN_MAX][] = 
{ 
	"zombie_plague/ghost/countdown/1.wav",
	"zombie_plague/ghost/countdown/2.wav",
	"zombie_plague/ghost/countdown/3.wav",
	"zombie_plague/ghost/countdown/4.wav",
	"zombie_plague/ghost/countdown/5.wav",
	"zombie_plague/ghost/countdown/6.wav",
	"zombie_plague/ghost/countdown/7.wav",
	"zombie_plague/ghost/countdown/8.wav",
	"zombie_plague/ghost/countdown/9.wav",
	"zombie_plague/ghost/countdown/10.wav"
};

new zp_sounds_other_countdown[COUNTDOWN_MAX][] = 
{ 
	"zombie_plague/ghost/other/1.wav",
	"zombie_plague/ghost/other/2.wav",
	"zombie_plague/ghost/other/3.wav",
	"zombie_plague/ghost/other/4.wav",
	"zombie_plague/ghost/other/5.wav",
	"zombie_plague/ghost/other/6.wav",
	"zombie_plague/ghost/other/7.wav",
	"zombie_plague/ghost/other/8.wav",
	"zombie_plague/ghost/other/9.wav",
	"zombie_plague/ghost/other/10.wav"
};

public plugin_init()
{
	register_plugin("Countdown for zp's ghost mod", "1.0", "mostten");
	g_varCountdown = register_cvar("ghost_mod_countdown", "1");
	g_varOtherCountdown = register_cvar("other_mod_countdown", "1");
	g_fZpGamemodDelay = get_cvar_pointer("zp_gamemode_delay");
}

public plugin_precache()
{
	// 初始化数组
	g_sound_ghost_start = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_sound_other_start = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_sound_ghost_countdown = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_sound_other_countdown = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	// 载入外部文件
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND GHOST START", g_sound_ghost_start);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND OTHER START", g_sound_other_start);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND GHOST COUNTDOWN", g_sound_ghost_countdown);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND OTHER COUNTDOWN", g_sound_other_countdown);
	
	// 如果不能载入自定义声音文件, 使用默认文件
	new index;
	if(ArraySize(g_sound_ghost_start) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_start; index++)
			ArrayPushString(g_sound_ghost_start, sound_ghost_start[index]);
		
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND GHOST START", g_sound_ghost_start);
	}
	if(ArraySize(g_sound_other_start) == 0)
	{
		for (index = 0; index < sizeof sound_other_start; index++)
			ArrayPushString(g_sound_other_start, sound_other_start[index]);
		
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND OTHER START", g_sound_other_start);
	}
	if(ArraySize(g_sound_ghost_countdown) == 0)
	{
		for (index = 0; index < sizeof zp_sounds_ghost_countdown; index++)
			ArrayPushString(g_sound_ghost_countdown, zp_sounds_ghost_countdown[index]);
		
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND GHOST COUNTDOWN", g_sound_ghost_countdown);
	}
	if(ArraySize(g_sound_other_countdown) == 0)
	{
		for (index = 0; index < sizeof zp_sounds_other_countdown; index++)
			ArrayPushString(g_sound_other_countdown, zp_sounds_other_countdown[index]);
		
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND OTHER COUNTDOWN", g_sound_other_countdown);
	}
	
	// 缓存声音文件
	new sound[SOUND_MAX_LENGTH];
	for (index = 0; index < ArraySize(g_sound_ghost_start); index++)
	{
		ArrayGetString(g_sound_ghost_start, index, sound, charsmax(sound));
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound);
			precache_generic(sound);
		}
		else
			precache_sound(sound);
	}
	for (index = 0; index < ArraySize(g_sound_other_start); index++)
	{
		ArrayGetString(g_sound_other_start, index, sound, charsmax(sound));
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound);
			precache_generic(sound);
		}
		else
			precache_sound(sound);
	}
	for (index = 0; index < ArraySize(g_sound_ghost_countdown); index++)
	{
		ArrayGetString(g_sound_ghost_countdown, index, sound, charsmax(sound));
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound);
			precache_generic(sound);
		}
		else
			precache_sound(sound);
	}
	for (index = 0; index < ArraySize(g_sound_other_countdown); index++)
	{
		ArrayGetString(g_sound_other_countdown, index, sound, charsmax(sound));
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound);
			precache_generic(sound);
		}
		else
			precache_sound(sound);
	}
}

public plugin_natives()
{
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP50_CORE) || equal(module, LIBRARY_ZP50_GAMEMODES) || equal(module, LIBRARY_CLASS_GHOST))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, skipchecks)
{
	g_bIsGhostMod = (LibraryExists(LIBRARY_CLASS_GHOST, LibType_Library) && game_mode_id == zp_gamemodes_get_id("Ghost Mode"));
	if(get_pcvar_num(g_varCountdown) || get_pcvar_num(g_varOtherCountdown))
	{
		g_iSecondsMax = floatround(get_pcvar_float(g_fZpGamemodDelay));
		zp_roundstart_play();
		zp_countdown_play();
	}
}

public zp_fw_gamemodes_end()
{
	g_bIsGhostMod = false;
}

zp_roundstart_play()
{
	// 播放幽灵声音
	new sound[SOUND_MAX_LENGTH];
	if(g_bIsGhostMod && get_pcvar_num(g_varCountdown))
	{
		ArrayGetString(g_sound_ghost_start, random_num(0, ArraySize(g_sound_ghost_start) - 1), sound, charsmax(sound));
		PlaySoundToClients(sound);
	}
	else if(!g_bIsGhostMod && get_pcvar_num(g_varOtherCountdown))
	{
		ArrayGetString(g_sound_other_start, random_num(0, ArraySize(g_sound_other_start) - 1), sound, charsmax(sound));
		PlaySoundToClients(sound);
	}
}

public zp_countdown_play()
{
	if(g_iSecondsMax > 0)
	{
		if(zp_countdown_second(g_iSecondsMax))
			g_iSecondsMax--;
		set_task(1.0, "zp_countdown_play");
	}
}

bool:zp_countdown_second(second)
{
	if(0 < second <= sizeof zp_sounds_ghost_countdown)
	{
		new index = second - 1;
		new sound[SOUND_MAX_LENGTH];
		if(g_bIsGhostMod && get_pcvar_num(g_varCountdown))
		{
			ArrayGetString(g_sound_ghost_countdown, index, sound, charsmax(sound));
		}
		else if(!g_bIsGhostMod && get_pcvar_num(g_varOtherCountdown))
		{
			ArrayGetString(g_sound_other_countdown, index, sound, charsmax(sound));
		}
		PlaySoundToClients(sound);
		zp_message_show(second);
		return true;
	}
	return false;
}

// 播放声音给所有玩家
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(0, "spk ^"%s^"", sound);
}

zp_message_show(second)
{
	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		if(is_user_connected(client) && !is_user_bot(client))
		{
			if(g_bIsGhostMod && get_pcvar_num(g_varCountdown))
			{
				client_print(client, print_center, "%L", client, "GHOST_ROUND_COUNTDOWN", second);
			}
			else if(!g_bIsGhostMod && get_pcvar_num(g_varOtherCountdown))
			{
				client_print(client, print_center, "%L", client, "OTHER_ROUND_COUNTDOWN", second);
			}
		}
	}
}