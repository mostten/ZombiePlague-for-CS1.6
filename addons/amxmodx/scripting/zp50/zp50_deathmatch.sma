/*================================================================================
	
	-----------------------
	-*- [ZP] Deathmatch -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>

#define TASK_RESPAWN 100

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_RESPAWN_PRE = 0
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers
new g_GameModeStarted

new cvar_deathmatch, cvar_respawn_delay
new cvar_respawn_zombies, cvar_respawn_humans
new cvar_respawn_on_suicide, cvar_zombie_headshot_die

public plugin_init()
{
	register_plugin("[ZP] Deathmatch", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	
	cvar_deathmatch = register_cvar("zp_deathmatch", "0")
	cvar_respawn_delay = register_cvar("zp_respawn_delay", "5")
	cvar_respawn_zombies = register_cvar("zp_respawn_zombies", "1")
	cvar_respawn_humans = register_cvar("zp_respawn_humans", "1")
	cvar_respawn_on_suicide = register_cvar("zp_respawn_on_suicide", "0")
	cvar_zombie_headshot_die = register_cvar("zp_zombie_headshot_die", "1")
	
	g_MaxPlayers = get_maxplayers()
	
	g_Forwards[FW_USER_RESPAWN_PRE] = CreateMultiForward("zp_fw_deathmatch_respawn_pre", ET_CONTINUE, FP_CELL)
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove respawn task
	remove_task(id+TASK_RESPAWN)
}

public client_death(killer, victim, wpnindex, hitplace, TK)
{
	if(get_pcvar_num(cvar_deathmatch))
	{
		// Respawn on suicide?
		if(!get_pcvar_num(cvar_respawn_on_suicide) && (victim == killer || !is_user_connected(killer)))
			return;
		
		// Respawn if human/zombie?
		new bool:zombie = zp_core_is_zombie(victim);
		if(zombie)
		{
			if(!get_pcvar_num(cvar_respawn_zombies))
				return;
			
			// Headshot Respawn?
			if(get_pcvar_num(cvar_zombie_headshot_die) && hitplace == HIT_HEAD)
				return;
		}
		else if(!get_pcvar_num(cvar_respawn_humans))
			return;
		
		// Set the respawn task
		new data_pack[2];
		data_pack[0] = victim;
		data_pack[1] = zombie?1:0;
		set_task(get_pcvar_float(cvar_respawn_delay), "respawn_player_task", victim+TASK_RESPAWN, data_pack, sizeof(data_pack));
	}
}

// Respawn Player Task (deathmatch)
public respawn_player_task(data_pack[2])
{
	// Already alive
	new client = data_pack[0];
	new bool:zombie = data_pack[1] == 1;
	if(!is_user_valid(client) || is_user_alive(client))
		return;
	
	// Already round ended
	if(zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
		return;
	
	// Get player's team
	new CsTeams:team = cs_get_user_team(client)
	
	// Player moved to spectators
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return;
	
	// Allow other plugins to decide whether player can respawn or not
	ExecuteForward(g_Forwards[FW_USER_RESPAWN_PRE], g_ForwardResult, client)
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	// Respawn as zombie?
	if (get_pcvar_num(cvar_deathmatch) == 2 || (get_pcvar_num(cvar_deathmatch) == 3 && random_num(0, 1)) || (get_pcvar_num(cvar_deathmatch) == 4 && zp_core_get_zombie_count() < GetAliveCount()/2))
	{
		// Only allow respawning as zombie after a game mode started
		if (g_GameModeStarted)
		{
			zombie = true;
			zp_core_respawn_as_zombie(client, zombie);
		}
	}
	
	respawn_player_manually(client, zombie)
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id, bool:zombie)
{
	// Respawn!
	ExecuteHamB(Ham_CS_RoundRespawn, id);
	
	// Respawn as zombie
	if(zombie){zp_core_force_infect(id);}
}

public client_disconnected(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_RESPAWN)
}

public zp_fw_gamemodes_start()
{
	g_GameModeStarted = true
}

public zp_fw_gamemodes_end()
{
	g_GameModeStarted = false
	
	// Stop respawning after game mode ends
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
		remove_task(id+TASK_RESPAWN)
}

bool:is_user_valid(id)
{
	return (1 <= id <= g_MaxPlayers && is_user_connected(id));
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
