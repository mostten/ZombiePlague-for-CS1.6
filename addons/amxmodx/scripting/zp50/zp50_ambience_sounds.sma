/*================================================================================
	
	----------------------------
	-*- [ZP] Ambience Sounds -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <zp50_gamemodes>

#define TASK_AMBIENCESOUNDS 100
#define SOUND_MAX_LENGTH 64
#define ZP_INVALID_SOUND_ID -1

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

enum _:SoundInfo{
	SoundInfo_Mode = 0,
	SoundInfo_Index,
	SoundInfo_Duration
};

// 声音文件
new const sounds_default[][] = {
	"zombie_plague/ambience.wav"
}
new const durations_default[] = {
	17
}

new Array:g_ambience_sounds;
new Array:g_ambience_infos;

public plugin_init()
{
	register_plugin("[ZP] Ambience Sonds", ZP_VERSION_STRING, "ZP Dev Team rewrite by mostten");
	register_event("30", "event_intermission", "a");
}

public plugin_precache()
{
	SoundArraysInitialize();
	
	new modename[32], key[64];
	for (new index = 0; index < zp_gamemodes_get_count(); index++)
	{
		zp_gamemodes_get_name(index, modename, charsmax(modename));
		
		new Array:ambience_sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
		formatex(key, charsmax(key), "SOUNDS (%s)", modename);
		amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_sounds);
		if (ArraySize(ambience_sounds) > 0)
		{
			// Precache ambience sounds
			for (new sound_index = 0; sound_index < ArraySize(ambience_sounds); sound_index++)
			{
				new sound[SOUND_MAX_LENGTH];
				ArrayGetString(ambience_sounds, sound_index, sound, charsmax(sound));
				AddSoundArrays(sound, index, 0);
			}
		}
		else
		{
			for (new sound_index = 0; sound_index < sizeof sounds_default; sound_index++)
			{
				ArrayPushString(ambience_sounds, sounds_default[sound_index]);
				AddSoundArrays(sounds_default[sound_index], index, 0);
			}
			// 存储至外部文件
			amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_sounds);
		}
		ArrayDestroy(ambience_sounds);
		
		new Array:ambience_durations = ArrayCreate(1, 1);
		formatex(key, charsmax(key), "DURATIONS (%s)", modename);
		amx_load_setting_int_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_durations);
		if (ArraySize(ambience_durations) > 0)
		{
			for (new duration_index = 0; duration_index < ArraySize(ambience_durations); duration_index++)
			{
				new duration = ArrayGetCell(ambience_durations, duration_index);
				SetSoundDuration(index, duration_index, duration);
			}
		}
		else
		{
			for (new duration_index = 0; duration_index < sizeof durations_default; duration_index++)
			{
				ArrayPushCell(ambience_durations, durations_default[duration_index]);
				SetSoundDuration(index, duration_index, durations_default[duration_index]);
			}
			// 存储至外部文件
			amx_save_setting_int_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_durations);
		}
		ArrayDestroy(ambience_durations);
	}
}

// Event Map Ended
public event_intermission()
{
	// Remove ambience sounds task
	remove_task(TASK_AMBIENCESOUNDS);
}

public zp_fw_gamemodes_end()
{
	// Stop ambience sounds
	remove_task(TASK_AMBIENCESOUNDS);
}

public zp_fw_gamemodes_start()
{
	// Start ambience sounds after a mode begins
	remove_task(TASK_AMBIENCESOUNDS);
	set_task(2.0, "ambience_sound_effects", TASK_AMBIENCESOUNDS);
}

// Ambience Sound Effects Task
public ambience_sound_effects(taskid)
{
	// Play a random sound depending on game mode
	new sound[SOUND_MAX_LENGTH];
	new current_game_mode = zp_gamemodes_get_current();
	if(current_game_mode >= 0)
	{
		// Play it on clients
		new duration = GetModeRandomSound(current_game_mode, sound);
		if(strlen(sound))
			PlaySoundToClients(sound);
		if(duration > 0)
		{
			// Set the task for when the sound is done playing
			set_task(float(duration), "ambience_sound_effects", TASK_AMBIENCESOUNDS)
		}
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(0, "spk ^"%s^"", sound);
}

SoundArraysInitialize()
{
	if(g_ambience_sounds == Invalid_Array)
		g_ambience_sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	if(g_ambience_infos == Invalid_Array)
		g_ambience_infos = ArrayCreate(SoundInfo, 1);
}

bool:SetSoundDuration(gamemode, duration_index, duration)
{
	if(duration > 0 && g_ambience_infos != Invalid_Array && duration_index >= 0 && duration_index < ArraySize(g_ambience_infos))
	{
		new index = 0;
		for(new i = 0; i < ArraySize(g_ambience_infos); i++)
		{
			new info[SoundInfo];
			ArrayGetArray(g_ambience_infos, i, info);
			if(info[SoundInfo_Mode] == gamemode)
			{
				if(index == duration_index)
				{
					info[SoundInfo_Duration] = duration;
					ArraySetArray(g_ambience_infos, i, info);
					return true;
				}
				index++;
			}
		}
	}
	return false;
}

AddSoundArrays(sound[], gamemode, duration)
{
	if(strlen(sound))
	{
		SoundArraysInitialize();
		
		new info[SoundInfo];
		info[SoundInfo_Mode] = gamemode;
		info[SoundInfo_Duration] = duration;
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
			info[SoundInfo_Index] = ArraySize(g_ambience_sounds);
			ArrayPushString(g_ambience_sounds, sound);
		}
		else
		{
			info[SoundInfo_Index] = index;
		}
		ArrayPushArray(g_ambience_infos, info);
		return info[SoundInfo_Index];
	}
	return ZP_INVALID_SOUND_ID;
}

GetSoundFileIndex(sound[])
{
	if(strlen(sound) && g_ambience_sounds != Invalid_Array)
	{
		for(new index = 0; index < ArraySize(g_ambience_sounds); index++)
		{
			new temp[SOUND_MAX_LENGTH];
			ArrayGetString(g_ambience_sounds, index, temp, charsmax(temp));
			if(equal(sound, temp))
				return index;
		}
	}
	return ZP_INVALID_SOUND_ID;
}

GetModeRandomSound(gamemode, sound[])
{
	new duration = 0;
	if(g_ambience_infos != Invalid_Array && g_ambience_sounds != Invalid_Array)
	{
		new Array:random_infos = ArrayCreate(SoundInfo, 1);
		for(new i = 0; i < ArraySize(g_ambience_infos); i++)
		{
			new info[SoundInfo];
			ArrayGetArray(g_ambience_infos, i, info);
			if(info[SoundInfo_Mode] == gamemode)
				ArrayPushArray(random_infos, info);
		}
		if(ArraySize(random_infos))
		{
			new info[SoundInfo];
			ArrayGetArray(random_infos, random_num(0, ArraySize(random_infos) - 1), info);
			ArrayGetString(g_ambience_sounds, info[SoundInfo_Index], sound, SOUND_MAX_LENGTH);
			duration = info[SoundInfo_Duration];
		}
		ArrayDestroy(random_infos);
	}
	return duration;
}