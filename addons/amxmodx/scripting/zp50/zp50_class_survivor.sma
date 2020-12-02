/*================================================================================
	
	----------------------------
	-*- [ZP] Class: Survivor -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>

#define LIBRARY_HUMAN "zp50_class_human"
#include <zp50_class_human>

#define MAXPLAYERS 32

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

// CS Player CBase Offsets (win32)
new const PDATA_SAFE = 2
new const OFFSET_ACTIVE_ITEM = 373

// Weapon bitsums
new const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
new const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
new const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define GRENADES_ONLY 4

new cvar_survivor_glow
new cvar_survivor_aura, cvar_survivor_aura_color_R, cvar_survivor_aura_color_G, cvar_survivor_aura_color_B
new cvar_survivor_weapon_block

new const survivor_name[] = "Survivor";
new const survivor_info[] = "=Survivor=";
new const survivor_models[][] = { "leet", "sas" }
new const survivor_weapon[] = "weapon_m249";
new const survivor_view_weapon[] = "models/v_m249.mdl";
new const survivor_health = 100;
new const survivor_base_health = 100;
new const Float:survivor_speed = 0.95;
new const Float:survivor_gravity = 1.25;
new const bool:survivor_infection = false;
new const Float:damage_multiplier = 1.0;

new g_Classid = ZP_INVALID_HUMAN_CLASS;

new g_MaxPlayers;

public plugin_init()
{
	register_plugin("[ZP] Class: Survivor", ZP_VERSION_STRING, "Mostten")
	
	register_clcmd("drop", "clcmd_drop")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	cvar_survivor_glow = register_cvar("zp_survivor_glow", "1")
	cvar_survivor_aura = register_cvar("zp_survivor_aura", "1")
	cvar_survivor_aura_color_R = register_cvar("zp_survivor_aura_color_R", "0")
	cvar_survivor_aura_color_G = register_cvar("zp_survivor_aura_color_G", "0")
	cvar_survivor_aura_color_B = register_cvar("zp_survivor_aura_color_B", "150")
	cvar_survivor_weapon_block = register_cvar("zp_survivor_weapon_block", "1")
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	g_Classid = zp_class_human_register(survivor_name,
										survivor_info,
										survivor_health,
										survivor_speed,
										survivor_gravity,
										survivor_infection,
										survivor_base_health);
	
	for (new index = 0; index < sizeof survivor_models; index++)
		zp_class_human_register_model(g_Classid, survivor_models[index]);
	
	zp_class_human_register_weapon(g_Classid, survivor_weapon);
	zp_class_human_register_vm(g_Classid, survivor_view_weapon);
	zp_class_human_register_dm(g_Classid, damage_multiplier);
	
	set_module_filter("module_filter");
	set_native_filter("native_filter");
}

public module_filter(const module[])
{
	if (equal(module, LIBRARY_HUMAN))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public plugin_natives()
{
	register_library("zp50_class_survivor")
	register_native("zp_class_survivor_get", "native_class_survivor_get")
	register_native("zp_class_survivor_set", "native_class_survivor_set")
	register_native("zp_class_survivor_get_classid", "_class_survivor_get_classid");
	register_native("zp_class_survivor_get_count", "native_class_survivor_get_count")
	register_native("zp_class_survivor_get_maxhealth", "_class_survivor_get_max_health")
}

public client_disconnected(id)
{
	// Remove survivor glow
	if (get_pcvar_num(cvar_survivor_glow) && is_user_valid(id))
		set_user_rendering(id)
		
	// Remove survivor aura
	if (get_pcvar_num(cvar_survivor_aura))
		remove_user_aura(id);
}

public clcmd_drop(id)
{
	// Should survivor stick to his weapon?
	if (is_user_survivor(id) && get_pcvar_num(cvar_survivor_weapon_block))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weapon, id)
{
	// Should survivor stick to his weapon?
	if (get_pcvar_num(cvar_survivor_weapon_block) && is_user_alive(id) && is_user_survivor(id))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	// Remove survivor aura
	if (get_pcvar_num(cvar_survivor_aura))
		remove_user_aura(victim);
}

public zp_fw_core_spawn_post(id)
{
	if (is_user_survivor(id))
	{
		// Remove survivor glow
		if (get_pcvar_num(cvar_survivor_glow))
			set_user_rendering(id);
	}
	
	// Remove survivor aura
	if (get_pcvar_num(cvar_survivor_aura))
		remove_user_aura(id);
}

public zp_fw_core_infect(id, attacker)
{
	zp_fw_core_spawn_post(id);
}

public zp_fw_class_human_init_pre(id, classid)
{
	if (is_classid_valid(classid))
	{
		// Strip current weapons
		strip_weapons(id, PRIMARY_ONLY);
		strip_weapons(id, SECONDARY_ONLY);
		strip_weapons(id, GRENADES_ONLY);
	}
	return PLUGIN_CONTINUE;
}

public zp_fw_class_human_init_post(id, classid)
{
	if(is_classid_valid(classid))
	{
		// Survivor glow
		if (get_pcvar_num(cvar_survivor_glow))
			set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 25);
		
		// Survivor aura task
		if (get_pcvar_num(cvar_survivor_aura))
			set_task(0.1, "survivor_aura", id+TASK_AURA, _, _, "b");
	}
}

public zp_fw_class_human_select_pre(client, classid)
{
	if(is_classid_valid(classid))
		return ZP_CLASS_DONT_SHOW;
	return ZP_CLASS_AVAILABLE;
}

public native_class_survivor_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return is_user_survivor(id);
}

public native_class_survivor_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (is_user_survivor(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a survivor (%d)", id)
		return false;
	}
	
	return zp_class_human_set_current(id, g_Classid);
}

public native_class_survivor_get_count(plugin_id, num_params)
{
	return GetSurvivorCount();
}

public _class_survivor_get_max_health(plugin_id, num_params)
{
	new id = get_param(1);
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id);
		return -1;
	}
	
	return zp_class_human_get_max_health(id);
}

public _class_survivor_get_classid(plugin_id, num_params)
{
	return g_Classid;
}

// Survivor aura task
public survivor_aura(taskid)
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
	write_byte(50) // radius
	write_byte(get_pcvar_num(cvar_survivor_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_survivor_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_survivor_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Get Survivor Count -returns alive survivors number-
GetSurvivorCount()
{
	new players[MAXPLAYERS], num, iSurvivors = 0;
	get_players(players, num, "a");
	for(new i = 0; i < num; i++)
	{
		if(is_user_survivor(players[i]))
			iSurvivors++;
	}
	return iSurvivors;
}

// Strip primary/secondary/grenades
stock strip_weapons(id, stripwhat)
{
	// Get user weapons
	new weapons[32], num_weapons, index, weaponid
	get_user_weapons(id, weapons, num_weapons)
	
	// Loop through them and drop primaries or secondaries
	for (index = 0; index < num_weapons; index++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[index]
		
		if ((stripwhat == PRIMARY_ONLY && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		|| (stripwhat == SECONDARY_ONLY && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		|| (stripwhat == GRENADES_ONLY && ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			new wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			
			// Strip weapon and remove bpammo
			ham_strip_weapon(id, wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock ham_strip_weapon(index, const weapon[])
{
	// Get weapon id
	new weaponid = get_weaponid(weapon)
	if (!weaponid)
		return false;
	
	// Get weapon entity
	new weapon_ent = fm_find_ent_by_owner(-1, weapon, index)
	if (!weapon_ent)
		return false;
	
	// If it's the current weapon, retire first
	new current_weapon_ent = fm_cs_get_current_weapon_ent(index)
	new current_weapon = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	if (current_weapon == weaponid)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent)
	
	// Remove weapon from player
	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weapon_ent))
		return false;
	
	// Kill weapon entity and fix pev_weapons bitsum
	ExecuteHamB(Ham_Item_Kill, weapon_ent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))
	return true;
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}

remove_user_aura(id)
{
	if(task_exists(id+TASK_AURA, 0)){remove_task(id+TASK_AURA);}
}

bool:is_classid_valid(classid)
{
	return g_Classid != ZP_INVALID_HUMAN_CLASS && g_Classid == classid;
}

bool:is_user_survivor(id)
{
	return (!zp_core_is_zombie(id) && LibraryExists(LIBRARY_HUMAN, LibType_Library) && is_classid_valid(zp_class_human_get_current(id)));
}

bool:is_user_valid(id)
{
	return (1 <= id <= g_MaxPlayers && is_user_connected(id));
}