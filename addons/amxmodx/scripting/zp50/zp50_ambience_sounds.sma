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

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

// 声音文件
new const sounds_default[][] = {
	"zombie_plague/ambience.wav"
}
new const durations_default[] = {
	17
}

new Array:g_ambience_modes;
new Array:g_ambience_sounds;
new Array:g_ambience_durations;

public plugin_init()
{
	register_plugin("[ZP] Ambience Sonds", ZP_VERSION_STRING, "ZP Dev Team rewrite by mostten");
	register_event("30", "event_intermission", "a");
}

public plugin_precache()
{
	g_ambience_sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_ambience_modes = ArrayCreate(1, 1);
	g_ambience_durations = ArrayCreate(1, 1);
	
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
				if (equal(sound[strlen(sound)-4], ".mp3"))
				{
					new path[128];
					format(path, charsmax(path), "sound/%s", sound);
					precache_generic(path);
				}
				else
					precache_sound(sound);
				ArrayPushString(g_ambience_sounds, sound);
				ArrayPushCell(g_ambience_modes, index);
			}
		}
		else
		{
			for (new sound_index = 0; sound_index < sizeof sounds_default; sound_index++)
			{
				ArrayPushString(ambience_sounds, sounds_default[sound_index]);
				ArrayPushString(g_ambience_sounds, sounds_default[sound_index]);
				ArrayPushCell(g_ambience_modes, index);
			}
			// 存储至外部文件
			amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_sounds);
		}
		
		new Array:ambience_durations = ArrayCreate(1, 1);
		formatex(key, charsmax(key), "DURATIONS (%s)", modename);
		amx_load_setting_int_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_durations);
		if (ArraySize(ambience_durations) > 0)
		{
			for (new sound_index = 0; sound_index < ArraySize(ambience_durations); sound_index++)
			{
				new duration = ArrayGetCell(ambience_durations, sound_index);
				ArrayPushCell(g_ambience_durations, duration);
			}
		}
		else
		{
			for (new duration_index = 0; duration_index < sizeof durations_default; duration_index++)
			{
				ArrayPushCell(ambience_durations, durations_default[duration_index]);
				ArrayPushCell(g_ambience_durations, durations_default[duration_index]);
			}
			// 存储至外部文件
			amx_save_setting_int_arr(ZP_SETTINGS_FILE, "Ambience Sounds", key, ambience_durations);
		}
		
		new sounds_count = ArraySize(ambience_sounds);
		new durations_count = ArraySize(ambience_durations);
		if(durations_count < sounds_count)
		{
			for(new i = durations_count; i < sounds_count; i++)
				ArrayPushCell(g_ambience_durations, 0);
		}
		
		ArrayDestroy(ambience_sounds);
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

GetModeRandomSound(gamemode, sound[])
{
	new duration = 0;
	new Array:random_sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:random_durations = ArrayCreate(1, 1);
	for(new i = 0; i < ArraySize(g_ambience_modes); i++)
	{
		new mode = ArrayGetCell(g_ambience_modes, i);
		if(mode == gamemode)
		{
			new sound_temp[SOUND_MAX_LENGTH];
			new duration_temp = ArrayGetCell(g_ambience_durations, i);
			ArrayPushCell(random_durations, duration_temp);
			ArrayGetString(g_ambience_sounds, i, sound_temp, charsmax(sound_temp));
			ArrayPushString(random_sounds, sound_temp);
		}
	}
	if(ArraySize(random_sounds) && ArraySize(random_durations))
	{
		new random = random_num(0, ArraySize(random_sounds) - 1);
		ArrayGetString(random_sounds, random, sound, SOUND_MAX_LENGTH);
		if(random < ArraySize(random_durations))
			duration = ArrayGetCell(random_durations, random);
	}
	ArrayDestroy(random_sounds);
	ArrayDestroy(random_durations);
	return duration;
}