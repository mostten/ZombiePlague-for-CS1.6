/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Nemesis -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_weap_restrict_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_ZOMBIE "zp50_class_zombie"
#include <zp50_class_zombie>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>

// Default models
new const models_nemesis_player[][] = { "zombie_source" }
new const models_nemesis_claw[][] = { "models/zombie_plague/v_knife_zombie.mdl" }

#define MAXPLAYERS 32

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

new g_MaxPlayers

new cvar_nemesis_glow
new cvar_nemesis_aura, cvar_nemesis_aura_color_R, cvar_nemesis_aura_color_G, cvar_nemesis_aura_color_B
new cvar_nemesis_kill_explode
new cvar_nemesis_grenade_frost, cvar_nemesis_grenade_fire

new const nemesis_name[] = "Nemesis";
new const nemesis_info[] = "=Nemesis=";
new const nemesis_health = 0;
new const nemesis_base_health = 1800;
new const Float:nemesis_speed = 1.05;
new const Float:nemesis_gravity = 0.5;
new const bool:nemesis_infection = false;
new const Float:interval_primary_attack = 0.5;
new const Float:interval_secondary_attack = 0.8;
new const Float:damage_primary_attack = 15.0;
new const Float:damage_secondary_attack = 25.0;
new const bool:nemesis_blood = false;
new const Float:nemesis_knockback = 0.0;
new const Float:damage_multiplier = 2.0;

new g_Classid = ZP_INVALID_ZOMBIE_CLASS;

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_NEMESIS_INIT_PRE = 0,
	FW_NEMESIS_INIT_POST
};

new g_ForwardResult;
new g_Forwards[TOTAL_FORWARDS];

