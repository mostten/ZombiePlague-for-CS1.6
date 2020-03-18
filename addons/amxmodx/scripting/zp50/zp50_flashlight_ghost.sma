#include <amxmodx>
#include <engine>
#include <fakemeta>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Zombie Plague 5.0 Includes]
=================================================================================*/

#include <cs_ham_bots_api>
#define LIBRARY_ZP50_CORE "zp50_core"
#include <zp50_core>
#define LIBRARY_ZP50_GAMEMODES "zp50_gamemodes"
#include <zp50_gamemodes>
#define LIBRARY_FLASHLIGHT "zp50_flashlight"
#include <zp50_flashlight>
#define LIBRARY_CLASS_GHOST "zp50_class_ghost"
#include <zp50_class_ghost>
#include <zp50_colorchat>
/*================================================================================
 [Plugin Customization]
=================================================================================*/

// only for testing :)
//#define TEST_3RD

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/
#define MAXPLAYERS 32

new const PLUGIN_VERSION[] = "2.0 (zp50)";

#define FM_PDATA_SAFE 2

new const model_lightcone[] = "models/css_lightcone2.mdl";

#if defined TEST_3RD
new const model_3rd_person[] = "models/rpgrocket.mdl";
#endif

new bs_Flashlight, bs_IsAlive, bs_IsBot;
new g_iLightConeIndex[MAXPLAYERS+1];

new g_iZombiePlague;
new g_varFlashlight;
new g_varShowAllMod;
new bool:g_bIsGhostMod = false;

#define add_bitsum(%1,%2) (%1 |= (1<<(%2-1)))
#define del_bitsum(%1,%2) (%1 &= ~(1<<(%2-1)))
#define get_bitsum(%1,%2) (%1 & (1<<(%2-1)))

/*================================================================================
 [Precache, Init]
=================================================================================*/

public plugin_precache()
{
	if (!LibraryExists(LIBRARY_ZP50_CORE, LibType_Library) || !LibraryExists(LIBRARY_ZP50_GAMEMODES, LibType_Library))
		return;
	
	g_iZombiePlague = 1;
	precache_model(model_lightcone);
	
	#if defined TEST_3RD
	precache_model(model_3rd_person);
	#endif
}

public plugin_init()
{
	register_plugin("[ZP] Ghost Mod Flashlight", PLUGIN_VERSION, "mostten");
	g_varFlashlight = register_cvar("ghost_mod_flashlight", "1");
	g_varShowAllMod = register_cvar("ghost_mod_flashlight_show_all", "0");
	
	if (!g_iZombiePlague)
		return;
	
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1);
	RegisterHamBots(Ham_Spawn, "fwd_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled");
	RegisterHamBots(Ham_Killed, "fwd_PlayerKilled");
	
	register_message(get_user_msgid("Flashlight"), "message_flashlight");
	
	#if defined TEST_3RD
	register_clcmd("say 1st", "clcmd_1st");
	register_clcmd("say 3rd", "clcmd_3rd");
	#endif
	
	if (!LibraryExists(LIBRARY_FLASHLIGHT, LibType_Library))
		return;
}

public plugin_natives()
{
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZP50_CORE) || equal(module, LIBRARY_ZP50_GAMEMODES) || equal(module, LIBRARY_FLASHLIGHT) || equal(module, LIBRARY_CLASS_GHOST))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

/*================================================================================
 [Zombie Plague Forwards]
=================================================================================*/

public zp_fw_gamemodes_start(game_mode_id)
{
	g_bIsGhostMod = (LibraryExists(LIBRARY_CLASS_GHOST, LibType_Library) && game_mode_id == zp_gamemodes_get_id("Ghost Mode"));
	set_all_cone_draw(true);
}

public zp_fw_gamemodes_end()
{
	g_bIsGhostMod = false;
	set_all_cone_draw(false);
}

public zp_fw_core_infect_post(client, attacker)
{
	remove_task(client);
	
	del_bitsum(bs_Flashlight, client);
	set_client_cone_draw(client, false);
}

