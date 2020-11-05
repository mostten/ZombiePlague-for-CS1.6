/*================================================================================
	
	-------------------------------
	-*- [ZP] Game Mode: Predator -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_predator>
#include <zp50_class_npc>
#include <zp50_class_npc_alien>
#include <zp50_deathmatch>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague_zaphie.ini";

// Default sounds
new const sound_predator[][] = { "zombie_plague/nemesis1.wav" , "zombie_plague/nemesis2.wav" };

new Array:g_sound_predator;

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 20
#define HUD_EVENT_B 20

#define SOUND_MAX_LENGTH 64

new g_PredatorModeId;
new g_MaxPlayers;
new g_HudSync;

new cvar_predator_chance, cvar_predator_ratio, cvar_alien_ratio;
new cvar_predator_min_players, cvar_predator_min_predators;
new cvar_predator_show_hud, cvar_predator_sounds;
new cvar_predator_allow_respawn;

public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Predator", ZP_VERSION_STRING, "Mostten");
	g_PredatorModeId = zp_gamemodes_register("Predator Mode");
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj();
	
	g_MaxPlayers = get_maxplayers();
	
	cvar_predator_chance = register_cvar("zp_predator_chance", "20");
	cvar_predator_min_players = register_cvar("zp_predator_min_players", "0");
	cvar_predator_min_predators = register_cvar("zp_predator_min_predators", "1");
	cvar_predator_ratio = register_cvar("zp_predator_ratio", "0.15");
	cvar_alien_ratio = register_cvar("zp_predator_alien_ratio", "1.0");
	cvar_predator_show_hud = register_cvar("zp_predator_show_hud", "1");
	cvar_predator_sounds = register_cvar("zp_predator_sounds", "1");
	cvar_predator_allow_respawn = register_cvar("zp_predator_allow_respawn", "0");
	
	// Initialize arrays
	g_sound_predator = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND Predator", g_sound_predator);
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index;
	if (ArraySize(g_sound_predator) == 0)
	{
		for (index = 0; index < sizeof sound_predator; index++)
			ArrayPushString(g_sound_predator, sound_predator[index]);
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND PREDATOR", g_sound_predator);
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH];
	for (index = 0; index < ArraySize(g_sound_predator); index++)
	{
		ArrayGetString(g_sound_predator, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound);
			precache_generic(sound);
		}
		else
			precache_sound(sound);
	}
}

public zp_fw_class_zombie_menu_show_pre(id)
{
	if (is_predator_mod(zp_gamemodes_get_current()))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(client)
{
	if (is_predator_mod(zp_gamemodes_get_current()))
	{
		// Respawning allowed?
		if (!get_pcvar_num(cvar_predator_allow_respawn))
			return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(client)
{
	// Always respawn as human on Predator rounds
	if (is_predator_mod(zp_gamemodes_get_current()))
		zp_core_respawn_as_zombie(client, false);
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	new alive_count = GetAliveCount();
	
	// Calculate predator count with current ratio setting
	new predator_count = floatround(alive_count * get_pcvar_float(cvar_predator_ratio), floatround_ceil);
	
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_predator_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (alive_count < get_pcvar_num(cvar_predator_min_players))
			return PLUGIN_HANDLED;
		
		// Min predator
		if (predator_count < get_pcvar_num(cvar_predator_min_predators))
			return PLUGIN_HANDLED;
	}
	
	// Predator count should be smaller than alive players count, so that there's humans left in the round
	if (predator_count >= alive_count)
		return PLUGIN_HANDLED;
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start(game_mode_id)
{
	if(!is_predator_mod(game_mode_id))
		return;
	
	// Enable infect?
	zp_gamemodes_set_allow_infect(true);
	
	// iMaxPredators is rounded up, in case there aren't enough players
	new iPredators, id, alive_count = GetAliveCount();
	new iMaxPredators = floatround(alive_count * get_pcvar_float(cvar_predator_ratio), floatround_ceil);
	
	// Turn the remaining players into humans
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Only those of them alive
		if (!is_user_alive(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	
	// Randomly turn iMaxPredators players into predators
	while(iPredators < iMaxPredators)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a predator
		if (!is_user_alive(id) || zp_class_predator_get(id))
			continue;
		
		// Turn into a predator
		zp_class_predator_set(id)
		iPredators++
	}
	
	// Spawn aliens
	new iAliens = 0;
	new iMaxAliens = floatround(alive_count * get_pcvar_float(cvar_alien_ratio), floatround_ceil) - zp_npc_alien_get_count();
	while(iAliens < iMaxAliens)
	{
		zp_npc_alien_spawn();
		iAliens++;
	}
	
	// Play Predator sound
	if (get_pcvar_num(cvar_predator_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_predator, random_num(0, ArraySize(g_sound_predator) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_predator_show_hud))
	{
		// Show Predator HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_PREDATOR")
	}
}

public zp_fw_npc_dead_post(npc, attacker)
{
	zp_npc_alien_spawn();
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}

bool:is_predator_mod(game_mode_id)
{
	return g_PredatorModeId != ZP_INVALID_GAME_MODE && game_mode_id == g_PredatorModeId;
}