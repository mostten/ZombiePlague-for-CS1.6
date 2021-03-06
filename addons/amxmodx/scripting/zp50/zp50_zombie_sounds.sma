/*================================================================================
	
	--------------------------
	-*- [ZP] Zombie Sounds -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_zsounds_const>
#include <zp50_core>
#include <zp50_class_zombie>
#include <zp50_class_human>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

#define ZP_INVALID_TEAM_CLASS -1
#define ZP_STEP_DELAY 0.7
#define SOUND_MAX_LENGTH 64
#define TASK_IDLE_SOUNDS 100
#define TASK_STEP_SOUNDS 200
#define ID_IDLE_SOUNDS (taskid - TASK_IDLE_SOUNDS)
#define ID_STEP_SOUNDS (taskid - TASK_STEP_SOUNDS)
#define MAXPLAYERS 32

enum SoundTeam{
	SoundTeam_Human = 0,
	SoundTeam_Zombie,
	SoundTeam_Nemesis,
	SoundTeam_Survivor
};

enum SoundType{
	SoundType_Pain = 0,
	SoundType_Die,
	SoundType_Fall,
	SoundType_MissSlash,
	SoundType_MissWall,
	SoundType_HitNormal,
	SoundType_HitStab,
	SoundType_HeadShot,
	SoundType_Step,
	SoundType_Idle,
	SoundType_IdleLast
};

enum _:SoundInfo{
	SoundInfo_FileIndex = 0,
	SoundInfo_TeamClass,
	SoundType:SoundInfo_Type,
	SoundTeam:SoundInfo_Team
};

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_zombie_pain[][] = { "zombie_plague/zombie_pain1.wav" , "zombie_plague/zombie_pain2.wav" , "zombie_plague/zombie_pain3.wav" , "zombie_plague/zombie_pain4.wav" , "zombie_plague/zombie_pain5.wav" }
new const sound_nemesis_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_zombie_die[][] = { "zombie_plague/zombie_die1.wav" , "zombie_plague/zombie_die2.wav" , "zombie_plague/zombie_die3.wav" , "zombie_plague/zombie_die4.wav" , "zombie_plague/zombie_die5.wav" }
new const sound_zombie_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_zombie_miss_slash[][] = { "zombie_plague/zaphie/claw/zombie_swing_1.wav" , "zombie_plague/zaphie/claw/zombie_swing_2.wav" }
new const sound_zombie_miss_wall[][] = { "weapons/knife_hitwall1.wav" }
new const sound_zombie_hit_normal[][] = { "weapons/knife_hit1.wav" , "weapons/knife_hit2.wav" , "weapons/knife_hit3.wav" , "weapons/knife_hit4.wav" }
new const sound_zombie_hit_stab[][] = { "weapons/knife_stab.wav" }
new const sound_zombie_idle[][] = { "nihilanth/nil_now_die.wav" , "nihilanth/nil_slaves.wav" , "nihilanth/nil_alone.wav" , "zombie_plague/zombie_brains1.wav" , "zombie_plague/zombie_brains2.wav" }
new const sound_zombie_idle_last[][] = { "nihilanth/nil_thelast.wav" }

// Custom sounds
new Array:g_sound_files;
new Array:g_sound_infos;

new Float:g_client_origin[MAXPLAYERS+1][3];

new cvar_zombie_sounds_pain, cvar_zombie_sounds_attack, cvar_zombie_sounds_idle, cvar_zombie_sounds_headshot, cvar_zombie_sounds_step;

public plugin_init()
{
	register_plugin("[ZP] Zombie Sounds", ZP_VERSION_STRING, "ZP Dev Team");
	
	register_forward(FM_EmitSound, "fw_EmitSound");
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1);
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn", 1);
	
	cvar_zombie_sounds_pain = register_cvar("zp_zombie_sounds_pain", "1");
	cvar_zombie_sounds_attack = register_cvar("zp_zombie_sounds_attack", "1");
	cvar_zombie_sounds_idle = register_cvar("zp_zombie_sounds_idle", "1");
	cvar_zombie_sounds_headshot = register_cvar("zp_zombie_sounds_headshot", "1");
	cvar_zombie_sounds_step = register_cvar("zp_zombie_sounds_step", "1");
}

public plugin_precache()
{
	// Initialize arrays
	sound_arrays_initialize();
	
	// Precache sounds
	zombie_precache();
	nemesis_precache();
}

public plugin_natives()
{
	register_library("zp50_zombie_sounds");
	register_native("zp_zombie_register_sound", "native_zombie_register_sound");
	register_native("zp_human_register_sound", "native_human_register_sound");
	register_native("zp_survivor_register_sound", "native_survivor_register_sound");
	register_native("zp_nemesis_register_sound", "native_nemesis_register_sound");
	
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

sound_arrays_initialize()
{
	// Initialize arrays
	if(g_sound_files == Invalid_Array)
		g_sound_files = ArrayCreate(SOUND_MAX_LENGTH, 1);
	if(g_sound_infos == Invalid_Array)
		g_sound_infos = ArrayCreate(SoundInfo, 1);
}

nemesis_precache()
{
	// Initialize arrays
	new Array:nemesis_pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "NEMESIS PAIN", nemesis_pain);
	
	// If we couldn't load custom sounds from file, use and save default ones
	if (ArraySize(nemesis_pain) == 0)
	{
		for (new index = 0; index < sizeof sound_nemesis_pain; index++)
			ArrayPushString(nemesis_pain, sound_nemesis_pain[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "NEMESIS PAIN", nemesis_pain)
	}
	
	// Nemesis Class loaded?
	new sound[SOUND_MAX_LENGTH];
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		for (new index = 0; index < ArraySize(nemesis_pain); index++)
		{
			ArrayGetString(nemesis_pain, index, sound, charsmax(sound))
			AddSoundFileArray(sound, SoundTeam_Nemesis, SoundType_Pain);
		}
	}
	ArrayDestroy(nemesis_pain);
}

zombie_precache()
{
	// Initialize arrays
	new Array:sound_pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_die = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_fall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_miss_slash = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_miss_wall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_hit_normal = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_hit_stab = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_idle = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:sound_idle_last = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE PAIN", sound_pain);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE DIE", sound_die);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE FALL", sound_fall);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS SLASH", sound_miss_slash);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS WALL", sound_miss_wall);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT NORMAL", sound_hit_normal);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT STAB", sound_hit_stab);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE", sound_idle);
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE LAST", sound_idle_last);
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index;
	if (ArraySize(sound_pain) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_pain; index++)
			ArrayPushString(sound_pain, sound_zombie_pain[index]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE PAIN", sound_pain)
	}
	if (ArraySize(sound_die) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_die; index++)
			ArrayPushString(sound_die, sound_zombie_die[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE DIE", sound_die)
	}
	if (ArraySize(sound_fall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_fall; index++)
			ArrayPushString(sound_fall, sound_zombie_fall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE FALL", sound_fall)
	}
	if (ArraySize(sound_miss_slash) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_slash; index++)
			ArrayPushString(sound_miss_slash, sound_zombie_miss_slash[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS SLASH", sound_miss_slash)
	}
	if (ArraySize(sound_miss_wall) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_miss_wall; index++)
			ArrayPushString(sound_miss_wall, sound_zombie_miss_wall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MISS WALL", sound_miss_wall)
	}
	if (ArraySize(sound_hit_normal) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_normal; index++)
			ArrayPushString(sound_hit_normal, sound_zombie_hit_normal[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT NORMAL", sound_hit_normal)
	}
	if (ArraySize(sound_hit_stab) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_hit_stab; index++)
			ArrayPushString(sound_hit_stab, sound_zombie_hit_stab[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE HIT STAB", sound_hit_stab)
	}
	if (ArraySize(sound_idle) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_idle; index++)
			ArrayPushString(sound_idle, sound_zombie_idle[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE", sound_idle)
	}
	if (ArraySize(sound_idle_last) == 0)
	{
		for (index = 0; index < sizeof sound_zombie_idle_last; index++)
			ArrayPushString(sound_idle_last, sound_zombie_idle_last[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE IDLE LAST", sound_idle_last)
	}
	
	new sound[SOUND_MAX_LENGTH];
	for (index = 0; index < ArraySize(sound_pain); index++)
	{
		ArrayGetString(sound_pain, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_Pain);
	}
	for (index = 0; index < ArraySize(sound_die); index++)
	{
		ArrayGetString(sound_die, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_Die);
	}
	for (index = 0; index < ArraySize(sound_fall); index++)
	{
		ArrayGetString(sound_fall, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_Fall);
	}
	for (index = 0; index < ArraySize(sound_miss_slash); index++)
	{
		ArrayGetString(sound_miss_slash, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_MissSlash);
	}
	for (index = 0; index < ArraySize(sound_miss_wall); index++)
	{
		ArrayGetString(sound_miss_wall, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_MissWall);
	}
	for (index = 0; index < ArraySize(sound_hit_normal); index++)
	{
		ArrayGetString(sound_hit_normal, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_HitNormal);
	}
	for (index = 0; index < ArraySize(sound_hit_stab); index++)
	{
		ArrayGetString(sound_hit_stab, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_HitStab);
	}
	for (index = 0; index < ArraySize(sound_idle); index++)
	{
		ArrayGetString(sound_idle, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_Idle);
	}
	for (index = 0; index < ArraySize(sound_idle_last); index++)
	{
		ArrayGetString(sound_idle_last, index, sound, charsmax(sound));
		AddSoundFileArray(sound, SoundTeam_Zombie, SoundType_IdleLast);
	}
	
	ArrayDestroy(sound_pain);
	ArrayDestroy(sound_die);
	ArrayDestroy(sound_fall);
	ArrayDestroy(sound_miss_slash);
	ArrayDestroy(sound_miss_wall);
	ArrayDestroy(sound_hit_normal);
	ArrayDestroy(sound_hit_stab);
	ArrayDestroy(sound_idle);
	ArrayDestroy(sound_idle_last);
}

public native_zombie_register_sound(plugin_id, num_params)
{
	new classid = get_param(1);
	new pain[SOUND_MAX_LENGTH];
	new die[SOUND_MAX_LENGTH];
	new fall[SOUND_MAX_LENGTH];
	new miss_slash[SOUND_MAX_LENGTH];
	new miss_wall[SOUND_MAX_LENGTH];
	new hit_normal[SOUND_MAX_LENGTH];
	new hit_stab[SOUND_MAX_LENGTH];
	new idle[SOUND_MAX_LENGTH];
	new idle_last[SOUND_MAX_LENGTH];
	new head_shot[SOUND_MAX_LENGTH];
	new step[SOUND_MAX_LENGTH];
	
	get_string(2, pain, charsmax(pain));
	get_string(3, die, charsmax(die));
	get_string(4, fall, charsmax(fall));
	get_string(5, miss_slash, charsmax(miss_slash));
	get_string(6, miss_wall, charsmax(miss_wall));
	get_string(7, hit_normal, charsmax(hit_normal));
	get_string(8, hit_stab, charsmax(hit_stab));
	get_string(9, idle, charsmax(idle));
	get_string(10, idle_last, charsmax(idle_last));
	get_string(11, head_shot, charsmax(head_shot));
	get_string(12, step, charsmax(step));
	
	RegSounds(classid, SoundTeam_Zombie, pain, die, fall, miss_slash, miss_wall, hit_normal, hit_stab, idle, idle_last, head_shot, step);
}

public native_human_register_sound(plugin_id, num_params)
{
	new classid = get_param(1);
	new pain[SOUND_MAX_LENGTH];
	new die[SOUND_MAX_LENGTH];
	new fall[SOUND_MAX_LENGTH];
	new miss_slash[SOUND_MAX_LENGTH];
	new miss_wall[SOUND_MAX_LENGTH];
	new hit_normal[SOUND_MAX_LENGTH];
	new hit_stab[SOUND_MAX_LENGTH];
	new head_shot[SOUND_MAX_LENGTH];
	new step[SOUND_MAX_LENGTH];
	
	get_string(2, pain, charsmax(pain));
	get_string(3, die, charsmax(die));
	get_string(4, fall, charsmax(fall));
	get_string(5, miss_slash, charsmax(miss_slash));
	get_string(6, miss_wall, charsmax(miss_wall));
	get_string(7, hit_normal, charsmax(hit_normal));
	get_string(8, hit_stab, charsmax(hit_stab));
	get_string(9, head_shot, charsmax(head_shot));
	get_string(10, step, charsmax(step));
	
	RegSounds(classid, SoundTeam_Human, pain, die, fall, miss_slash, miss_wall, hit_normal, hit_stab, "", "", head_shot, step);
}

public native_survivor_register_sound(plugin_id, num_params)
{
	if(!LibraryExists(LIBRARY_SURVIVOR, LibType_Library)){return;}
	
	new classid = zp_class_survivor_get_classid();
	if(classid == ZP_INVALID_HUMAN_CLASS){return;}
	
	new pain[SOUND_MAX_LENGTH];
	new die[SOUND_MAX_LENGTH];
	new fall[SOUND_MAX_LENGTH];
	new miss_slash[SOUND_MAX_LENGTH];
	new miss_wall[SOUND_MAX_LENGTH];
	new hit_normal[SOUND_MAX_LENGTH];
	new hit_stab[SOUND_MAX_LENGTH];
	new head_shot[SOUND_MAX_LENGTH];
	new step[SOUND_MAX_LENGTH];
	
	get_string(1, pain, charsmax(pain));
	get_string(2, die, charsmax(die));
	get_string(3, fall, charsmax(fall));
	get_string(4, miss_slash, charsmax(miss_slash));
	get_string(5, miss_wall, charsmax(miss_wall));
	get_string(6, hit_normal, charsmax(hit_normal));
	get_string(7, hit_stab, charsmax(hit_stab));
	get_string(8, head_shot, charsmax(head_shot));
	get_string(9, step, charsmax(step));
	
	RegSounds(classid, SoundTeam_Survivor, pain, die, fall, miss_slash, miss_wall, hit_normal, hit_stab, "", "", head_shot, step);

}

public native_nemesis_register_sound(plugin_id, num_params)
{
	if(!LibraryExists(LIBRARY_NEMESIS, LibType_Library)){return;}
	
	new classid = zp_class_nemesis_get_classid();
	if(classid == ZP_INVALID_ZOMBIE_CLASS){return;}
	
	new pain[SOUND_MAX_LENGTH];
	new die[SOUND_MAX_LENGTH];
	new fall[SOUND_MAX_LENGTH];
	new miss_slash[SOUND_MAX_LENGTH];
	new miss_wall[SOUND_MAX_LENGTH];
	new hit_normal[SOUND_MAX_LENGTH];
	new hit_stab[SOUND_MAX_LENGTH];
	new idle[SOUND_MAX_LENGTH];
	new idle_last[SOUND_MAX_LENGTH];
	new head_shot[SOUND_MAX_LENGTH];
	new step[SOUND_MAX_LENGTH];
	
	get_string(1, pain, charsmax(pain));
	get_string(2, die, charsmax(die));
	get_string(3, fall, charsmax(fall));
	get_string(4, miss_slash, charsmax(miss_slash));
	get_string(5, miss_wall, charsmax(miss_wall));
	get_string(6, hit_normal, charsmax(hit_normal));
	get_string(7, hit_stab, charsmax(hit_stab));
	get_string(8, idle, charsmax(idle));
	get_string(9, idle_last, charsmax(idle_last));
	get_string(10, head_shot, charsmax(head_shot));
	get_string(11, step, charsmax(step));
	
	RegSounds(classid, SoundTeam_Nemesis, pain, die, fall, miss_slash, miss_wall, hit_normal, hit_stab, idle, idle_last, head_shot, step);
}

RegSounds(team_class, SoundTeam:sound_team, const pain[] = "", const die[] = "", const fall[] = "", const miss_slash[] = "", const miss_wall[] = "", const hit_normal[] = "", const hit_stab[] = "", const idle[] = "", const idle_last[] = "", const head_shot[] = "", const step[] = "")
{
	AddSoundFileArray(pain, sound_team, SoundType_Pain, team_class);
	AddSoundFileArray(die, sound_team, SoundType_Die, team_class);
	AddSoundFileArray(fall, sound_team, SoundType_Fall, team_class);
	AddSoundFileArray(miss_slash, sound_team, SoundType_MissSlash, team_class);
	AddSoundFileArray(miss_wall, sound_team, SoundType_MissWall, team_class);
	AddSoundFileArray(hit_normal, sound_team, SoundType_HitNormal, team_class);
	AddSoundFileArray(hit_stab, sound_team, SoundType_HitStab, team_class);
	AddSoundFileArray(idle, sound_team, SoundType_Idle, team_class);
	AddSoundFileArray(idle_last, sound_team, SoundType_IdleLast, team_class);
	AddSoundFileArray(head_shot, sound_team, SoundType_HeadShot, team_class);
	AddSoundFileArray(step, sound_team, SoundType_Step, team_class);
}

AddSoundFileArray(const sound[], SoundTeam:sound_team, SoundType:sound_type, team_class = ZP_INVALID_TEAM_CLASS)
{
	if(strlen(sound))
	{
		sound_arrays_initialize();
		
		new info[SoundInfo];
		info[SoundInfo_Team] = _:sound_team;
		info[SoundInfo_Type] = _:sound_type;
		info[SoundInfo_TeamClass] = team_class;
		new index = GetSoundFileArrayIndex(sound);
		if(index >= 0)
		{
			info[SoundInfo_FileIndex] = index;
		}
		else
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
			info[SoundInfo_FileIndex] = ArraySize(g_sound_files);
			ArrayPushString(g_sound_files, sound);
		}
		ArrayPushArray(g_sound_infos, info);
		return info[SoundInfo_FileIndex];
	}
	return ZP_INVALID_SOUND_ID;
}

GetSoundFileArrayIndex(const sound[])
{
	if(strlen(sound) && (g_sound_files != Invalid_Array))
	{
		for (new index = 0; index < ArraySize(g_sound_files); index++)
		{
			new temp[SOUND_MAX_LENGTH];
			ArrayGetString(g_sound_files, index, temp, SOUND_MAX_LENGTH);
			if(equal(sound, temp))
				return index;
		}
	}
	return ZP_INVALID_SOUND_ID;
}

GetClientSoundTeamClass(client)
{
	switch(GetClientSoundTeam(client))
	{
		case SoundTeam_Human:
		{
			new human_class = zp_class_human_get_current(client);
			if(human_class != ZP_INVALID_HUMAN_CLASS)
				return human_class;
		}
		case SoundTeam_Zombie:
		{
			new zombie_class = zp_class_zombie_get_current(client);
			if(zombie_class != ZP_INVALID_ZOMBIE_CLASS)
				return zombie_class;
		}
		case SoundTeam_Nemesis:
		{
			return zp_class_nemesis_get_classid();
		}
		case SoundTeam_Survivor:
		{
			return zp_class_survivor_get_classid();
		}
	}
	return ZP_INVALID_TEAM_CLASS;
}

SoundTeam:GetClientSoundTeam(client)
{
	if(LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(client))
	{
		return SoundTeam_Nemesis;
	}
	else if(LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(client))
	{
		return SoundTeam_Survivor;
	}
	else if(zp_core_is_zombie(client))
	{
		return SoundTeam_Zombie;
	}
	return SoundTeam_Human;
}

GetCustomSoundArray(team_class, SoundTeam:sound_team, SoundType:sound_type, &Array:sound_array)
{
	new count = 0;
	for (new index = 0; index < ArraySize(g_sound_infos); index++)
	{
		new info[SoundInfo];
		ArrayGetArray(g_sound_infos, index, info);
		if(info[SoundInfo_Team] == sound_team && info[SoundInfo_TeamClass] == team_class && info[SoundInfo_Type] == sound_type && info[SoundInfo_FileIndex] >= 0)
		{
			new sound[SOUND_MAX_LENGTH];
			ArrayGetString(g_sound_files, info[SoundInfo_FileIndex], sound, charsmax(sound));
			ArrayPushString(sound_array, sound);
			
			count++;
		}
	}
	return count;
}

bool:GetCustomRandomSound(team_class, SoundTeam:sound_team, SoundType:sound_type, sound[])
{
	new Array:sound_array = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new count = GetCustomSoundArray(team_class, sound_team, sound_type, sound_array);
	format(sound, SOUND_MAX_LENGTH, "");
	if(count > 0)
	{
		ArrayGetString(sound_array, random_num(0, ArraySize(sound_array) - 1), sound, SOUND_MAX_LENGTH);
	}
	else if(team_class != ZP_INVALID_TEAM_CLASS)
	{
		ArrayClear(sound_array);
		count = GetCustomSoundArray(ZP_INVALID_TEAM_CLASS, sound_team, sound_type, sound_array);
		if(count > 0)
			ArrayGetString(sound_array, random_num(0, ArraySize(sound_array) - 1), sound, SOUND_MAX_LENGTH);
	}
	ArrayDestroy(sound_array);
	return (strlen(sound) > 0);
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id))
		return FMRES_IGNORED;
	static sound[SOUND_MAX_LENGTH];
	if (get_pcvar_num(cvar_zombie_sounds_pain))
	{
		// Zombie being hit
		if (StrContains(sample, "/bhit_") > -1)
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_Pain, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
		
		// Zombie dies
		else if (StrContains(sample, "/die") > -1 || StrContains(sample, "/death") > -1)
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_Die, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
		
		// Zombie falls off
		else if (StrContains(sample, "/pl_fall") > -1)
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_Fall, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
	}
	
	if (get_pcvar_num(cvar_zombie_sounds_attack))
	{
		// Zombie attacks with knife
		if (StrContains(sample, "/knife_slash") > -1) // slash
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_MissSlash, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
		else if (StrContains(sample, "/knife_hitwall") > -1) // wall
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_MissWall, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
		else if (StrContains(sample, "/knife_hit") > -1) // hit
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_HitNormal, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
		else if (StrContains(sample, "/knife_stab") > -1) // stab
		{
			if(GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_HitStab, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
	}
	
	if (get_pcvar_num(cvar_zombie_sounds_headshot))
	{
		if (StrContains(sample, "/headshot") > -1) // headshot
		{
			if (GetCustomRandomSound(GetClientSoundTeamClass(id), GetClientSoundTeam(id), SoundType_HeadShot, sound))
			{
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			return FMRES_IGNORED;
		}
	}
	
	return FMRES_IGNORED;
}

// Ham Player Spawned Forward
public fw_PlayerSpawn(id) 
{
	if (get_pcvar_num(cvar_zombie_sounds_step))
		set_task(ZP_STEP_DELAY, "zombie_step_sounds", id+TASK_STEP_SOUNDS, _, _, "b");
}

public client_disconnected(id)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS);
	
	// Remove step sounds task
	remove_task(id+TASK_STEP_SOUNDS);
}

public zp_fw_core_infect_post(id, attacker)
{
	// Remove previous tasks
	remove_task(id+TASK_IDLE_SOUNDS)
	
	// Idle sounds?
	if (get_pcvar_num(cvar_zombie_sounds_idle))
	{
		switch(GetClientSoundTeam(id))
		{
			case SoundTeam_Zombie:
			{
				set_task(random_float(50.0, 70.0), "zombie_idle_sounds", id+TASK_IDLE_SOUNDS, _, _, "b");
			}
			case SoundTeam_Nemesis:
			{
				set_task(random_float(50.0, 70.0), "zombie_idle_sounds", id+TASK_IDLE_SOUNDS, _, _, "b");
			}
		}
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS)
}

// Play idle zombie sounds
public zombie_idle_sounds(taskid)
{
	static sound[SOUND_MAX_LENGTH];
	
	// Last zombie?
	if (zp_core_is_last_zombie(ID_IDLE_SOUNDS))
	{
		if(GetCustomRandomSound(GetClientSoundTeamClass(ID_IDLE_SOUNDS), GetClientSoundTeam(ID_IDLE_SOUNDS), SoundType_IdleLast, sound))
			emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		if(GetCustomRandomSound(GetClientSoundTeamClass(ID_IDLE_SOUNDS), GetClientSoundTeam(ID_IDLE_SOUNDS), SoundType_Idle, sound))
			emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}

// Play step sounds
public zombie_step_sounds(taskid)
{
	if (is_user_alive(ID_STEP_SOUNDS))
	{
		static sound[SOUND_MAX_LENGTH];
		if (IsClientOriginChanged(ID_STEP_SOUNDS) && (pev(ID_STEP_SOUNDS, pev_flags) & FL_ONGROUND) && GetCustomRandomSound(GetClientSoundTeamClass(ID_STEP_SOUNDS), GetClientSoundTeam(ID_STEP_SOUNDS), SoundType_Step, sound))
		{
			// Disable original step
			set_pev(ID_STEP_SOUNDS, pev_flTimeStepSound, 999);
			
			// Step sound
			emit_sound(ID_STEP_SOUNDS, CHAN_BODY, sound, VOL_NORM, ATTN_STATIC, 0, PITCH_NORM);
		}
	}
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	// Remove idle sounds task
	remove_task(victim+TASK_IDLE_SOUNDS);
	
	// Remove step sounds task
	remove_task(victim+TASK_STEP_SOUNDS);
	
	static sound[SOUND_MAX_LENGTH];
	new bool:headshot = (hitplace == HIT_HEAD);
	new bool:selfkill = (killer == victim);
	if(get_pcvar_num(cvar_zombie_sounds_headshot) && headshot && !selfkill && GetCustomRandomSound(GetClientSoundTeamClass(killer), GetClientSoundTeam(killer), SoundType_HeadShot, sound))
	{
		PlaySoundToClient(killer, sound);
		emit_sound(victim, CHAN_VOICE, sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

/**
 * Tests whether a string is found inside another string.
 *
 * @param str			String to search in.
 * @param substr		Substring to find inside the original string.
 * @param caseSensitive	If true (default), search is case sensitive.
 *						If false, search is case insensitive.
 * @return				-1 on failure (no match found). Any other value
 *						indicates a position in the string where the match starts.
 */