public zp_fw_core_cure_post(client, attacker)
{
	remove_task(client);
	
	del_bitsum(bs_Flashlight, client);
	set_client_cone_draw(client, false);
	
	if (get_bitsum(bs_IsBot, client))
		set_lightcone(client);
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_PlayerSpawn_Post(client)
{
	if (!is_user_alive(client))
		return;
	
	add_bitsum(bs_IsAlive, client);
	
	remove_task(client)
	del_bitsum(bs_Flashlight, client);
	set_client_cone_draw(client, false)
	
	if (get_bitsum(bs_IsBot, client))
		set_lightcone(client)
	
	#if defined TEST_3RD
	clcmd_1st(client)
	client_print(client, print_chat, "Test: first persion view say ^"1st^" for third persion view ^"3rd^"")
	#endif
}

public fwd_PlayerKilled(victim, attacker, shouldgib)
{
	del_bitsum(bs_IsAlive, victim);
	
	remove_task(victim)
	del_bitsum(bs_Flashlight, victim);
	set_client_cone_draw(victim, false)
}

public client_putinserver(client)
{
	if (is_user_bot(client))
	{
		add_bitsum(bs_IsBot, client);
	}
	else
	{
		del_bitsum(bs_IsBot, client);
	}
}

public client_disconnect(client)
{
	del_bitsum(bs_IsAlive, client);
	del_bitsum(bs_IsBot, client);
	
	remove_task(client);
	del_bitsum(bs_Flashlight, client);
	
	remove_client_cone(client);
}

/*================================================================================
 [Client Commands]
=================================================================================*/

#if defined TEST_3RD
public clcmd_1st(client)
{
	if (!get_bitsum(bs_IsAlive, client))
		return
	
	set_view(client, CAMERA_NONE)
}

public clcmd_3rd(client)
{
	if (!get_bitsum(bs_IsAlive, client))
		return
	
	set_view(client, CAMERA_3RDPERSON)
}
#endif

/*================================================================================
 [Message Hooks]
=================================================================================*/

public message_flashlight(msg_id, msg_dest, msg_entity)
{
	get_msg_arg_int(1) ? add_bitsum(bs_Flashlight, msg_entity) : del_bitsum(bs_Flashlight, msg_entity);
	
	set_lightcone(msg_entity)
}

/*================================================================================
 [Cone Logic]
=================================================================================*/

set_lightcone(client)
{
	remove_task(client)
	if (get_bitsum(bs_Flashlight, client) || get_bitsum(bs_IsBot, client))
	{
		set_task(0.2, "zp_have_battery", client, _, _, "b")
		if (!client_cone_valid(client))
		{
			create_cone_for_client(client)
		}
		else
		{
			set_cone_draw(get_client_cone(client), is_class_show_allow(client));
		}
	}
	else set_client_cone_draw(client, false);
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

public zp_have_battery(client)
{
	if (!zp_flashlight_get_charge(client))
	{
		remove_task(client)
		del_bitsum(bs_Flashlight, client);
		set_client_cone_draw(client, false);
	}
}

get_client_cone(client)
{
	return g_iLightConeIndex[client];
}

set_client_cone(client, entity)
{
	g_iLightConeIndex[client] = entity;
}

bool:client_cone_valid(client)
{
	new entity = get_client_cone(client);
	return (entity && pev_valid(entity));
}

bool:create_cone_for_client(client)
{
	static info;
	if (!info) info = engfunc(EngFunc_AllocString, "info_target");
	
	new entity = engfunc(EngFunc_CreateNamedEntity, info);
	
	if (pev_valid(entity))
	{
		engfunc(EngFunc_SetModel, entity, model_lightcone);
		set_pev(entity, pev_owner, client);
		set_pev(entity, pev_movetype, MOVETYPE_FOLLOW);
		set_pev(entity, pev_aiment, client);
		set_client_cone(client, entity);
		set_cone_draw(entity, is_class_show_allow(client));
		return true;
	}
	set_client_cone(client, 0);
	return false;
}

set_cone_draw(entity, bool:draw)
{
	if (draw && get_pcvar_num(g_varFlashlight))
	{
		set_pev(entity, pev_effects, (get_pcvar_num(g_varShowAllMod) || g_bIsGhostMod)?0:EF_NODRAW);
	}
	else
	{
		set_pev(entity, pev_effects, EF_NODRAW);
	}
}

set_all_cone_draw(bool:draw)
{
	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		if(is_user_connected(client) && is_user_alive(client))
			set_client_cone_draw(client, draw);
	}
}

set_client_cone_draw(client, bool:draw)
{
	new entity = get_client_cone(client);
	if (client_cone_valid(client))
		set_cone_draw(entity, is_class_show_allow(client)?draw:false);
}

remove_cone(entity)
{
	if (entity && pev_valid(entity))
		engfunc(EngFunc_RemoveEntity, entity);
}

remove_client_cone(client)
{
	remove_cone(get_client_cone(client));
	set_client_cone(client, 0);
}

bool:is_class_show_allow(client)
{
	if(zp_class_ghost_get(client) || zp_core_is_zombie(client))
		return false;
	return true;
}
