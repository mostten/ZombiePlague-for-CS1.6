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

#define MAXPLAYERS 32
#define SOUND_MAX_LENGTH 64
#define COUNTDOWN_MAX 10
#define ZP_INVALID_SOUND_ID -1

enum SoundType{
	SoundType_Start = 0,
	SoundType_Countdown
};

enum _:SoundInfo{
	SoundInfo_Mode = 0,
	SoundInfo_Index,
	SoundType:SoundInfo_Type
};

new g_zp_countdown;
new g_fZpGamemodDelay;
new g_iSecondsMax = COUNTDOWN_MAX;
new Array:g_sound_files;
new Array:g_sound_infos;

// 配置文件
new const ZP_SETTINGS_FILE[] = "zombieplague_mod_ghost.ini";

// 声音文件
new const sound_start_default[][] = {
	"zombie_plague/ghost/roundstart/other_roundstart.mp3"
};

new const message_phrase_en_default[] = "Biochemical virus is looking for host in %d seconds."
new const message_phrase_cn_default[] = "生化病毒正在寻找宿主, 剩余 %d 秒."

new zp_countdown_default[COUNTDOWN_MAX][] = 
{ 
	"zombie_plague/ghost/other/10.wav",
	"zombie_plague/ghost/other/9.wav",
	"zombie_plague/ghost/other/8.wav",
	"zombie_plague/ghost/other/7.wav",
	"zombie_plague/ghost/other/6.wav",
	"zombie_plague/ghost/other/5.wav",
	"zombie_plague/ghost/other/4.wav",
	"zombie_plague/ghost/other/3.wav",
	"zombie_plague/ghost/other/2.wav",
	"zombie_plague/ghost/other/1.wav"
};

public plugin_init()
{
	register_plugin("Countdown for zp", "1.0", "mostten");
	g_zp_countdown = register_cvar("zp_gamemode_countdown", "1");
	g_fZpGamemodDelay = get_cvar_pointer("zp_gamemode_delay");
}

public plugin_precache()
{
	SoundArraysInitialize();
	sounds_precache();
}

public plugin_natives()
{
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP50_CORE) || equal(module, LIBRARY_ZP50_GAMEMODES))
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
	if(get_pcvar_num(g_zp_countdown))
	{
		g_iSecondsMax = floatround(get_pcvar_float(g_fZpGamemodDelay));
		zp_roundstart_play(game_mode_id);
		zp_countdown_play(game_mode_id);
	}
}

public zp_countdown_play(game_mode_id)
{
	if(g_iSecondsMax > 0)
	{
		zp_countdown_second(game_mode_id, g_iSecondsMax);
		g_iSecondsMax--;
		set_task(1.0, "zp_countdown_play", game_mode_id);
	}
}

// 播放声音给所有玩家
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(0, "spk ^"%s^"", sound);
}

sounds_precache()
{
	for (new mode = 0; mode < zp_gamemodes_get_count(); mode++)
	{
		start_precache(mode);
		countdown_precache(mode);
	}
}

start_precache(mode)
{
	new modename[32], key[64];
	zp_gamemodes_get_name(mode, modename, charsmax(modename));
	new Array:sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	formatex(key, charsmax(key), "SOUNDS (%s)", modename);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Start Sounds", key, sounds);
	if (ArraySize(sounds) > 0)
	{
		// Precache ambience sounds
		for (new index = 0; index < ArraySize(sounds); index++)
		{
			new sound[SOUND_MAX_LENGTH];
			ArrayGetString(sounds, index, sound, charsmax(sound));
			AddSoundArrays(sound, mode, SoundType_Start);
		}
	}
	else
	{
		for (new index = 0; index < sizeof sound_start_default; index++)
		{
			ArrayPushString(sounds, sound_start_default[index]);
			AddSoundArrays(sound_start_default[index], mode, SoundType_Start);
		}
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Start Sounds", key, sounds);
	}
	ArrayDestroy(sounds);
}

countdown_precache(mode)
{
	new modename[32], key[64];
	zp_gamemodes_get_name(mode, modename, charsmax(modename));
	new Array:sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	formatex(key, charsmax(key), "SOUNDS (%s)", modename);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Countdown Sounds", key, sounds);
	if (ArraySize(sounds) > 0)
	{
		// Precache ambience sounds
		for (new index = 0; index < ArraySize(sounds); index++)
		{
			new sound[SOUND_MAX_LENGTH];
			ArrayGetString(sounds, index, sound, charsmax(sound));
			AddSoundArrays(sound, mode, SoundType_Countdown);
		}
	}
	else
	{
		for (new index = 0; index < sizeof zp_countdown_default; index++)
		{
			ArrayPushString(sounds, zp_countdown_default[index]);
			AddSoundArrays(zp_countdown_default[index], mode, SoundType_Countdown);
		}
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Countdown Sounds", key, sounds);
	}
	ArrayDestroy(sounds);
}

