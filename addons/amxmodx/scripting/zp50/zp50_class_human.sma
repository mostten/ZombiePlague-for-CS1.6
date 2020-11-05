/*================================================================================
	
	-------------------------
	-*- [ZP] Class: Human -*-
	-------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <cs_weap_restrict_api>
#include <zp50_core>
#include <zp50_colorchat>
#include <zp50_class_human_const>

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" };

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 };

// Human Classes file
new const ZP_HUMANCLASSES_FILE[] = "zp_humanclasses.ini"

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

#define MODEL_MAX_LENGTH 64

// Models
new g_model_vknife_human[MODEL_MAX_LENGTH] = "models/v_knife.mdl"

#define MAXPLAYERS 32

#define HUMANS_DEFAULT_NAME "Human"
#define HUMANS_DEFAULT_DESCRIPTION "Default"
#define HUMANS_DEFAULT_HEALTH 100
#define HUMANS_DEFAULT_BASE_HEALTH 100
#define HUMANS_DEFAULT_SPEED 1.0
#define HUMANS_DEFAULT_GRAVITY 1.0
#define HUMANS_DEFAULT_DMULTIPLIER 1.0

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// For class list menu handlers
#define MENU_PAGE_CLASS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_CLASS_SELECT_POST,
	FW_CLASS_MENU_SHOW_PRE,
	FW_CLASS_INIT_PRE,
	FW_CLASS_INIT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_HumanClassCount
new Array:g_HumanClassRealName
new Array:g_HumanClassName
new Array:g_HumanClassDesc
new Array:g_HumanClassHealth
new Array:g_HumanClassBaseHealth
new Array:g_HumanClassSpeed
new Array:g_HumanClassGravity
new Array:g_HumanClassDMFile
new Array:g_HumanClassDamageMultiplier
new Array:g_HumanClassModelsFile
new Array:g_HumanClassModelsHandle
new Array:g_HumanViewModelsFile
new Array:g_HumanViewModelsHandle
new Array:g_HumanClassWeaponFile
new Array:g_HumanClassWeaponHandle
new Array:g_HumanClassAllowInfection
new g_HumanClass[MAXPLAYERS+1]
new g_HumanClassTemp[MAXPLAYERS+1]
new g_HumanClassNext[MAXPLAYERS+1]
new g_HumanMaxHealth[MAXPLAYERS+1]
new g_HumanWeapon[MAXPLAYERS+1][32]
new g_AdditionalMenuText[32]

public plugin_init()
{
	register_plugin("[ZP] Class: Human", ZP_VERSION_STRING, "ZP Dev Team");
	
	register_clcmd("say /hclass", "show_menu_humanclass");
	register_clcmd("say /class", "show_class_menu");
	
	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zp_fw_class_human_select_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_CLASS_SELECT_POST] = CreateMultiForward("zp_fw_class_human_select_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[FW_CLASS_MENU_SHOW_PRE] = CreateMultiForward("zp_fw_class_human_menu_show_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[FW_CLASS_INIT_PRE] = CreateMultiForward("zp_fw_class_human_init_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_CLASS_INIT_POST] = CreateMultiForward("zp_fw_class_human_init_post", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_cfg()
{
	// No classes loaded, add default human class
	if (g_HumanClassCount < 1)
	{
		ArrayPushString(g_HumanClassRealName, HUMANS_DEFAULT_NAME)
		ArrayPushString(g_HumanClassName, HUMANS_DEFAULT_NAME)
		ArrayPushString(g_HumanClassDesc, HUMANS_DEFAULT_DESCRIPTION)
		ArrayPushCell(g_HumanClassHealth, HUMANS_DEFAULT_HEALTH)
		ArrayPushCell(g_HumanClassBaseHealth, HUMANS_DEFAULT_BASE_HEALTH)
		ArrayPushCell(g_HumanClassSpeed, HUMANS_DEFAULT_SPEED)
		ArrayPushCell(g_HumanClassGravity, HUMANS_DEFAULT_GRAVITY)
		ArrayPushCell(g_HumanClassDMFile, false)
		ArrayPushCell(g_HumanClassDamageMultiplier, HUMANS_DEFAULT_DMULTIPLIER)
		ArrayPushCell(g_HumanClassModelsFile, false)
		ArrayPushCell(g_HumanClassModelsHandle, Invalid_Array)
		ArrayPushCell(g_HumanViewModelsFile, false)
		ArrayPushCell(g_HumanViewModelsHandle, Invalid_Array)
		ArrayPushCell(g_HumanClassWeaponFile, false)
		ArrayPushCell(g_HumanClassWeaponHandle, Invalid_Array)
		ArrayPushCell(g_HumanClassAllowInfection, true)
		g_HumanClassCount++
	}
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE HUMAN", g_model_vknife_human, charsmax(g_model_vknife_human)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE HUMAN", g_model_vknife_human)
	
	// Precache models
	precache_model(g_model_vknife_human)
}

public plugin_natives()
{
	register_library("zp50_class_human")
	register_native("zp_class_human_get_current", "native_class_human_get_current")
	register_native("zp_class_human_set_current", "native_class_human_set_current")
	register_native("zp_class_human_get_next", "native_class_human_get_next")
	register_native("zp_class_human_set_next", "native_class_human_set_next")
	register_native("zp_class_human_get_max_health", "_class_human_get_max_health")
	register_native("zp_class_human_register", "native_class_human_register")
	register_native("zp_class_human_register_model", "_class_human_register_model")
	register_native("zp_class_human_register_vm", "_class_human_register_vm")
	register_native("zp_class_human_register_weapon", "_class_human_register_weapon")
	register_native("zp_class_human_register_dm", "native_class_human_register_dm")
	register_native("zp_class_human_get_id", "native_class_human_get_id")
	register_native("zp_class_human_get_name", "native_class_human_get_name")
	register_native("zp_class_human_get_real_name", "_class_human_get_real_name")
	register_native("zp_class_human_get_desc", "native_class_human_get_desc")
	register_native("zp_class_human_get_dm", "native_class_human_get_dm")
	register_native("zp_class_human_get_infection", "_class_human_get_infection")
	register_native("zp_class_human_get_count", "native_class_human_get_count")
	register_native("zp_class_human_show_menu", "native_class_human_show_menu")
	register_native("zp_class_human_menu_text_add", "_class_human_menu_text_add")
	
	// Initialize dynamic arrays
	g_HumanClassRealName = ArrayCreate(32, 1)
	g_HumanClassName = ArrayCreate(32, 1)
	g_HumanClassDesc = ArrayCreate(32, 1)
	g_HumanClassHealth = ArrayCreate(1, 1)
	g_HumanClassBaseHealth = ArrayCreate(1, 1)
	g_HumanClassSpeed = ArrayCreate(1, 1)
	g_HumanClassGravity = ArrayCreate(1, 1)
	g_HumanClassDMFile = ArrayCreate(1, 1)
	g_HumanClassDamageMultiplier = ArrayCreate(1, 1)
	g_HumanClassModelsFile = ArrayCreate(1, 1)
	g_HumanClassModelsHandle = ArrayCreate(1, 1)
	g_HumanViewModelsFile = ArrayCreate(1, 1)
	g_HumanViewModelsHandle = ArrayCreate(1, 1)
	g_HumanClassWeaponFile = ArrayCreate(1, 1)
	g_HumanClassWeaponHandle = ArrayCreate(1, 1)
	g_HumanClassAllowInfection = ArrayCreate(1, 1)
}

public client_putinserver(id)
{
	g_HumanClass[id] = ZP_INVALID_HUMAN_CLASS
	g_HumanClassTemp[id] = ZP_INVALID_HUMAN_CLASS
	g_HumanClassNext[id] = ZP_INVALID_HUMAN_CLASS
}

public client_disconnected(id)
{
	// Reset remembered menu pages
	MENU_PAGE_CLASS = 0
}

public show_class_menu(id)
{
	if (!zp_core_is_zombie(id))
		show_menu_humanclass(id)
}

public show_menu_humanclass(id)
{
	// Execute class select attempt forward
	ExecuteForward(g_Forwards[FW_CLASS_MENU_SHOW_PRE], g_ForwardResult, id);
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	static menu[128], name[32], description[32], transkey[64]
	new menuid, itemdata[2], index
	
	formatex(menu, charsmax(menu), "%L\r", id, "MENU_HCLASS")
	menuid = menu_create(menu, "menu_humanclass")
	
	for (index = 0; index < g_HumanClassCount; index++)
	{
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
		
		// Show class to player?
		if (g_ForwardResult >= ZP_CLASS_DONT_SHOW)
			continue;
		
		ArrayGetString(g_HumanClassName, index, name, charsmax(name))
		ArrayGetString(g_HumanClassDesc, index, description, charsmax(description))
		
		// ML support for class name + description
		formatex(transkey, charsmax(transkey), "HUMANDESC %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(description, charsmax(description), "%L", id, transkey)
		formatex(transkey, charsmax(transkey), "HUMANNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// Class available to player?
		if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %s %s", name, description, g_AdditionalMenuText)
		// Class is current class?
		else if (index == g_HumanClassNext[id])
			formatex(menu, charsmax(menu), "\r%s \y%s \w%s", name, description, g_AdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%s \w%s", name, description, g_AdditionalMenuText)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// No classes to display?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_CLASSES")
		menu_destroy(menuid)
		return;
	}
	
	// Back - Next - Exit
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_CLASS = min(MENU_PAGE_CLASS, menu_pages(menuid)-1)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_CLASS)
}

public menu_humanclass(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		MENU_PAGE_CLASS = 0
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Remember class menu page
	MENU_PAGE_CLASS = item / 7
	
	// Retrieve class index
	new itemdata[2], dummy, index
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy)
	index = itemdata[0]
	
	// Execute class select attempt forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
	
	// Class available to player?
	if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	// Make selected class next class for player
	g_HumanClassNext[id] = index
	
	new name[32], transkey[64]
	new Float:maxspeed = Float:ArrayGetCell(g_HumanClassSpeed, g_HumanClassNext[id])
	ArrayGetString(g_HumanClassName, g_HumanClassNext[id], name, charsmax(name))
	// ML support for class name
	formatex(transkey, charsmax(transkey), "HUMANNAME %s", name)
	if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
	
	// Show selected human class
	zp_colored_print(id, "%L: %s", id, "HUMAN_SELECT", name)
	zp_colored_print(id, "%L: %d %L: %d %L: %.2fx", id, "ZOMBIE_ATTRIB1", ArrayGetCell(g_HumanClassHealth, g_HumanClassNext[id]), id, "ZOMBIE_ATTRIB2", cs_maxspeed_display_value(maxspeed), id, "ZOMBIE_ATTRIB3", Float:ArrayGetCell(g_HumanClassGravity, g_HumanClassNext[id]))
	
	// Execute class select post forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_POST], g_ForwardResult, id, index)
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public zp_fw_core_cure_post(id, attacker)
{
	if(g_HumanClassTemp[id] == ZP_INVALID_HUMAN_CLASS)
	{
		// Show human class menu if they haven't chosen any (e.g. just connected)
		new random_classid = get_random_human(id);
		if (g_HumanClassNext[id] == ZP_INVALID_HUMAN_CLASS)
		{
			if (get_valid_class_count(id) > 1)
				show_menu_humanclass(id);
			else // If only one class is registered, choose it automatically
				g_HumanClassNext[id] = random_classid;
		}
		
		// Bots pick class automatically
		if (is_user_bot(id))
		{
			// Try choosing class
			g_HumanClassNext[id] = random_classid;
		}
		
		// Set selected human class. If none selected yet, use the first one
		g_HumanClass[id] = g_HumanClassNext[id];
		if (g_HumanClass[id] == ZP_INVALID_HUMAN_CLASS){g_HumanClass[id] = random_classid;}
	}
	else
	{
		g_HumanClass[id] = g_HumanClassTemp[id];
		g_HumanClassTemp[id] = ZP_INVALID_HUMAN_CLASS;
	}
	// Apply human attributes
	apply_human_info(id, g_HumanClass[id]);
}

get_valid_class_count(id)
{
	new count = 0;
	for(new classid = 0; classid < g_HumanClassCount; classid++)
	{
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, classid);
		
		// Class available to player?
		if (g_ForwardResult < ZP_CLASS_NOT_AVAILABLE)
			count++;
	}
	return count;
}

get_random_human(id)
{
	new Array:humans = ArrayCreate(1, 1);
	
	for(new classid = 0; classid < g_HumanClassCount; classid++)
	{
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, classid);
		
		// Class available to player?
		if (g_ForwardResult < ZP_CLASS_NOT_AVAILABLE)
			ArrayPushCell(humans, classid);
	}
	
	new human_select = 0;
	new human_count = ArraySize(humans);
	if(human_count > 0)
		human_select = ArrayGetCell(humans, random_num(0, human_count - 1));
	
	ArrayDestroy(humans);
	
	return human_select;
}

apply_human_info(id, classid)
{
	ExecuteForward(g_Forwards[FW_CLASS_INIT_PRE], g_ForwardResult, id, classid);
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	// Apply human attributes
	g_HumanMaxHealth[id] = (ArrayGetCell(g_HumanClassHealth, classid) == 0)?(ArrayGetCell(g_HumanClassBaseHealth, classid)*GetAliveCount()):(ArrayGetCell(g_HumanClassHealth, classid));
	set_user_health(id, g_HumanMaxHealth[id]);
	set_user_gravity(id, Float:ArrayGetCell(g_HumanClassGravity, classid));
	cs_set_player_maxspeed_auto(id, Float:ArrayGetCell(g_HumanClassSpeed, classid));
	
	// Apply human player model
	new Array:class_models = ArrayGetCell(g_HumanClassModelsHandle, classid);
	if (class_models != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_models) - 1);
		new player_model[32];
		ArrayGetString(class_models, index, player_model, charsmax(player_model));
		cs_set_player_model(id, player_model);
	}
	else
	{
		// No models registered for current class, use default model
		cs_reset_player_model(id);
	}
	
	// Set custom knife model
	cs_set_player_view_model(id, CSW_KNIFE, g_model_vknife_human);
	
	// Apply player weapon
	give_human_weapon(id, classid);
	
	ExecuteForward(g_Forwards[FW_CLASS_INIT_POST], g_ForwardResult, id, classid);
}

give_human_weapon(id, classid)
{
	if (get_class_weapon_name(classid, g_HumanWeapon[id]))
	{
		new weapon_id, view_weapon[32];
		if(get_class_view_weapon(classid, view_weapon))
		{
			weapon_id = get_weaponid(g_HumanWeapon[id]);
			cs_set_player_view_model(id, weapon_id, view_weapon);
		}
		give_item(id, g_HumanWeapon[id]);
		
		if(weapon_id > 0)
			ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weapon_id], AMMOTYPE[weapon_id], MAXBPAMMO[weapon_id]);
	}
	else{formatex(g_HumanWeapon[id], 32, "");}
}

reset_human_view_model(id)
{
	if (strlen(g_HumanWeapon[id]))
	{
		new weapon_id = get_weaponid(g_HumanWeapon[id]);
		cs_reset_player_view_model(id, weapon_id);
	}
}

bool:get_class_weapon_name(classid, weapon_name[32])
{
	new Array:weapons = ArrayGetCell(g_HumanClassWeaponHandle, classid);
	if (weapons != Invalid_Array)
	{
		new index = random_num(0, ArraySize(weapons) - 1);
		ArrayGetString(weapons, index, weapon_name, charsmax(weapon_name));
		return (strlen(weapon_name) > 0);
	}
	return false;
}

bool:get_class_view_weapon(classid, view_weapon[32])
{
	new Array:view_weapons = ArrayGetCell(g_HumanViewModelsHandle, classid);
	if (view_weapons != Invalid_Array)
	{
		new index = random_num(0, ArraySize(view_weapons) - 1);
		ArrayGetString(view_weapons, index, view_weapon, charsmax(view_weapon));
		return (strlen(view_weapon) > 0);
	}
	return false;
}

public zp_fw_core_spawn_post(id)
{
	reset_human_view_model(id);
}

public zp_fw_core_infect(id, attacker)
{
	// Remove custom knife model
	cs_reset_player_view_model(id, CSW_KNIFE);
	
	reset_human_view_model(id);
}

public native_class_human_get_current(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	return g_HumanClass[id];
}

public native_class_human_set_current(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	g_HumanClassTemp[id] = classid;
	
	if(!zp_core_is_zombie(id)){zp_core_force_cure(id);}
	else{zp_core_cure(id, id);}
	
	return true;
}

public native_class_human_get_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	return g_HumanClassNext[id];
}

public native_class_human_set_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	g_HumanClassNext[id] = classid
	return true;
}

public _class_human_get_max_health(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_HumanMaxHealth[id];
}

public native_class_human_register(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register human class with an empty name")
		return ZP_INVALID_HUMAN_CLASS;
	}
	
	new index, humanclass_name[32]
	for (index = 0; index < g_HumanClassCount; index++)
	{
		ArrayGetString(g_HumanClassRealName, index, humanclass_name, charsmax(humanclass_name))
		if (equali(name, humanclass_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Human class already registered (%s)", name)
			return ZP_INVALID_HUMAN_CLASS;
		}
	}
	
	new description[32]
	get_string(2, description, charsmax(description))
	new health = get_param(3)
	new Float:speed = get_param_f(4)
	new Float:gravity = get_param_f(5)
	new bool:infection = (get_param(6) > 0)
	new base_health = get_param(7)
	
	// Load settings from human classes file
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_HumanClassRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_HUMANCLASSES_FILE, real_name, "NAME", name, charsmax(name)))
		amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "NAME", name)
	ArrayPushString(g_HumanClassName, name)
	
	// Description
	if (!amx_load_setting_string(ZP_HUMANCLASSES_FILE, real_name, "INFO", description, charsmax(description)))
		amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "INFO", description)
	ArrayPushString(g_HumanClassDesc, description)
	
	// Models
	new Array:class_models = ArrayCreate(32, 1)
	amx_load_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "MODELS", class_models)
	if (ArraySize(class_models) > 0)
	{
		ArrayPushCell(g_HumanClassModelsFile, true)
		
		// Precache player models
		new index, player_model[32], model_path[128]
		for (index = 0; index < ArraySize(class_models); index++)
		{
			ArrayGetString(class_models, index, player_model, charsmax(player_model))
			formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
			precache_model(model_path)
			// Support modelT.mdl files
			formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
			if (file_exists(model_path)) precache_model(model_path)
		}
	}
	else
	{
		ArrayPushCell(g_HumanClassModelsFile, false)
		ArrayDestroy(class_models)
		amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "MODELS", "")
	}
	ArrayPushCell(g_HumanClassModelsHandle, class_models)
	
	// Infection
	human_infection_register(real_name, infection);
	
	// Health
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "HEALTH", health))
		amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "HEALTH", health)
	ArrayPushCell(g_HumanClassHealth, health)
	
	// Base Health
	human_base_health_register(real_name, base_health);
	
	// Speed
	if (!amx_load_setting_float(ZP_HUMANCLASSES_FILE, real_name, "SPEED", speed))
		amx_save_setting_float(ZP_HUMANCLASSES_FILE, real_name, "SPEED", speed)
	ArrayPushCell(g_HumanClassSpeed, speed)
	
	// Gravity
	if (!amx_load_setting_float(ZP_HUMANCLASSES_FILE, real_name, "GRAVITY", gravity))
		amx_save_setting_float(ZP_HUMANCLASSES_FILE, real_name, "GRAVITY", gravity)
	ArrayPushCell(g_HumanClassGravity, gravity)
	
	// Damage multiplier
	new Float:damage_multiplier = HUMANS_DEFAULT_DMULTIPLIER
	if (!amx_load_setting_float(ZP_HUMANCLASSES_FILE, real_name, "DAMAGE MULTIPLIER", damage_multiplier))
	{
		ArrayPushCell(g_HumanClassDMFile, false)
		amx_save_setting_float(ZP_HUMANCLASSES_FILE, real_name, "DAMAGE MULTIPLIER", damage_multiplier)
	}
	else
		ArrayPushCell(g_HumanClassDMFile, true)
	ArrayPushCell(g_HumanClassDamageMultiplier, damage_multiplier)
	
	// View weapons
	new Array:view_models = ArrayCreate(32, 1);
	amx_load_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "VIEW WEAPONS", view_models);
	if (ArraySize(view_models) > 0)
	{
		ArrayPushCell(g_HumanViewModelsFile, true);
		
		// Precache player view models
		new index, view_model[32];
		for (index = 0; index < ArraySize(view_models); index++)
		{
			ArrayGetString(view_models, index, view_model, charsmax(view_model));
			if(strlen(view_model)){precache_model(view_model);}
		}
	}
	else
	{
		ArrayPushCell(g_HumanViewModelsFile, false);
		ArrayDestroy(view_models);
		amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "VIEW WEAPONS", "");
	}
	ArrayPushCell(g_HumanViewModelsHandle, view_models);
	
	// Weapons
	new Array:weapons = ArrayCreate(32, 1);
	amx_load_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "WEAPONS", weapons);
	if (ArraySize(weapons) > 0){ArrayPushCell(g_HumanClassWeaponFile, true);}
	else
	{
		ArrayPushCell(g_HumanClassWeaponFile, false);
		ArrayDestroy(weapons);
		amx_save_setting_string(ZP_HUMANCLASSES_FILE, real_name, "WEAPONS", "");
	}
	ArrayPushCell(g_HumanClassWeaponHandle, weapons);
	
	g_HumanClassCount++
	return g_HumanClassCount - 1;
}

human_base_health_register(const real_name[], const base_health = 100)
{
	new health_file;
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "BASE HEALTH", health_file))
	{
		health_file = base_health;
		amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "BASE HEALTH", health_file);
	}
	ArrayPushCell(g_HumanClassBaseHealth, health_file);
}

human_infection_register(const real_name[], const bool:infection = true)
{
	new infection_file;
	if (!amx_load_setting_int(ZP_HUMANCLASSES_FILE, real_name, "INFECTION", infection_file))
	{
		infection_file = infection?1:0;
		amx_save_setting_int(ZP_HUMANCLASSES_FILE, real_name, "INFECTION", infection_file);
	}
	ArrayPushCell(g_HumanClassAllowInfection, infection_file);
}

public _class_human_register_model(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	// Player models already loaded from file
	if (ArrayGetCell(g_HumanClassModelsFile, classid))
		return true;
	
	new player_model[32]
	get_string(2, player_model, charsmax(player_model))
	
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
	
	precache_model(model_path)
	
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
	if (file_exists(model_path)) precache_model(model_path)
	
	new Array:class_models = ArrayGetCell(g_HumanClassModelsHandle, classid)
	
	// No models registered yet?
	if (class_models == Invalid_Array)
	{
		class_models = ArrayCreate(32, 1)
		ArraySetCell(g_HumanClassModelsHandle, classid, class_models)
	}
	ArrayPushString(class_models, player_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "MODELS", class_models)
	
	return true;
}

public _class_human_register_vm(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	// Player models already loaded from file
	if (ArrayGetCell(g_HumanViewModelsFile, classid))
		return true;
	
	new view_model[32];
	get_string(2, view_model, charsmax(view_model));
	
	if(strlen(view_model)){precache_model(view_model);}
	
	new Array:view_models = ArrayGetCell(g_HumanViewModelsHandle, classid);
	
	// No models registered yet?
	if (view_models == Invalid_Array)
	{
		view_models = ArrayCreate(32, 1);
		ArraySetCell(g_HumanViewModelsHandle, classid, view_models);
	}
	ArrayPushString(view_models, view_model);
	
	// Save models to file
	new real_name[32];
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name));
	amx_save_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "VIEW WEAPONS", view_models);
	
	return true;
}

public _class_human_register_weapon(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	// Player weapons already loaded from file
	if (ArrayGetCell(g_HumanClassWeaponFile, classid))
		return true;
	
	new weapon[32];
	get_string(2, weapon, charsmax(weapon));
	
	new Array:weapons = ArrayGetCell(g_HumanClassWeaponHandle, classid);
	// No models registered yet?
	if (weapons == Invalid_Array)
	{
		weapons = ArrayCreate(32, 1);
		ArraySetCell(g_HumanClassWeaponHandle, classid, weapons);
	}
	ArrayPushString(weapons, weapon);
	
	// Save weapons to file
	new real_name[32];
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name));
	amx_save_setting_string_arr(ZP_HUMANCLASSES_FILE, real_name, "WEAPONS", weapons);
	
	return true;
}

public native_class_human_register_dm(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	// Damage multiplier already loaded from file
	if (ArrayGetCell(g_HumanClassDMFile, classid))
		return true;
	
	new Float:damage_multiplier = get_param_f(2)
	
	// Set human class damage multiplier
	ArraySetCell(g_HumanClassDamageMultiplier, classid, damage_multiplier)
	
	// Save to file
	new real_name[32]
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_float(ZP_HUMANCLASSES_FILE, real_name, "DAMAGE MULTIPLIER", damage_multiplier)
	
	return true;
}

public native_class_human_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every class
	new index, humanclass_name[32]
	for (index = 0; index < g_HumanClassCount; index++)
	{
		ArrayGetString(g_HumanClassRealName, index, humanclass_name, charsmax(humanclass_name))
		if (equali(real_name, humanclass_name))
			return index;
	}
	
	return ZP_INVALID_HUMAN_CLASS;
}

public native_class_human_get_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_HumanClassName, classid, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public _class_human_get_real_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_HumanClassRealName, classid, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_class_human_get_desc(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return false;
	}
	
	new description[32]
	ArrayGetString(g_HumanClassDesc, classid, description, charsmax(description))
	
	new len = get_param(3)
	set_string(2, description, len)
	return true;
}

public Float:native_class_human_get_dm(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return HUMANS_DEFAULT_DMULTIPLIER;
	}
	
	// Return human class damage multiplier
	return ArrayGetCell(g_HumanClassDamageMultiplier, classid);
}

public _class_human_get_infection(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_HumanClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid human class id (%d)", classid)
		return -1;
	}
	
	return ArrayGetCell(g_HumanClassAllowInfection, classid) > 0;
}

public native_class_human_get_count(plugin_id, num_params)
{
	return g_HumanClassCount;
}

public native_class_human_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	show_menu_humanclass(id)
	return true;
}

public _class_human_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

GetAliveCount()
{
	new players[MAXPLAYERS], count;
	get_players(players, count, "a");
	return count;
}