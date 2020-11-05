/*================================================================================
	
	-------------------------------
	-*- [ZP] Game Modes Manager -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
	-TODO: cvar prevent consecutive modes (should work for all except default)
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_class_human>
#include <zp50_gamemodes_const>
#define LIBRARY_ZAPHIE "zp50_class_zaphie"
#include <zp50_class_zaphie>

#define HAM_ZAPHIE HAM_DoZaphieDamage(victim, attacker, damage)
#define HAM_ZOMBIE HAM_DoZombieDamage(victim, attacker, damage)

#define TASK_GAMEMODE 100

#define MAXPLAYERS 32
// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373
const OFFSSET_NEXTATTACK = 83
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const OFFSET_NEXTPRIMARYATTACK = 46
const OFFSET_NEXTSECONDARYATTACK = 47
const OFFSET_TIME_WEAPONIDLE = 48

// HUD messages
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.12

enum _:TOTAL_FORWARDS
{
	FW_GAME_MODE_CHOOSE_PRE = 0,
	FW_GAME_MODE_CHOOSE_POST,
	FW_GAME_MODE_START,
	FW_GAME_MODE_END,
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers
new g_HudSync

new cvar_gamemode_delay, cvar_round_start_show_hud,
	cvar_prevent_consecutive, cvar_last_man_infection;

// Game Modes data
new Array:g_GameModeName
new Array:g_GameModeFileName
new g_GameModeCount
new g_DefaultGameMode = 0 // first game mode is used as default if none specified
new g_ChosenGameMode = ZP_NO_GAME_MODE
new g_CurrentGameMode = ZP_NO_GAME_MODE
new g_LastGameMode = ZP_NO_GAME_MODE

new g_AllowInfection
new Float:g_NextAttackTime[MAXPLAYERS+1]
new AttackType:g_AttackType[MAXPLAYERS+1]

enum AttackType{
	AttackType_Primary = 0,
	AttackType_Secondary,
	AttackType_Other
}

enum ClassTeam{
	ClassTeam_Human = 0,
	ClassTeam_Zombie
}

public plugin_init()
{
	register_plugin("[ZP] Game Modes Manager", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("TextMsg", "event_game_restart", "a", "2=#Game_will_restart_in")
	
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_KnifePrimaryAttack")
	RegisterHamBots(Ham_Weapon_PrimaryAttack, "fw_KnifePrimaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_KnifeSecondaryAttack")
	RegisterHamBots(Ham_Weapon_SecondaryAttack, "fw_KnifeSecondaryAttack")
	
	cvar_gamemode_delay = register_cvar("zp_gamemode_delay", "10")
	cvar_round_start_show_hud = register_cvar("zp_round_start_show_hud", "1")
	cvar_prevent_consecutive = register_cvar("zp_prevent_consecutive_modes", "1")
	cvar_last_man_infection = register_cvar("zp_last_man_infection", "1")
	
	g_Forwards[FW_GAME_MODE_CHOOSE_PRE] = CreateMultiForward("zp_fw_gamemodes_choose_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_GAME_MODE_CHOOSE_POST] = CreateMultiForward("zp_fw_gamemodes_choose_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_GAME_MODE_START] = CreateMultiForward("zp_fw_gamemodes_start", ET_IGNORE, FP_CELL)
	g_Forwards[FW_GAME_MODE_END] = CreateMultiForward("zp_fw_gamemodes_end", ET_IGNORE, FP_CELL)
	
	g_MaxPlayers = get_maxplayers()
	g_HudSync = CreateHudSyncObj()
}

public plugin_natives()
{
	register_library("zp50_gamemodes")
	register_native("zp_gamemodes_register", "native_gamemodes_register")
	register_native("zp_gamemodes_set_default", "native_gamemodes_set_default")
	register_native("zp_gamemodes_get_default", "native_gamemodes_get_default")
	register_native("zp_gamemodes_get_chosen", "native_gamemodes_get_chosen")
	register_native("zp_gamemodes_get_current", "native_gamemodes_get_current")
	register_native("zp_gamemodes_get_id", "native_gamemodes_get_id")
	register_native("zp_gamemodes_get_name", "native_gamemodes_get_name")
	register_native("zp_gamemodes_start", "native_gamemodes_start")
	register_native("zp_gamemodes_get_count", "native_gamemodes_get_count")
	register_native("zp_gamemodes_set_allow_infect", "_gamemodes_set_allow_infect")
	register_native("zp_gamemodes_get_allow_infect", "_gamemodes_get_allow_infect")
	
	// Initialize dynamic arrays
	g_GameModeName = ArrayCreate(32, 1)
	g_GameModeFileName = ArrayCreate(64, 1)
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_ZAPHIE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_gamemodes_register(plugin_id, num_params)
{
	new name[32], filename[64]
	get_string(1, name, charsmax(name))
	get_plugin(plugin_id, filename, charsmax(filename))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register game mode with an empty name")
		return ZP_INVALID_GAME_MODE;
	}
	
	new index, gamemode_name[32]
	for (index = 0; index < g_GameModeCount; index++)
	{
		ArrayGetString(g_GameModeName, index, gamemode_name, charsmax(gamemode_name))
		if (equali(name, gamemode_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Game mode already registered (%s)", name)
			return ZP_INVALID_GAME_MODE;
		}
	}
	
	ArrayPushString(g_GameModeName, name)
	ArrayPushString(g_GameModeFileName, filename)
	
	// Pause Game Mode plugin after registering
	pause("ac", filename)
	
	g_GameModeCount++
	return g_GameModeCount - 1;
}

public native_gamemodes_set_default(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	g_DefaultGameMode = game_mode_id
	return true;
}

public native_gamemodes_get_default(plugin_id, num_params)
{
	return g_DefaultGameMode;
}

public native_gamemodes_get_chosen(plugin_id, num_params)
{
	return g_ChosenGameMode;
}

public native_gamemodes_get_current(plugin_id, num_params)
{
	return g_CurrentGameMode;
}

public native_gamemodes_get_id(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	// Loop through every game mode
	new index, gamemode_name[32]
	for (index = 0; index < g_GameModeCount; index++)
	{
		ArrayGetString(g_GameModeName, index, gamemode_name, charsmax(gamemode_name))
		if (equali(name, gamemode_name))
			return index;
	}
	
	return ZP_INVALID_GAME_MODE;
}

public native_gamemodes_get_name(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_GameModeName, game_mode_id, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public native_gamemodes_start(plugin_id, num_params)
{
	new game_mode_id = get_param(1)
	
	if (game_mode_id < 0 || game_mode_id >= g_GameModeCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid game mode id (%d)", game_mode_id)
		return false;
	}
	
	new target_player = get_param(2)
	
	if (target_player != RANDOM_TARGET_PLAYER && !is_user_alive(target_player))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid player (%d)", target_player)
		return false;
	}
	
	// Game modes can only be started at roundstart
	if (!task_exists(TASK_GAMEMODE))
		return false;
	
	new previous_mode, filename_previous[64]
	
	// Game mode already chosen?
	if (g_ChosenGameMode != ZP_NO_GAME_MODE)
	{
		// Pause previous game mode before picking a new one
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename_previous, charsmax(filename_previous))
		pause("ac", filename_previous)
		previous_mode = true
	}
	
	// Set chosen game mode id
	g_ChosenGameMode = game_mode_id
	
	// Unpause game mode once it's chosen
	new filename[64]
	ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
	unpause("ac", filename)
	
	// Execute game mode choose attempt forward (skip checks = true)
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
	
	// Game mode can't be started
	if (g_ForwardResult >= PLUGIN_HANDLED)
	{
		// Pause the game mode we were trying to start
		pause("ac", filename)
		
		// Unpause previously chosen game mode
		if (previous_mode) unpause("ac", filename_previous)
		
		return false;
	}
	
	// Execute game mode chosen forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, target_player)
	
	// Override task and start game mode manually
	remove_task(TASK_GAMEMODE)
	start_game_mode_task()
	return true;
}

public native_gamemodes_get_count(plugin_id, num_params)
{
	return g_GameModeCount;
}

public _gamemodes_set_allow_infect(plugin_id, num_params)
{
	g_AllowInfection = get_param(1)
}

public _gamemodes_get_allow_infect(plugin_id, num_params)
{
	return g_AllowInfection;
}

public event_game_restart()
{
	logevent_round_end()
}

public logevent_round_end()
{
	ExecuteForward(g_Forwards[FW_GAME_MODE_END], g_ForwardResult, g_CurrentGameMode)
	
	if (g_ChosenGameMode != ZP_NO_GAME_MODE)
	{
		// pause game mode after its round ends
		new filename[64]
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		pause("ac", filename)
	}
	
	g_CurrentGameMode = ZP_NO_GAME_MODE
	g_ChosenGameMode = ZP_NO_GAME_MODE
	g_AllowInfection = false
	
	// Stop game mode task
	remove_task(TASK_GAMEMODE)
	
	// Balance the teams
	balance_teams()
}

public event_round_start()
{
	// Players respawn as humans when a new round begins
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		zp_core_respawn_as_zombie(id, false)
	}
	
	// No game modes registered?
	if (g_GameModeCount < 1)
	{
		set_fail_state("[ZP] No game modes registered!")
		return;
	}
	
	// Remove previous tasks
	remove_task(TASK_GAMEMODE)
	
	// Pick game mode for the current round (delay needed because not all players are alive at this point)
	set_task(0.1, "choose_game_mode", TASK_GAMEMODE)
	
	// Start game mode task (delay should be greater than choose_game_mode task)
	set_task(0.2 + get_pcvar_float(cvar_gamemode_delay), "start_game_mode_task", TASK_GAMEMODE)
	
	if (get_pcvar_num(cvar_round_start_show_hud))
	{
		// Show T-virus HUD notice
		set_hudmessage(0, 125, 200, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 3.0, 2.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_VIRUS_FREE")
	}
}

public choose_game_mode()
{
	// No players joined yet
	if (GetAliveCount() <= 0)
		return;
	
	new index, filename[64]
	
	// Try choosing a game mode
	for (index = g_DefaultGameMode + 1; /*no condition*/; index++)
	{
		// Start over when we reach the end
		if (index >= g_GameModeCount)
			index = 0
		
		// Game mode already chosen?
		if (g_ChosenGameMode != ZP_NO_GAME_MODE)
		{
			// Pause previous game mode before picking a new one
			ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
			pause("ac", filename)
		}
		
		// Set chosen game mode index
		g_ChosenGameMode = index
		
		// Unpause game mode once it's chosen
		ArrayGetString(g_GameModeFileName, g_ChosenGameMode, filename, charsmax(filename))
		unpause("ac", filename)
		
		// Starting non-default game mode?
		if (index != g_DefaultGameMode)
		{
			// Execute game mode choose attempt forward (skip checks = false)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, false)
			
			// Custom game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED && (!get_pcvar_num(cvar_prevent_consecutive) || g_LastGameMode != index))
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				g_LastGameMode = g_ChosenGameMode
				break;
			}
		}
		else
		{
			// Execute game mode choose attempt forward (skip checks = true)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_ForwardResult, g_ChosenGameMode, true)
			
			// Default game mode can start?
			if (g_ForwardResult < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_ForwardResult, g_ChosenGameMode, RANDOM_TARGET_PLAYER)
				g_LastGameMode = g_ChosenGameMode
				break;
			}
			else
			{
				remove_task(TASK_GAMEMODE)
				abort(AMX_ERR_GENERAL, "[ZP] Default game mode can't be started. Check server settings.")
				break;
			}
		}
	}
}

