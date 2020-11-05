/*================================================================================
	
	------------------------
	-*- [ZP] Core/Engine -*-
	------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core_const>

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_INFECT_PRE = 0,
	FW_USER_INFECT,
	FW_USER_INFECT_POST,
	FW_USER_CURE_PRE,
	FW_USER_CURE,
	FW_USER_CURE_POST,
	FW_USER_LAST_ZOMBIE,
	FW_USER_LAST_HUMAN,
	FW_USER_LAST_HUMAN_DEAD,
	FW_USER_SPAWN_POST,
	FW_ZOMBIE_SPAWN_POST,
	FW_HUMAN_SPAWN_POST,
	FW_ZOMBIE_FLAG_ADD_POST,
	FW_ZOMBIE_FLAG_REMOVE_POST,
	FW_SET_USER_LIGHTSTYLE_PRE,
	FW_SET_USER_LIGHTSTYLE_POST,
	FW_SET_USER_SCREENFADE_PRE,
	FW_SET_USER_SCREENFADE_POST
}

enum UserInfo{
	UserInfo_Id = 0,
	bool:UserInfo_IsZombie,
	bool:UserInfo_IsFirstZombie,
	bool:UserInfo_IsLastZombie,
	bool:UserInfo_IsLastHuman,
	bool:UserInfo_RespawnAsZombie,
	bool:UserInfo_BlockClcorpse
};
new Array:g_UserInfo = Invalid_Array;

new g_MaxPlayers;
new g_MsgScreenFade;
new g_MsgScoreAttrib;
new g_MsgScoreInfo;
new g_MsgDeathMsg;
new g_MsgClCorpse;
new bool:g_LastZombieForwardCalled;
new bool:g_LastHumanForwardCalled;
new bool:g_LastHumanDeadForwardCalled;
new g_ForwardResult;
new g_Forwards[TOTAL_FORWARDS];

public plugin_init()
{
	register_plugin("[ZP] Core/Engine", ZP_VERSION_STRING, "ZP Dev Team")
	register_dictionary("zombie_plague.txt")
	register_dictionary("zombie_plague50.txt")
	register_dictionary("zombie_plague_zaphie.txt")
	
	g_Forwards[FW_USER_INFECT_PRE] = CreateMultiForward("zp_fw_core_infect_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECT] = CreateMultiForward("zp_fw_core_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_INFECT_POST] = CreateMultiForward("zp_fw_core_infect_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_Forwards[FW_USER_CURE_PRE] = CreateMultiForward("zp_fw_core_cure_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_CURE] = CreateMultiForward("zp_fw_core_cure", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_CURE_POST] = CreateMultiForward("zp_fw_core_cure_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_Forwards[FW_USER_LAST_ZOMBIE] = CreateMultiForward("zp_fw_core_last_zombie", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_HUMAN] = CreateMultiForward("zp_fw_core_last_human", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_LAST_HUMAN_DEAD] = CreateMultiForward("zp_fw_core_last_human_dead", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_Forwards[FW_USER_SPAWN_POST] = CreateMultiForward("zp_fw_core_spawn_post", ET_IGNORE, FP_CELL)
	g_Forwards[FW_ZOMBIE_SPAWN_POST] = CreateMultiForward("zp_fw_core_zombie_spawn_post", ET_IGNORE, FP_CELL)
	g_Forwards[FW_HUMAN_SPAWN_POST] = CreateMultiForward("zp_fw_core_human_spawn_post", ET_IGNORE, FP_CELL)
	
	g_Forwards[FW_ZOMBIE_FLAG_ADD_POST] = CreateMultiForward("zp_fw_core_zombie_add_post", ET_IGNORE, FP_CELL);
	g_Forwards[FW_ZOMBIE_FLAG_REMOVE_POST] = CreateMultiForward("zp_fw_core_zombie_remove_post", ET_IGNORE, FP_CELL);
	
	g_Forwards[FW_SET_USER_LIGHTSTYLE_PRE] = CreateMultiForward("zp_fw_core_set_lightstyle_pre", ET_CONTINUE, FP_CELL, FP_STRING);
	g_Forwards[FW_SET_USER_LIGHTSTYLE_POST] = CreateMultiForward("zp_fw_core_set_lightstyle_post", ET_IGNORE, FP_CELL, FP_STRING);
	
	g_Forwards[FW_SET_USER_SCREENFADE_PRE] = CreateMultiForward("zp_fw_core_set_screenfade_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	g_Forwards[FW_SET_USER_SCREENFADE_POST] = CreateMultiForward("zp_fw_core_set_screenfade_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	g_MsgScreenFade = get_user_msgid("ScreenFade");
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib");
	g_MsgScoreInfo = get_user_msgid("ScoreInfo");
	g_MsgDeathMsg = get_user_msgid("DeathMsg");
	g_MsgClCorpse = get_user_msgid ("ClCorpse");
	
	register_message(g_MsgClCorpse, "message_clcorpse");
	
	// To help players find ZP servers
	register_cvar("zp_version", ZP_VERSION_STR_LONG, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("zp_version", ZP_VERSION_STR_LONG)
}

public plugin_cfg()
{
	// Get configs dir
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	// Execute config file (zombieplague.cfg)
	server_cmd("exec %s/zombieplague.cfg", cfgdir)
}

public plugin_natives()
{
	register_library("zp50_core")
	register_native("zp_core_is_zombie", "native_core_is_zombie")
	register_native("zp_core_is_first_zombie", "native_core_is_first_zombie")
	register_native("zp_core_is_last_zombie", "native_core_is_last_zombie")
	register_native("zp_core_is_last_human", "native_core_is_last_human")
	register_native("zp_core_get_zombie_count", "native_core_get_zombie_count")
	register_native("zp_core_get_human_count", "native_core_get_human_count")
	register_native("zp_core_infect", "native_core_infect")
	register_native("zp_core_cure", "native_core_cure")
	register_native("zp_core_force_infect", "native_core_force_infect")
	register_native("zp_core_force_cure", "native_core_force_cure")
	register_native("zp_core_respawn_as_zombie", "native_core_respawn_as_zombie")
	register_native("zp_core_is_respawn_as_zombie", "native_core_is_respawn_as_zombie")
	register_native("zp_core_set_screenfade", "native_core_set_screenfade");
	register_native("zp_core_set_lightstyle", "native_core_set_lightstyle");
	register_native("zp_core_update_user_state", "native_core_update_user_state");
	register_native("zp_core_update_user_scoreboard", "native_update_user_scoreboard");
	register_native("zp_core_send_death_msg", "native_core_send_death_msg");
	register_native("zp_core_set_block_clcorpse_once", "_set_core_block_clcorpse_once");
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// Reset flags AFTER disconnect (to allow checking if the player was zombie before disconnecting)
	remove_user_zombie_flag(id);
	SetUserInfoValue(id, UserInfo_RespawnAsZombie, false);
	
	// This should be called AFTER client disconnects (post forward)
	CheckLastZombieHuman();
	
	RemoveUserInfo(id);
}

public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// ZP Spawn Forward
	ExecuteForward(g_Forwards[FW_USER_SPAWN_POST], g_ForwardResult, id);
	
	// Set zombie/human attributes upon respawn
	if (IsRespawnAsZombie(id))
	{
		if(InfectPlayer(id, id))
			ExecuteForward(g_Forwards[FW_ZOMBIE_SPAWN_POST], g_ForwardResult, id);
	}
	else
	{
		CurePlayer(id);
		ExecuteForward(g_Forwards[FW_HUMAN_SPAWN_POST], g_ForwardResult, id);
	}
	// Reset flag afterwards
	SetUserInfoValue(id, UserInfo_RespawnAsZombie, false);
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	CheckLastZombieHuman();
	CheckLastHumanDead(victim, attacker);
}

bool:InfectPlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_INFECT_PRE], g_ForwardResult, id, attacker)
	
	// One or more plugins blocked infection
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return false;
	
	ExecuteForward(g_Forwards[FW_USER_INFECT], g_ForwardResult, id, attacker)
	
	add_user_zombie_flag(id);
	
	if (GetZombieCount() == 1)
		SetUserInfoValue(id, UserInfo_IsFirstZombie, true);
	else
		SetUserInfoValue(id, UserInfo_IsFirstZombie, false);
	
	ExecuteForward(g_Forwards[FW_USER_INFECT_POST], g_ForwardResult, id, attacker)
	
	CheckLastZombieHuman()
	
	return true;
}

CurePlayer(id, attacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_CURE_PRE], g_ForwardResult, id, attacker);
	
	// One or more plugins blocked cure
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	ExecuteForward(g_Forwards[FW_USER_CURE], g_ForwardResult, id, attacker);
	
	remove_user_zombie_flag(id);
	
	ExecuteForward(g_Forwards[FW_USER_CURE_POST], g_ForwardResult, id, attacker);
	
	CheckLastZombieHuman();
}

// Last Zombie/Human Check
CheckLastZombieHuman()
{
	new id, last_zombie_id, last_human_id
	new zombie_count = GetZombieCount()
	new human_count = GetHumanCount()
	
	if (zombie_count == 1)
	{
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			// Last zombie
			if (is_user_alive(id) && IsZombie(id))
			{
				SetUserInfoValue(id, UserInfo_IsLastZombie, true);
				last_zombie_id = id
			}
			else
				SetUserInfoValue(id, UserInfo_IsLastZombie, false);
		}
	}
	else
	{
		g_LastZombieForwardCalled = false
		
		for (id = 1; id <= g_MaxPlayers; id++)
			SetUserInfoValue(id, UserInfo_IsLastZombie, false);
	}
	
	// Last zombie forward
	if (last_zombie_id > 0 && !g_LastZombieForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE], g_ForwardResult, last_zombie_id)
		g_LastZombieForwardCalled = true
	}
	
	if (human_count == 1)
	{
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			// Last human
			if (is_user_alive(id) && !IsZombie(id))
			{
				SetUserInfoValue(id, UserInfo_IsLastHuman, true);
				last_human_id = id;
			}
			else
				SetUserInfoValue(id, UserInfo_IsLastHuman, false);
		}
	}
	else
	{
		g_LastHumanForwardCalled = false
		
		for (id = 1; id <= g_MaxPlayers; id++)
			SetUserInfoValue(id, UserInfo_IsLastHuman, false);
	}
	
	// Last human forward
	if (last_human_id > 0 && !g_LastHumanForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN], g_ForwardResult, last_human_id)
		g_LastHumanForwardCalled = true;
		g_LastHumanDeadForwardCalled = false;
	}
}

CheckLastHumanDead(victim, attacker)
{
	if(!IsZombie(victim)
	&& GetHumanCount() == 0
	&& !g_LastHumanDeadForwardCalled)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN_DEAD], g_ForwardResult, victim, attacker);
		g_LastHumanDeadForwardCalled = true;
	}
}

public native_core_is_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return IsZombie(id);
}

public native_core_is_first_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return IsFirstZombie(id);
}

public native_core_is_last_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return IsLastZombie(id);
}

public native_core_is_last_human(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return IsLastHuman(id);
}

public native_core_get_zombie_count(plugin_id, num_params)
{
	return GetZombieCount();
}

public native_core_get_human_count(plugin_id, num_params)
{
	return GetHumanCount();
}

public native_core_infect(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (IsZombie(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already infected (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_connected(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", attacker)
		return false;
	}
	
	InfectPlayer(id, attacker)
	return true;
}

public native_core_cure(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (!IsZombie(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player not infected (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_connected(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", attacker)
		return false;
	}
	
	CurePlayer(id, attacker)
	return true;
}

public native_core_force_infect(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	InfectPlayer(id)
	return true;
}

public native_core_force_cure(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	CurePlayer(id)
	return true;
}

public native_core_respawn_as_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new respawn_as_zombie = get_param(2)
	
	if (respawn_as_zombie)
		SetUserInfoValue(id, UserInfo_RespawnAsZombie, true);
	else
		SetUserInfoValue(id, UserInfo_RespawnAsZombie, false);
	
	return true;
}

public native_core_is_respawn_as_zombie(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	return IsRespawnAsZombie(id);
}

public native_core_set_screenfade(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return false;
	}
	
	new duration = get_param(2);
	new hold_time = get_param(3);
	new fade_type = get_param(4);
	new red = get_param(5);
	new green = get_param(6);
	new blue = get_param(7);
	new alpha = get_param(8);
	new bool:call_forward = bool:get_param(9);
	set_user_screenfade(id, duration, hold_time, fade_type, red, green, blue, alpha, call_forward);
	return true;
}

set_user_screenfade(client, duration, hold_time, fade_type, red, green, blue, alpha, bool:call_forward = true)
{
	if(call_forward)
	{
		ExecuteForward(g_Forwards[FW_SET_USER_SCREENFADE_PRE], g_ForwardResult, client, duration, hold_time, fade_type, red, green, blue, alpha);
		if(g_ForwardResult >= PLUGIN_HANDLED)
			return;
	}
	
	message_begin(MSG_ONE, g_MsgScreenFade, .player = client);
	write_short(duration);
	write_short(hold_time);
	write_short(fade_type);
	write_byte(red);
	write_byte(green);
	write_byte(blue);
	write_byte(alpha);
	message_end();
	
	if(call_forward)
		ExecuteForward(g_Forwards[FW_SET_USER_SCREENFADE_POST], g_ForwardResult, client, duration, hold_time, fade_type, red, green, blue, alpha);
}

public native_core_set_lightstyle(plugin_id, num_params)
{
	new id = get_param(1);
	new light_style[ZP_LIGHTSTYLE_LENGTH];
	get_string(2, light_style, charsmax(light_style));
	new bool:call_forward = bool:get_param(3);
	set_user_lightstyle(id, light_style, call_forward);
}

set_user_lightstyle(client, const light_style[ZP_LIGHTSTYLE_LENGTH], bool:call_forward = true)
{
	if(call_forward)
	{
		ExecuteForward(g_Forwards[FW_SET_USER_LIGHTSTYLE_PRE], g_ForwardResult, client, light_style);
		if(g_ForwardResult >= PLUGIN_HANDLED)
			return;
	}
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = client);
	write_byte(0);
	write_string(light_style);
	message_end();
	
	if(call_forward)
		ExecuteForward(g_Forwards[FW_SET_USER_LIGHTSTYLE_POST], g_ForwardResult, client, light_style);
}

public native_core_update_user_state(plugin_id, num_params)
{
	new id = get_param(1);
	new user_state = get_param(2);
	update_user_state(id, user_state);
}

update_user_state(client, user_state)
{
	message_begin(MSG_BROADCAST, g_MsgScoreAttrib);
	write_byte(client); // id
	write_byte(user_state); // 0 - nothing, 1 - dead, 2 - bomb 
	message_end();
}

public native_update_user_scoreboard(plugin_id, num_params)
{
	new id = get_param(1);
	update_user_scoreboard(id);
}

update_user_scoreboard(client)
{
	message_begin(MSG_BROADCAST, g_MsgScoreInfo);
	write_byte(client); // id
	write_short(pev(client, pev_frags)); // frags
	write_short(cs_get_user_deaths(client)); // deaths
	write_short(0); // class?
	write_short(_:cs_get_user_team(client)); // team
	message_end();
}

public native_core_send_death_msg(plugin_id, num_params)
{
	new attacker = get_param(1);
	new victim = get_param(2);
	new bool:headshot = bool:get_param(3);
	new killer_weapon[32];
	get_string(4, killer_weapon, charsmax(killer_weapon));
	
	send_death_msg(attacker, victim, headshot, killer_weapon);
}

public _set_core_block_clcorpse_once(plugin_id, num_params)
{
	new id = get_param(1);
	new bool:block = bool:get_param(2);
	
	SetUserInfoValue(id, UserInfo_BlockClcorpse, block);
}

// Send Death Message
send_death_msg(attacker, victim, bool:headshot = false, const killer_weapon[] = "")
{
	message_begin(MSG_BROADCAST, g_MsgDeathMsg);
	write_byte(attacker); // killer
	write_byte(victim); // victim
	write_byte(headshot?1:0); // headshot flag
	
	// killer's weapon
	if(!strlen(killer_weapon))
	{
		new weapon_name[32], truncated[32];
		new weapon = cs_get_user_weapon(attacker);
		get_weaponname(weapon, weapon_name, charsmax(weapon_name));
		new index = 0;
		for(new i = strlen("weapon_"); i < charsmax(weapon_name); i++)
		{
			truncated[index] = weapon_name[i];
			index++;
		}
		write_string(truncated);
	}else{write_string(killer_weapon);}
	
	message_end();
}

public message_clcorpse(msg_id, msg_dest, msg_entity)
{
	new id = get_msg_arg_int(12);
	
	if(IsUserBlockClcorpse(id))
	{
		SetUserInfoValue(id, UserInfo_BlockClcorpse, false);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

add_user_zombie_flag(id)
{
	SetUserInfoValue(id, UserInfo_IsZombie, true);
	ExecuteForward(g_Forwards[FW_ZOMBIE_FLAG_ADD_POST], g_ForwardResult, id);
}

remove_user_zombie_flag(id)
{
	SetUserInfoValue(id, UserInfo_IsZombie, false);
	ExecuteForward(g_Forwards[FW_ZOMBIE_FLAG_REMOVE_POST], g_ForwardResult, id);
}

// Get Zombie Count -returns alive zombies number-
GetZombieCount()
{
	new iZombies, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && IsZombie(id))
			iZombies++
	}
	
	return iZombies;
}

// Get Human Count -returns alive humans number-
GetHumanCount()
{
	new iHumans, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && !IsZombie(id))
			iHumans++
	}
	
	return iHumans;
}

ArraysInit()
{
	if(g_UserInfo == Invalid_Array)
		g_UserInfo = ArrayCreate(_:UserInfo, 1);
}

bool:IsZombie(const id)
{
	new bool:iszombie = false;
	return GetUserInfoValue(id, UserInfo_IsZombie, iszombie) && iszombie;
}

bool:IsFirstZombie(const id)
{
	new bool:isfirst = false;
	return GetUserInfoValue(id, UserInfo_IsFirstZombie, isfirst) && isfirst;
}

bool:IsLastZombie(const id)
{
	new bool:islast = false;
	return GetUserInfoValue(id, UserInfo_IsLastZombie, islast) && islast;
}

bool:IsLastHuman(const id)
{
	new bool:islast = false;
	return GetUserInfoValue(id, UserInfo_IsLastHuman, islast) && islast;
}

bool:IsRespawnAsZombie(const id)
{
	new bool:aszombie = false;
	return GetUserInfoValue(id, UserInfo_RespawnAsZombie, aszombie) && aszombie;
}

bool:IsUserBlockClcorpse(const id)
{
	new bool:block = false;
	return GetUserInfoValue(id, UserInfo_BlockClcorpse, block) && block;
}

SetUserInfoValue(const id, const UserInfo:info_type, const any:value)
{
	ArraysInit();
	
	new any:infos[_:UserInfo];
	new index = GetUserInfo(id, infos);
	if(index < 0)
	{
		for(new i = 0; i < sizeof(infos); i++){infos[i] = false;}
		
		infos[_:UserInfo_Id] = id;
		infos[_:info_type] = value;
		
		index = ArrayPushArray(g_UserInfo, infos);
	}
	else
	{
		infos[_:info_type] = value;
		ArraySetArray(g_UserInfo, index, infos);
	}
	
	return index;
}

bool:GetUserInfoValue(const id, const UserInfo:info_type, &any:result)
{
	new any:infos[_:UserInfo];
	
	if(GetUserInfo(id, infos) >= 0)
	{
		result = infos[_:info_type];
		return true;
	}
	
	return false;
}

GetUserInfo(const id, any:infos[_:UserInfo])
{
	new index = GetUserInfoIndex(id);
	
	if(index >= 0){ArrayGetArray(g_UserInfo, index, infos);}
	
	return index;
}

GetUserInfoIndex(const id)
{
	if(g_UserInfo == Invalid_Array){return -1;}
	
	new count = ArraySize(g_UserInfo);
	if(count <= 0){return -1;}
	
	new any:infos[_:UserInfo];
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_UserInfo, i, infos);
		
		if(infos[_:UserInfo_Id] == id){return i;}
	}
	
	return -1;
}

bool:RemoveUserInfo(const id)
{
	new index = GetUserInfoIndex(id);
	
	if(index >= 0)
	{
		ArrayDeleteItem(g_UserInfo, index);
		return true;
	}
	return false;
}