public plugin_init()
{
	register_plugin("[ZP] Class: Nemesis", ZP_VERSION_STRING, "Mostten")
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_nemesis_glow = register_cvar("zp_nemesis_glow", "1")
	cvar_nemesis_aura = register_cvar("zp_nemesis_aura", "1")
	cvar_nemesis_aura_color_R = register_cvar("zp_nemesis_aura_color_R", "150")
	cvar_nemesis_aura_color_G = register_cvar("zp_nemesis_aura_color_G", "0")
	cvar_nemesis_aura_color_B = register_cvar("zp_nemesis_aura_color_B", "0")
	cvar_nemesis_kill_explode = register_cvar("zp_nemesis_kill_explode", "1")
	cvar_nemesis_grenade_frost = register_cvar("zp_nemesis_grenade_frost", "0")
	cvar_nemesis_grenade_fire = register_cvar("zp_nemesis_grenade_fire", "1")
	
	g_Forwards[FW_NEMESIS_INIT_PRE] = CreateMultiForward("zp_fw_nemesis_init_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_NEMESIS_INIT_POST] = CreateMultiForward("zp_fw_nemesis_init_post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_precache()
{
	// reg nemesis
	g_Classid = zp_class_zombie_register(nemesis_name,
										nemesis_info,
										nemesis_health,
										nemesis_speed,
										nemesis_gravity,
										nemesis_infection,
										interval_primary_attack,
										interval_secondary_attack,
										damage_primary_attack,
										damage_secondary_attack,
										nemesis_blood,
										nemesis_base_health);
	
	zp_class_zombie_register_kb(g_Classid, nemesis_knockback);
	
	zp_class_zombie_register_dm(g_Classid, damage_multiplier);
	
	new index;
	// If we couldn't load from file, use and save default ones
	for (index = 0; index < sizeof models_nemesis_player; index++)
		zp_class_zombie_register_model(g_Classid, models_nemesis_player[index]);
	
	for (index = 0; index < sizeof models_nemesis_claw; index++)
		zp_class_zombie_register_claw(g_Classid, models_nemesis_claw[index]);
}

public plugin_natives()
{
	register_library("zp50_class_nemesis");
	register_native("zp_class_nemesis_get", "native_class_nemesis_get");
	register_native("zp_class_nemesis_set", "native_class_nemesis_set");
	register_native("zp_class_nemesis_get_count", "native_class_nemesis_get_count");
	register_native("zp_class_nemesis_get_maxhealth", "_class_nemesis_get_max_health");
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZOMBIE)
		|| equal(module, LIBRARY_GRENADE_FROST)
		|| equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	// Remove nemesis glow
	if (get_pcvar_num(cvar_nemesis_glow) && is_user_valid(id))
		set_user_rendering(id);
		
	// Remove nemesis aura
	if (get_pcvar_num(cvar_nemesis_aura))
		remove_aura_task(id);
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (is_user_nemesis(victim))
	{
		// Nemesis explodes!
		if (get_pcvar_num(cvar_nemesis_kill_explode))
			SetHamParamInteger(3, 2)
		
		// Remove nemesis aura
		if (get_pcvar_num(cvar_nemesis_aura))
			remove_aura_task(victim);
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Nemesis
	if (is_user_valid(id) && is_user_nemesis(id) && !get_pcvar_num(cvar_nemesis_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Nemesis
	if (is_user_valid(id) && is_user_nemesis(id) && !get_pcvar_num(cvar_nemesis_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (is_user_valid(id) && is_user_nemesis(id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
	}
	
	// Remove nemesis aura
	if (get_pcvar_num(cvar_nemesis_aura))
		remove_aura_task(id);
}

public zp_fw_core_cure(id, attacker)
{
	if (is_user_valid(id) && is_user_nemesis(id))
	{
		// Remove nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id)
	}
	
	// Remove nemesis aura
	if (get_pcvar_num(cvar_nemesis_aura))
		remove_aura_task(id);
}

public zp_fw_class_zombie_init_pre(id, classid)
{
	if(is_classid_valid(classid))
	{
		ExecuteForward(g_Forwards[FW_NEMESIS_INIT_PRE], g_ForwardResult, id, classid);
		
		return g_ForwardResult;
	}
	
	return PLUGIN_CONTINUE;
}

public zp_fw_class_zombie_init_post(id, classid)
{
	// Apply Nemesis attributes?
	if(is_classid_valid(classid))
	{
		// Nemesis glow
		if (get_pcvar_num(cvar_nemesis_glow))
			set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
		
		// Nemesis aura task
		if (get_pcvar_num(cvar_nemesis_aura))
		{
			remove_aura_task(id);
			set_task(0.1, "nemesis_aura", id+TASK_AURA, _, _, "b");
		}
		
		cs_set_player_weap_restrict(id, false);
		
		ExecuteForward(g_Forwards[FW_NEMESIS_INIT_POST], g_ForwardResult, id, classid);
	}
}

public zp_fw_class_zombie_select_pre(client, classid)
{
	if(is_classid_valid(classid))
		return ZP_CLASS_DONT_SHOW;
	return ZP_CLASS_AVAILABLE;
}

bool:is_classid_valid(classid)
{
	return g_Classid != ZP_INVALID_ZOMBIE_CLASS && g_Classid == classid;
}

public native_class_nemesis_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return is_user_nemesis(id);
}

public native_class_nemesis_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (is_user_nemesis(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a nemesis (%d)", id)
		return false;
	}
	
	return zp_class_zombie_set_current(id, g_Classid);
}

public native_class_nemesis_get_count(plugin_id, num_params)
{
	return GetNemesisCount();
}

public _class_nemesis_get_max_health(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return -1;
	}
	
	if (!is_user_nemesis(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player isn't nemesis (%d)", id)
		return -1;
	}
	
	return zp_class_zombie_get_max_health(id);
}

// Nemesis aura task
public nemesis_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_nemesis_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Get Nemesis Count -returns alive nemesis number-
GetNemesisCount()
{
	new players[MAXPLAYERS], num, iNemesis = 0;
	get_players(players, num, "a");
	for(new i = 0; i < num; i++)
	{
		if(is_user_nemesis(players[i]))
			iNemesis++;
	}
	return iNemesis;
}

remove_aura_task(id)
{
	if(task_exists(id+TASK_AURA, 0))
		remove_task(id+TASK_AURA, 0);
}

bool:is_user_valid(id)
{
	return (1 <= id <= g_MaxPlayers && is_user_connected(id));
}

bool:is_user_nemesis(id)
{
	return (LibraryExists(LIBRARY_ZOMBIE, LibType_Library)
			&& zp_core_is_zombie(id)
			&& is_classid_valid(zp_class_zombie_get_current(id)));
}