public start_game_mode_task()
{
	// No game mode was chosen (not enough players)
	if (g_ChosenGameMode == ZP_NO_GAME_MODE)
		return;
	
	// Set current game mode
	g_CurrentGameMode = g_ChosenGameMode
	
	// Execute game mode started forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_START], g_ForwardResult, g_CurrentGameMode)
}

// Client Disconnected Post Forward
public fw_ClientDisconnect_Post(id)
{
	// Are there any other players? (if not, round end is automatically triggered after last player leaves)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		choose_game_mode()
	}
}

// Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Are there any other players? (if not, round end is automatically triggered after last player dies)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		choose_game_mode()
	}
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when no game mode is active
	if (g_CurrentGameMode == ZP_NO_GAME_MODE)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (zp_core_is_zombie(attacker) == zp_core_is_zombie(victim))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Prevent attacks when no game mode is active
	if (g_CurrentGameMode == ZP_NO_GAME_MODE)
		return HAM_SUPERCEDE;
	
	// Prevent friendly fire
	if (zp_core_is_zombie(attacker) == zp_core_is_zombie(victim))
		return HAM_SUPERCEDE;
	
	// Mode allows infection and zombie attacking human...
	if (zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Prevent infection/damage by HE grenade (bugfix)
		if (damage_type & DMG_GRENADE)
			return HAM_SUPERCEDE;
		
		// Do Zaphie Damage
		if (LibraryExists(LIBRARY_ZAPHIE, LibType_Library) && zp_class_zaphie_get(attacker))
			return HAM_ZAPHIE;
		
		// Do Zombie Damage
		return HAM_ZOMBIE;
	}
	
	return HAM_IGNORED;
}