StrContains(const str[], const substr[], bool:caseSensitive = true)
{
	new strLen = strlen(str);
	new subLen = strlen(substr);
	if(strLen < 1 || subLen < 1 || subLen > strLen){return -1;}
	
	for(new i = 0; i < strLen; i++)
	{
		if((caseSensitive && str[i] != substr[0]) || (!caseSensitive && tolower(str[i]) != tolower(substr[0]))){continue;}
		
		new count = 1;
		for(new subi = 1; subi < subLen; subi++)
		{
			new temp = i + subi;
			
			if((temp < strLen) && ((caseSensitive && substr[subi] == str[temp]) || (!caseSensitive && tolower(substr[subi]) == tolower(str[temp])))){count++;}
			else{break;}
		}
		if(count == subLen){return i;}
	}
	return -1;
}

// Plays a sound on client
PlaySoundToClient(client, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(client, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(client, "spk ^"%s^"", sound);
}

//Get client speed
bool:IsClientOriginChanged(client)
{
	new Float:origin[3];
	pev(client, pev_origin, origin);
	if(origin[0] != g_client_origin[client][0] || origin[1] != g_client_origin[client][1] || origin[2] != g_client_origin[client][2])
	{
		g_client_origin[client][0] = origin[0];
		g_client_origin[client][1] = origin[1];
		g_client_origin[client][2] = origin[2];
		return true;
	}
	return false;
}