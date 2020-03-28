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
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_GHOST "zp50_class_ghost"
#include <zp50_class_ghost>

enum _:SoundType{
	SoundType_Pain = 0,
	SoundType_Die,
	SoundType_Fall,
	SoundType_MissSlash,
	SoundType_MissWall,
	SoundType_HitNormal,
	SoundType_HitStab,
	SoundType_Idle,
	SoundType_IdleLast
};

enum _:SoundInfo{
	SoundInfo_SoundId = 0,
	SoundType:SoundInfo_Type,
	SoundInfo_Ghost
};

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Settings file for ghost
new const ZP_GHOST_SETTINGS_FILE[] = "zombieplague_mod_ghost.ini"

// Default sounds
new const sound_zombie_pain[][] = { "zombie_plague/zombie_pain1.wav" , "zombie_plague/zombie_pain2.wav" , "zombie_plague/zombie_pain3.wav" , "zombie_plague/zombie_pain4.wav" , "zombie_plague/zombie_pain5.wav" }
new const sound_nemesis_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_zombie_die[][] = { "zombie_plague/zombie_die1.wav" , "zombie_plague/zombie_die2.wav" , "zombie_plague/zombie_die3.wav" , "zombie_plague/zombie_die4.wav" , "zombie_plague/zombie_die5.wav" }
new const sound_zombie_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_zombie_miss_slash[][] = { "zombie_plague/ghost/claw/zombie_swing_1.wav" , "zombie_plague/ghost/claw/zombie_swing_2.wav" }
new const sound_zombie_miss_wall[][] = { "weapons/knife_hitwall1.wav" }
new const sound_zombie_hit_normal[][] = { "weapons/knife_hit1.wav" , "weapons/knife_hit2.wav" , "weapons/knife_hit3.wav" , "weapons/knife_hit4.wav" }
new const sound_zombie_hit_stab[][] = { "weapons/knife_stab.wav" }
new const sound_zombie_idle[][] = { "nihilanth/nil_now_die.wav" , "nihilanth/nil_slaves.wav" , "nihilanth/nil_alone.wav" , "zombie_plague/zombie_brains1.wav" , "zombie_plague/zombie_brains2.wav" }
new const sound_zombie_idle_last[][] = { "nihilanth/nil_thelast.wav" }

// Ghost sounds
new const sound_ghost_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_ghost_die[][] = { "zombie_plague/ghost/zbs_death_female_1.wav" }
new const sound_ghost_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_ghost_miss_slash[][] = { "zombie_plague/ghost/claw/zombie_ghost_midslash01.wav" , "zombie_plague/ghost/claw/zombie_ghost_midslash02.wav" }
new const sound_ghost_miss_wall[][] = { "zombie_plague/ghost/claw/zombie_ghost_draw.wav" }
new const sound_ghost_hit_normal[][] = { "zombie_plague/ghost/claw/zombie_hit1.wav" , "zombie_plague/ghost/claw/zombie_hit2.wav" , "zombie_plague/ghost/claw/zombie_hit3.wav" , "zombie_plague/ghost/claw/zombie_hit4.wav" }
new const sound_ghost_hit_stab[][] = { "zombie_plague/ghost/claw/zombie_ghost_stab.wav" , "zombie_plague/ghost/claw/zombie_ghost_stabmiss.wav" }
new const sound_ghost_idle[][] = { "zombie_plague/ghost/ambience/zombie_ghost_idle01.wav" , "zombie_plague/ghost/ambience/zombie_ghost_idle02.wav" }
new const sound_ghost_idle_last[][] = { "zombie_plague/ghost/ambience/zombie_ghost_idle03.wav" }

#define SOUND_MAX_LENGTH 64

// Custom sounds
new Array:g_sound_nemesis_pain
new Array:g_ghost_ids;
new Array:g_sound_ids;
new Array:g_sound_files;
new Array:g_sound_infos;

#define TASK_IDLE_SOUNDS 100
#define ID_IDLE_SOUNDS (taskid - TASK_IDLE_SOUNDS)