HAM_DoZaphieDamage(victim, attacker, &Float:damage)
{
	new bool:changed = reset_user_damage(attacker, false, ClassTeam_Zombie, damage);
	
	if(damage < get_user_health(victim) || zp_core_is_last_human(victim))
	{
		if(changed)
		{
			SetHamParamFloat(4, damage);
			return HAM_HANDLED;
		}
		return HAM_IGNORED;
	}
	
	if(g_AllowInfection
	&& is_user_infection_allows(attacker, ClassTeam_Zombie)
	&& damage > 0.0
	&& GetHamReturnStatus() != HAM_SUPERCEDE
	&& is_user_infection_allows(victim, ClassTeam_Human))
	{
		zp_class_zaphie_set(victim);
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

HAM_DoZombieDamage(victim, attacker, &Float:damage)
{
	// Last human is killed to trigger round end
	if (zp_core_is_last_human(victim))
	{
		if(reset_user_damage(attacker, get_pcvar_num(cvar_last_man_infection) != 0, ClassTeam_Zombie, damage))
		{
			SetHamParamFloat(4, damage);
			return HAM_HANDLED;
		}
		return HAM_IGNORED;
	}
	
	// Infect only if damage is done to victim
	if (g_AllowInfection
	&& is_user_infection_allows(attacker, ClassTeam_Zombie)
	&& damage > 0.0
	&& GetHamReturnStatus() != HAM_SUPERCEDE
	&& is_user_infection_allows(victim, ClassTeam_Human))
	{
		// Infect victim!
		zp_core_infect(victim, attacker)
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

bool:is_user_infection_allows(client, ClassTeam:team)
{
	new classid;
	switch(team)
	{
		case ClassTeam_Human:
		{
			classid = zp_class_human_get_current(client);
			if(classid != ZP_INVALID_HUMAN_CLASS)
				return zp_class_human_get_infection(classid);
		}
		case ClassTeam_Zombie:
		{
			classid = zp_class_zombie_get_current(client);
			if(classid != ZP_INVALID_ZOMBIE_CLASS)
				return zp_class_zombie_get_infection(classid);
		}
	}
	return true;
}

bool:reset_user_damage(client, bool:kill, ClassTeam:team, &Float:damage)
{
	new Float:damage_new = damage;
	if(kill)
		damage_new = get_user_health(client)*1.0 + get_user_armor(client);
	else
	{
		new Float:damage_primary;
		new Float:damage_secondary;
		new Float:damage_multiplier;
		get_setting_damage(client, team, damage_primary, damage_secondary, damage_multiplier);
		
		switch(g_AttackType[client])
		{
			case AttackType_Primary:
			{
				if(damage_primary >= 0.0)
					damage_new = damage_primary;
			}
			case AttackType_Secondary:
			{
				if(damage_secondary >= 0.0)
					damage_new = damage_secondary;
			}
		}
		g_AttackType[client] = AttackType_Other;
		
		damage_new *= damage_multiplier;
	}
	if(damage_new != damage && damage_new >= 0.0)
	{
		damage = damage_new;
		return true;
	}
	return false;
}

get_setting_damage(client, ClassTeam:team, &Float:primary, &Float:secondary, &Float:multiplier)
{
	new classid;
	switch(team)
	{
		case ClassTeam_Human:
		{
			classid = zp_class_human_get_current(client);
			if(classid != ZP_INVALID_HUMAN_CLASS)
			{
				primary = -1.0;
				secondary = -1.0;
				multiplier = zp_class_human_get_dm(classid);
			}
		}
		case ClassTeam_Zombie:
		{
			classid = zp_class_zombie_get_current(client);
			if(classid != ZP_INVALID_ZOMBIE_CLASS)
			{
				primary = zp_class_zombie_get_pd(classid);
				secondary = zp_class_zombie_get_sd(classid);
				multiplier = zp_class_zombie_get_dm(classid);
			}
		}
	}
	if(multiplier < 0.0)
		multiplier = 1.0;
}

reset_attack_interval(client, AttackType:attack_type)
{
	new Float:interval;
	if(zp_core_is_zombie(client))
		interval = get_setting_interval(client, ClassTeam_Zombie, attack_type);
	
	g_AttackType[client] = attack_type;
	
	if(interval >= 0.0)
	{
		if(get_gametime() <= g_NextAttackTime[client])
			return HAM_SUPERCEDE;
		
		g_NextAttackTime[client] = get_gametime() + interval;
		set_next_attack(client, interval);
	}
	return HAM_IGNORED;
}

Float:get_setting_interval(client, ClassTeam:team, AttackType:attack_type)
{
	new classid;
	new Float:interval_primary;
	new Float:interval_secondary;
	switch(team)
	{
		case ClassTeam_Human:
		{
			interval_primary = -1.0;
			interval_secondary = -1.0;
		}
		case ClassTeam_Zombie:
		{
			classid = zp_class_zombie_get_current(client);
			if(classid != ZP_INVALID_ZOMBIE_CLASS)
			{
				interval_primary = zp_class_zombie_get_pi(classid);
				interval_secondary = zp_class_zombie_get_si(classid);
			}
		}
	}
	switch(attack_type)
	{
		case AttackType_Primary:{return interval_primary;}
		case AttackType_Secondary:{return interval_secondary;}
	}
	return -1.0;
}

public fw_KnifePrimaryAttack(knife)
{
	if(!pev_valid(knife))
		return HAM_IGNORED;
	
	new owner = pev(knife, pev_owner);
	if(!is_user_connected(owner) || !is_user_alive(owner))
		return HAM_IGNORED;
	
	return reset_attack_interval(owner, AttackType_Primary);
}

public fw_KnifeSecondaryAttack(knife)
{
	if(!pev_valid(knife))
		return HAM_IGNORED;
	
	new owner = pev(knife, pev_owner);
	if(!is_user_connected(owner) || !is_user_alive(owner))
		return HAM_IGNORED;
	
	return reset_attack_interval(owner, AttackType_Secondary);
}

set_next_attack(client, Float:cdtime, const modex = 0, const moder = 0)
{
	if(!is_user_alive(client))
		return
	
	new item = get_pdata_cbase(client, OFFSET_ACTIVE_ITEM)
	
	if(pev_valid(item))
	{
		if(!modex)
		{
			set_pdata_float(item, OFFSET_TIME_WEAPONIDLE, cdtime + 1.0, OFFSET_LINUX_WEAPONS)
		}
		else
		{
			set_pdata_float(item, OFFSET_TIME_WEAPONIDLE, cdtime, OFFSET_LINUX_WEAPONS)
		}
		if(moder)
		{
			set_pdata_float(item, OFFSET_NEXTPRIMARYATTACK, cdtime, OFFSET_LINUX_WEAPONS)
			set_pdata_float(item, OFFSET_NEXTSECONDARYATTACK, cdtime, OFFSET_LINUX_WEAPONS)
		}
	}
	set_pdata_float(client, OFFSSET_NEXTATTACK, cdtime, 5)
}

public zp_fw_core_infect_post(id, attacker)
{
	if (g_CurrentGameMode != ZP_NO_GAME_MODE)
	{
		// Zombies are switched to Terrorist team
		cs_set_player_team(id, CS_TEAM_T)
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	if (g_CurrentGameMode != ZP_NO_GAME_MODE)
	{
		// Humans are switched to CT team
		cs_set_player_team(id, CS_TEAM_CT)
	}
}

// Balance Teams
balance_teams()
{
	// Get amount of users playing
	new players_count = GetPlayingCount()
	
	// No players, don't bother
	if (players_count < 1) return;
	
	// Split players evenly
	new iTerrors
	new iMaxTerrors = players_count / 2
	new id, CsTeams:team
	
	// First, set everyone to CT
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing
		if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
			continue;
		
		// Set team
		cs_set_player_team(id, CS_TEAM_CT, 0)
	}
	
	// Then randomly move half of the players to Terrorists
	while (iTerrors < iMaxTerrors)
	{
		// Keep looping through all players
		if (++id > g_MaxPlayers) id = 1
		
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing or already a Terrorist
		if (team != CS_TEAM_CT)
			continue;
		
		// Random chance
		if (random_num(0, 1))
		{
			cs_set_player_team(id, CS_TEAM_T, 0)
			iTerrors++
		}
	}
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

// Get Playing Count -returns number of users playing-
GetPlayingCount()
{
	new iPlaying, id, CsTeams:team
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		if (team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED)
			iPlaying++
	}
	
	return iPlaying;
}