SoundArraysInitialize()
{
	if(g_sound_files == Invalid_Array)
		g_sound_files = ArrayCreate(SOUND_MAX_LENGTH, 1);
	if(g_sound_infos == Invalid_Array)
		g_sound_infos = ArrayCreate(SoundInfo, 1);
}

AddSoundArrays(sound[], gamemode, SoundType:sound_type)
{
	if(strlen(sound))
	{
		SoundArraysInitialize();
		
		new info[SoundInfo];
		info[SoundInfo_Mode] = gamemode;
		info[SoundInfo_Type] = _:sound_type;
		new index = GetSoundFileIndex(sound);
		if(index < 0)
		{
			if(equal(sound[strlen(sound)-4], ".mp3"))
			{
				new path[128];
				format(path, charsmax(path), "sound/%s", sound);
				precache_generic(path);
			}
			else
			{
				precache_sound(sound);
			}
			info[SoundInfo_Index] = ArraySize(g_sound_files);
			ArrayPushString(g_sound_files, sound);
		}
		else
		{
			info[SoundInfo_Index] = index;
		}
		ArrayPushArray(g_sound_infos, info);
		return info[SoundInfo_Index];
	}
	return ZP_INVALID_SOUND_ID;
}

GetSoundFileIndex(sound[])
{
	if(strlen(sound) && g_sound_files != Invalid_Array)
	{
		for(new index = 0; index < ArraySize(g_sound_files); index++)
		{
			new temp[SOUND_MAX_LENGTH];
			ArrayGetString(g_sound_files, index, temp, charsmax(temp));
			if(equal(sound, temp))
				return index;
		}
	}
	return ZP_INVALID_SOUND_ID;
}

bool:GetStartSound(gamemod, sound[])
{
	new bool:result = false;
	new Array:sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new count = GetSoundArray(gamemod, SoundType_Start, sounds);
	if(count > 0)
	{
		ArrayGetString(sounds, random_num(0, count - 1), sound, SOUND_MAX_LENGTH);
		result = strlen(sound) > 0;
	}
	ArrayDestroy(sounds);
	return result;
}

bool:GetCountdownSound(gamemod, second, sound[])
{
	new bool:result = false;
	if(second < 1)
		return result;
	new Array:sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new count = GetSoundArray(gamemod, SoundType_Countdown, sounds);
	if(count > 0 && second <= count)
	{
		ArrayGetString(sounds, count - second, sound, SOUND_MAX_LENGTH);
		result = strlen(sound) > 0;
	}
	ArrayDestroy(sounds);
	return result;
}

zp_roundstart_play(game_mode_id)
{
	// 播放幽灵声音
	new sound[SOUND_MAX_LENGTH];
	if(GetStartSound(game_mode_id, sound))
		PlaySoundToClients(sound);
}

zp_countdown_second(game_mode_id, second)
{
	new sound[SOUND_MAX_LENGTH];
	if(GetCountdownSound(game_mode_id, second, sound))
		PlaySoundToClients(sound);
	zp_message_show(game_mode_id, second);
}

zp_message_show(game_mode_id, second)
{
	new message_lang[128];
	get_message_lang(game_mode_id, message_lang, charsmax(message_lang));
	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		if(is_user_connected(client) && !is_user_bot(client))
			client_print(client, print_center, "%L", client, message_lang, second);
	}
}

get_message_lang(game_mode_id, message_lang[], maxsize)
{
	new modename[32];
	zp_gamemodes_get_name(game_mode_id, modename, charsmax(modename));
	formatex(message_lang, maxsize, "ROUND_COUNTDOWN (%s)", modename);
	if(GetLangTransKey(message_lang) == TransKey_Bad)
	{
		new TransKey:key = CreateLangKey(message_lang);
		AddTranslation("en", key, message_phrase_en_default);
		AddTranslation("cn", key, message_phrase_cn_default);
	}
}

GetSoundArray(gamemod, SoundType:sound_type, &Array:sounds)
{
	if(sounds != Invalid_Array && g_sound_infos != Invalid_Array && g_sound_files != Invalid_Array)
	{
		for (new i = 0; i < ArraySize(g_sound_infos); i++)
		{
			new sound_info[SoundInfo];
			ArrayGetArray(g_sound_infos, i, sound_info);
			if(sound_info[SoundInfo_Mode] == gamemod && sound_info[SoundInfo_Type] == sound_type && sound_info[SoundInfo_Index] >= 0 && sound_info[SoundInfo_Index] < ArraySize(g_sound_files))
			{
				new sound[SOUND_MAX_LENGTH];
				ArrayGetString(g_sound_files, sound_info[SoundInfo_Index], sound, charsmax(sound));
				if(strlen(sound))
					ArrayPushString(sounds, sound);
			}
		}
		return ArraySize(sounds);
	}
	return 0;
}