new cvar_zombie_sounds_pain, cvar_zombie_sounds_attack, cvar_zombie_sounds_idle

public plugin_init()
{
	register_plugin("[ZP] Zombie Sounds", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	cvar_zombie_sounds_pain = register_cvar("zp_zombie_sounds_pain", "1")
	cvar_zombie_sounds_attack = register_cvar("zp_zombie_sounds_attack", "1")
	cvar_zombie_sounds_idle = register_cvar("zp_zombie_sounds_idle", "1")
}

public plugin_precache()
{
	// Initialize arrays
	sound_arrays_initialize();
	
	// Precache sounds
	zombie_precache();
	nemesis_precache();
	ghost_precache();
	
	new sound[SOUND_MAX_LENGTH];
	for (new index = 0; index < ArraySize(g_sound_files); index++)
	{
		ArrayGetString(g_sound_files, index, sound, charsmax(sound));
		precache_sound(sound);
	}
}

sound_arrays_initialize()
{
	// Initialize arrays
	if(g_ghost_ids == Invalid_Array)
		g_ghost_ids = ArrayCreate(1, 1);
	if(g_sound_ids == Invalid_Array)
		g_sound_ids = ArrayCreate(1, 1);
	if(g_sound_files == Invalid_Array)
		g_sound_files = ArrayCreate(SOUND_MAX_LENGTH, 1);
	if(g_sound_infos == Invalid_Array)
		g_sound_infos = ArrayCreate(SoundInfo, 1);
}

ghost_precache()
{
	// Initialize ghost arrays
	new Array:ghost_pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_die = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_fall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_miss_slash = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_miss_wall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_hit_normal = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_hit_stab = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_idle = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:ghost_idle_last = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	// Load ghost sounds from external file
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST PAIN", ghost_pain);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST DIE", ghost_die);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST FALL", ghost_fall);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST MISS SLASH", ghost_miss_slash);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST MISS WALL", ghost_miss_wall);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST HIT NORMAL", ghost_hit_normal);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST HIT STAB", ghost_hit_stab);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST IDLE", ghost_idle);
	amx_load_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST IDLE LAST", ghost_idle_last);
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index;
	if (ArraySize(ghost_pain) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_pain; index++)
			ArrayPushString(ghost_pain, sound_ghost_pain[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST PAIN", ghost_pain)
	}
	if (ArraySize(ghost_die) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_die; index++)
			ArrayPushString(ghost_die, sound_ghost_die[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST DIE", ghost_die)
	}
	if (ArraySize(ghost_fall) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_fall; index++)
			ArrayPushString(ghost_fall, sound_ghost_fall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST FALL", ghost_fall)
	}
	if (ArraySize(ghost_miss_slash) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_miss_slash; index++)
			ArrayPushString(ghost_miss_slash, sound_ghost_miss_slash[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST MISS SLASH", ghost_miss_slash)
	}
	if (ArraySize(ghost_miss_wall) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_miss_wall; index++)
			ArrayPushString(ghost_miss_wall, sound_ghost_miss_wall[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST MISS WALL", ghost_miss_wall)
	}
	if (ArraySize(ghost_hit_normal) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_hit_normal; index++)
			ArrayPushString(ghost_hit_normal, sound_ghost_hit_normal[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST HIT NORMAL", ghost_hit_normal)
	}
	if (ArraySize(ghost_hit_stab) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_hit_stab; index++)
			ArrayPushString(ghost_hit_stab, sound_ghost_hit_stab[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST HIT STAB", ghost_hit_stab)
	}
	if (ArraySize(ghost_idle) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_idle; index++)
			ArrayPushString(ghost_idle, sound_ghost_idle[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST IDLE", ghost_idle)
	}
	if (ArraySize(ghost_idle_last) == 0)
	{
		for (index = 0; index < sizeof sound_ghost_idle_last; index++)
			ArrayPushString(ghost_idle_last, sound_ghost_idle_last[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_GHOST_SETTINGS_FILE, "Sounds", "GHOST IDLE LAST", ghost_idle_last)
	}
	
	// Ghost Class loaded?
	if (LibraryExists(LIBRARY_GHOST, LibType_Library))
	{
		new info[SoundInfo];
		new sound[SOUND_MAX_LENGTH];
		info[SoundInfo_Ghost] = 1;
		info[SoundInfo_SoundId] = ZP_INVALID_SOUND_ID;
		for (index = 0; index < ArraySize(ghost_pain); index++)
		{
			info[SoundInfo_Type] = SoundType_Pain;
			ArrayGetString(ghost_pain, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_die); index++)
		{
			info[SoundInfo_Type] = SoundType_Die;
			ArrayGetString(ghost_die, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_fall); index++)
		{
			info[SoundInfo_Type] = SoundType_Fall;
			ArrayGetString(ghost_fall, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_miss_slash); index++)
		{
			info[SoundInfo_Type] = SoundType_MissSlash;
			ArrayGetString(ghost_miss_slash, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_miss_wall); index++)
		{
			info[SoundInfo_Type] = SoundType_MissWall;
			ArrayGetString(ghost_miss_wall, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_hit_normal); index++)
		{
			info[SoundInfo_Type] = SoundType_HitNormal;
			ArrayGetString(ghost_hit_normal, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_hit_stab); index++)
		{
			info[SoundInfo_Type] = SoundType_HitStab;
			ArrayGetString(ghost_hit_stab, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_idle); index++)
		{
			info[SoundInfo_Type] = SoundType_Idle;
			ArrayGetString(ghost_idle, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
		for (index = 0; index < ArraySize(ghost_idle_last); index++)
		{
			info[SoundInfo_Type] = SoundType_IdleLast;
			ArrayGetString(ghost_idle_last, index, sound, charsmax(sound));
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	ArrayDestroy(ghost_pain);
	ArrayDestroy(ghost_die);
	ArrayDestroy(ghost_fall);
	ArrayDestroy(ghost_miss_slash);
	ArrayDestroy(ghost_miss_wall);
	ArrayDestroy(ghost_hit_normal);
	ArrayDestroy(ghost_hit_stab);
	ArrayDestroy(ghost_idle);
	ArrayDestroy(ghost_idle_last);
}

nemesis_precache()
{
	// Initialize arrays
	g_sound_nemesis_pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "NEMESIS PAIN", g_sound_nemesis_pain);
	
	// If we couldn't load custom sounds from file, use and save default ones
	if (ArraySize(g_sound_nemesis_pain) == 0)
	{
		for (new index = 0; index < sizeof sound_nemesis_pain; index++)
			ArrayPushString(g_sound_nemesis_pain, sound_nemesis_pain[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "NEMESIS PAIN", g_sound_nemesis_pain)
	}
	
	new sound[SOUND_MAX_LENGTH];
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		for (new index = 0; index < ArraySize(g_sound_nemesis_pain); index++)
		{
			ArrayGetString(g_sound_nemesis_pain, index, sound, charsmax(sound))
			precache_sound(sound)
		}
	}	
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
	
	new info[SoundInfo];
	new sound[SOUND_MAX_LENGTH];
	info[SoundInfo_Ghost] = 0;
	info[SoundInfo_SoundId] = ZP_INVALID_SOUND_ID;
	for (index = 0; index < ArraySize(sound_pain); index++)
	{
		info[SoundInfo_Type] = SoundType_Pain;
		ArrayGetString(sound_pain, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_die); index++)
	{
		info[SoundInfo_Type] = SoundType_Die;
		ArrayGetString(sound_die, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_fall); index++)
	{
		info[SoundInfo_Type] = SoundType_Fall;
		ArrayGetString(sound_fall, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_miss_slash); index++)
	{
		info[SoundInfo_Type] = SoundType_MissSlash;
		ArrayGetString(sound_miss_slash, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_miss_wall); index++)
	{
		info[SoundInfo_Type] = SoundType_MissWall;
		ArrayGetString(sound_miss_wall, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_hit_normal); index++)
	{
		info[SoundInfo_Type] = SoundType_HitNormal;
		ArrayGetString(sound_hit_normal, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_hit_stab); index++)
	{
		info[SoundInfo_Type] = SoundType_HitStab;
		ArrayGetString(sound_hit_stab, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_idle); index++)
	{
		info[SoundInfo_Type] = SoundType_Idle;
		ArrayGetString(sound_idle, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
	}
	for (index = 0; index < ArraySize(sound_idle_last); index++)
	{
		info[SoundInfo_Type] = SoundType_IdleLast;
		ArrayGetString(sound_idle_last, index, sound, charsmax(sound));
		ArrayPushString(g_sound_files, sound);
		ArrayPushArray(g_sound_infos, info);
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

public native_zombie_sound_register(plugin_id, num_params)
{
	new zombie_class = get_param(1);
	new Array:sound_pain = Array:get_param(2);
	new Array:sound_die = Array:get_param(3);
	new Array:sound_fall = Array:get_param(4);
	new Array:sound_miss_slash = Array:get_param(5);
	new Array:sound_miss_wall = Array:get_param(6);
	new Array:sound_hit_normal = Array:get_param(7);
	new Array:sound_hit_stab = Array:get_param(8);
	new Array:sound_idle = Array:get_param(9);
	new Array:sound_idle_last = Array:get_param(10);
	
	return RegSoundArray(zombie_class, 0, sound_pain, sound_die, sound_fall, sound_miss_slash, sound_miss_wall, sound_hit_normal, sound_hit_stab, sound_idle, sound_idle_last);
}

public native_ghost_sound_register(plugin_id, num_params)
{
	new ghost_class = get_param(1);
	new Array:sound_pain = Array:get_param(2);
	new Array:sound_die = Array:get_param(3);
	new Array:sound_fall = Array:get_param(4);
	new Array:sound_miss_slash = Array:get_param(5);
	new Array:sound_miss_wall = Array:get_param(6);
	new Array:sound_hit_normal = Array:get_param(7);
	new Array:sound_hit_stab = Array:get_param(8);
	new Array:sound_idle = Array:get_param(9);
	new Array:sound_idle_last = Array:get_param(10);
	
	return RegSoundArray(ghost_class, 1, sound_pain, sound_die, sound_fall, sound_miss_slash, sound_miss_wall, sound_hit_normal, sound_hit_stab, sound_idle, sound_idle_last);
}

RegSoundArray(zombie_class, ghost, &Array:sound_pain, &Array:sound_die, &Array:sound_fall, &Array:sound_miss_slash, &Array:sound_miss_wall, &Array:sound_hit_normal, &Array:sound_hit_stab, &Array:sound_idle, &Array:sound_idle_last)
{
	// Initialize arrays
	sound_arrays_initialize();
	
	new info[SoundInfo];
	new sound[SOUND_MAX_LENGTH];
	new index = GetSoundArrayIndex(zombie_class, ghost);
	if(index < 0)
	{
		new bool:isGhostMod = (ghost > 0);
		ArrayPushCell(isGhostMod?g_ghost_ids:g_sound_ids, zombie_class);
		info[SoundInfo_SoundId] = ArraySize(isGhostMod?g_ghost_ids:g_sound_ids) - 1;
	}
	else
	{
		info[SoundInfo_SoundId] = index;
		return index;
	}
	
	info[SoundInfo_Ghost] = ghost;
	if(sound_pain != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_pain); index++)
		{
			ArrayGetString(sound_pain, index, sound, charsmax(sound));
			info[SoundInfo_Type] = SoundType_Pain;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_die != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_die); index++)
		{
			ArrayGetString(sound_die, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_Die;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_fall != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_fall); index++)
		{
			ArrayGetString(sound_fall, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_Fall;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_miss_slash != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_miss_slash); index++)
		{
			ArrayGetString(sound_miss_slash, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_MissSlash;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_miss_wall != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_miss_wall); index++)
		{
			ArrayGetString(sound_miss_wall, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_MissWall;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_hit_normal != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_hit_normal); index++)
		{
			ArrayGetString(sound_hit_normal, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_HitNormal;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_hit_stab != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_hit_stab); index++)
		{
			ArrayGetString(sound_hit_stab, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_HitStab;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_idle != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_idle); index++)
		{
			ArrayGetString(sound_idle, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_Idle;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	if(sound_idle_last != Invalid_Array)
	{
		for (index = 0; index < ArraySize(sound_idle_last); index++)
		{
			ArrayGetString(sound_idle_last, index, sound, charsmax(sound));
			
			info[SoundInfo_Type] = SoundType_IdleLast;
			ArrayPushString(g_sound_files, sound);
			ArrayPushArray(g_sound_infos, info);
		}
	}
	// Precache sounds
	for (index = 0; index < ArraySize(g_sound_files); index++)
	{
		ArrayGetString(g_sound_files, index, sound, charsmax(sound));
		precache_sound(sound);
	}
	return info[SoundInfo_SoundId];
}

GetSoundArrayIndex(zombie_class, ghost)
{
	if(ghost > 0)
	{
		for (new index = 0; index < ArraySize(g_ghost_ids); index++)
		{
			if(ArrayGetCell(g_ghost_ids, index) == zombie_class)
				return index;
		}
	}
	else
	{
		for (new index = 0; index < ArraySize(g_sound_ids); index++)
		{
			if(ArrayGetCell(g_sound_ids, index) == zombie_class)
				return index;
		}
	}
	return -1;
}

GetPlayerSoundId(client, ghost)
{
	if(ghost > 0)
	{
		new ghost_class = zp_class_ghost_get_current(client);
		if(ghost_class != ZP_INVALID_GHOST_CLASS)
		{
			for (new index = 0; index < ArraySize(g_ghost_ids); index++)
			{
				if(ArrayGetCell(g_ghost_ids, index) == ghost_class)
					return index;
			}
		}
	}
	else
	{
		new zombie_class = zp_class_zombie_get_current(client);
		if(zombie_class != ZP_INVALID_ZOMBIE_CLASS)
		{
			for (new index = 0; index < ArraySize(g_sound_ids); index++)
			{
				if(ArrayGetCell(g_sound_ids, index) == zombie_class)
					return index;
			}
		}
	}
	return ZP_INVALID_SOUND_ID;
}

GetCustomSoundArray(sound_id, sound_ghost, sound_type, &Array:sound_array)
{
	new count = 0;
	for (new index = 0; index < ArraySize(g_sound_infos); index++)
	{
		new info[SoundInfo];
		ArrayGetArray(g_sound_infos, index, info);
		if(_:info[SoundInfo_SoundId] == sound_id && _:info[SoundInfo_Ghost] == sound_ghost && _:info[SoundInfo_Type] == sound_type)
		{
			new sound[SOUND_MAX_LENGTH];
			ArrayGetString(g_sound_files, index, sound, charsmax(sound));
			ArrayPushString(sound_array, sound);
			count++;
		}
	}
	return count;
}

bool:GetCustomRandomSound(sound_id, sound_ghost, sound_type, sound[])
{
	new Array:sound_array = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new count = GetCustomSoundArray(sound_id, sound_ghost, sound_type, sound_array);
	if(count > 0)
	{
		ArrayGetString(sound_array, random_num(0, ArraySize(sound_array) - 1), sound, SOUND_MAX_LENGTH);
	}
	else if(sound_id != ZP_INVALID_SOUND_ID)
	{
		ArrayClear(sound_array);
		count = GetCustomSoundArray(ZP_INVALID_SOUND_ID, sound_ghost, sound_type, sound_array);
		if(count > 0)
			ArrayGetString(sound_array, random_num(0, ArraySize(sound_array) - 1), sound, SOUND_MAX_LENGTH);
	}
	ArrayDestroy(sound_array);
	return (strlen(sound) > 0);
}

public plugin_natives()
{
	register_library("zp50_zombie_sounds");
	register_native("zp_zombie_sound_register", "native_zombie_sound_register");
	register_native("zp_ghost_sound_register", "native_ghost_sound_register");
	
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_GHOST))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !zp_core_is_zombie(id))
		return FMRES_IGNORED;
	
	new ghost_mod = (LibraryExists(LIBRARY_GHOST, LibType_Library) && zp_class_ghost_get(id))?1:0;
	static sound[SOUND_MAX_LENGTH];
	if (get_pcvar_num(cvar_zombie_sounds_pain))
	{
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			// Nemesis Class loaded?
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
			{
				ArrayGetString(g_sound_nemesis_pain, random_num(0, ArraySize(g_sound_nemesis_pain) - 1), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_Pain, sound);
			emit_sound(id, channel, sound, volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_Die, sound);
			emit_sound(id, channel, sound, volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
		
		// Zombie falls off
		if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
		{
			GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_Fall, sound);
			emit_sound(id, channel, sound, volume, attn, flags, pitch);
			return FMRES_SUPERCEDE;
		}
	}
	
	if (get_pcvar_num(cvar_zombie_sounds_attack))
	{
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_MissSlash, sound);
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_MissWall, sound);
					emit_sound(id, channel, sound, volume, attn, flags, pitch);
					return FMRES_SUPERCEDE;
				}
				else
				{
					GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_HitNormal, sound);
					emit_sound(id, channel, sound, volume, attn, flags, pitch);
					return FMRES_SUPERCEDE;
				}
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				GetCustomRandomSound(GetPlayerSoundId(id, ghost_mod), ghost_mod, SoundType_HitStab, sound);
				emit_sound(id, channel, sound, volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	return FMRES_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Remove idle sounds task
	remove_task(victim+TASK_IDLE_SOUNDS)
}

public client_disconnect(id)
{
	// Remove idle sounds task
	remove_task(id+TASK_IDLE_SOUNDS)
}

public zp_fw_core_infect_post(id, attacker)
{
	// Remove previous tasks
	remove_task(id+TASK_IDLE_SOUNDS)
	
	// Ghost Class loaded
	if (LibraryExists(LIBRARY_GHOST, LibType_Library) && zp_class_ghost_get(id))
	{
		// Idle sounds?
		if (get_pcvar_num(cvar_zombie_sounds_idle))
			set_task(random_float(50.0, 70.0), "zombie_idle_sounds", id+TASK_IDLE_SOUNDS, _, _, "b")
		return;
	}
	
	// Nemesis Class loaded?
	if (!LibraryExists(LIBRARY_NEMESIS, LibType_Library) || !zp_class_nemesis_get(id))
	{
		// Idle sounds?
		if (get_pcvar_num(cvar_zombie_sounds_idle))
			set_task(random_float(50.0, 70.0), "zombie_idle_sounds", id+TASK_IDLE_SOUNDS, _, _, "b")
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
	static sound[SOUND_MAX_LENGTH]
	
	// Last zombie?
	new ghost_mod = (LibraryExists(LIBRARY_GHOST, LibType_Library) && zp_class_ghost_get(ID_IDLE_SOUNDS))?1:0;
	if (zp_core_is_last_zombie(ID_IDLE_SOUNDS))
	{
		GetCustomRandomSound(GetPlayerSoundId(ID_IDLE_SOUNDS, ghost_mod), ghost_mod, SoundType_IdleLast, sound);
		emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
	else
	{
		GetCustomRandomSound(GetPlayerSoundId(ID_IDLE_SOUNDS, ghost_mod), ghost_mod, SoundType_Idle, sound);
		emit_sound(ID_IDLE_SOUNDS, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}
