/*================================================================================
	
	---------------------------
	-*- [ZP] Class: Ghost -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <amx_settings_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_maxspeed_api>
#include <cs_weap_restrict_api>
#include <zp50_core>
#include <zp50_colorchat>
#include <zp50_class_ghost_const>

// Ghost Classes file
new const ZP_GHOSTCLASSES_FILE[] = "zp_ghostclasses.ini"

#define MAXPLAYERS 32

#define GHOSTS_DEFAULT_NAME "Ghost"
#define GHOSTS_DEFAULT_DESCRIPTION "Default"
#define GHOSTS_DEFAULT_HEALTH 1800
#define GHOSTS_DEFAULT_SPEED 0.75
#define GHOSTS_DEFAULT_GRAVITY 1.0
#define GHOSTS_DEFAULT_DMULTIPLIER -1.0
#define GHOSTS_DEFAULT_MODEL "zombie"
#define GHOSTS_DEFAULT_CLAWMODEL "models/zombie_plague/zp_ghost/v_knife_ghost.mdl"
#define GHOSTS_DEFAULT_KNOCKBACK 1.0
#define DEFAULT_INTERVAL_PRIMARYATTACK 0.5
#define DEFAULT_INTERVAL_SECONDARYATTACK 0.8
#define DEFAULT_DAMAGE_PRIMARYATTACK 10.0
#define DEFAULT_DAMAGE_SECONDARYATTACK 20.0

// 幽灵允许使用的武器
const GHOST_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)
const GHOST_DEFAULT_ALLOWED_WEAPON = CSW_KNIFE

// CS 玩家的 PData 数据偏移 (win32)
const OFFSET_CSMENUCODE = 205

// 类型列表菜单的句柄
#define MENU_PAGE_CLASS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_CLASS_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_GhostClassCount
new Array:g_GhostClassRealName
new Array:g_GhostClassName
new Array:g_GhostClassDesc
new Array:g_GhostClassHealth
new Array:g_GhostClassSpeed
new Array:g_GhostClassGravity
new Array:g_GhostClassDMFile
new Array:g_GhostClassDamageMultiplier
new Array:g_GhostClassKnockbackFile
new Array:g_GhostClassKnockback
new Array:g_GhostClassModelsFile
new Array:g_GhostClassModelsHandle
new Array:g_GhostClassClawsFile
new Array:g_GhostClassClawsHandle
new Array:g_GhostClassAllowInfection
new Array:g_IntervalPrimaryAttack
new Array:g_IntervalSecondaryAttack
new Array:g_DamagePrimaryAttack
new Array:g_DamageSecondaryAttack
new g_GhostClass[MAXPLAYERS+1]
new g_GhostClassNext[MAXPLAYERS+1]
new g_AdditionalMenuText[32]

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_MaxPlayers
new g_IsGhost

public plugin_init()
{
	register_plugin("[ZP] Class: Ghost", ZP_VERSION_STRING, "Mostten")
	
	register_clcmd("say /gclass", "show_menu_ghostclass")
	
	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zp_fw_class_ghost_select_pre", ET_CONTINUE, FP_CELL, FP_CELL)
	g_Forwards[FW_CLASS_SELECT_POST] = CreateMultiForward("zp_fw_class_ghost_select_post", ET_CONTINUE, FP_CELL, FP_CELL)
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", GHOSTS_DEFAULT_MODEL, GHOSTS_DEFAULT_MODEL)
	precache_model(model_path)
	// 支持 modelT.mdl 文件
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", GHOSTS_DEFAULT_MODEL, GHOSTS_DEFAULT_MODEL)
	if (file_exists(model_path)) precache_model(model_path)
	
	precache_model(GHOSTS_DEFAULT_CLAWMODEL)
}

public plugin_cfg()
{
	// 没有类型载入, 添加默认幽灵类型
	if (g_GhostClassCount < 1)
	{
		ArrayPushString(g_GhostClassRealName, GHOSTS_DEFAULT_NAME)
		ArrayPushString(g_GhostClassName, GHOSTS_DEFAULT_NAME)
		ArrayPushString(g_GhostClassDesc, GHOSTS_DEFAULT_DESCRIPTION)
		ArrayPushCell(g_GhostClassHealth, GHOSTS_DEFAULT_HEALTH)
		ArrayPushCell(g_GhostClassSpeed, GHOSTS_DEFAULT_SPEED)
		ArrayPushCell(g_GhostClassGravity, GHOSTS_DEFAULT_GRAVITY)
		ArrayPushCell(g_GhostClassKnockbackFile, false)
		ArrayPushCell(g_GhostClassKnockback, GHOSTS_DEFAULT_KNOCKBACK)
		ArrayPushCell(g_GhostClassDMFile, false)
		ArrayPushCell(g_GhostClassDamageMultiplier, GHOSTS_DEFAULT_DMULTIPLIER)
		ArrayPushCell(g_GhostClassModelsFile, false)
		ArrayPushCell(g_GhostClassModelsHandle, Invalid_Array)
		ArrayPushCell(g_GhostClassClawsFile, false)
		ArrayPushCell(g_GhostClassClawsHandle, Invalid_Array)
		ArrayPushCell(g_GhostClassAllowInfection, true)
		ArrayPushCell(g_IntervalPrimaryAttack, DEFAULT_INTERVAL_PRIMARYATTACK)
		ArrayPushCell(g_IntervalSecondaryAttack, DEFAULT_INTERVAL_SECONDARYATTACK)
		ArrayPushCell(g_DamagePrimaryAttack, DEFAULT_DAMAGE_PRIMARYATTACK)
		ArrayPushCell(g_DamageSecondaryAttack, DEFAULT_DAMAGE_SECONDARYATTACK)
		g_GhostClassCount++
	}
}

public plugin_natives()
{
	register_library("zp50_class_ghost")
	register_native("zp_class_ghost_get_current", "native_class_ghost_get_current")
	register_native("zp_class_ghost_get_next", "native_class_ghost_get_next")
	register_native("zp_class_ghost_set_next", "native_class_ghost_set_next")
	register_native("zp_class_ghost_get_max_health", "_class_ghost_get_max_health")
	register_native("zp_class_ghost_register", "native_class_ghost_register")
	register_native("zp_class_ghost_register_model", "_class_ghost_register_model")
	register_native("zp_class_ghost_register_claw", "_class_ghost_register_claw")
	register_native("zp_class_ghost_register_kb", "native_class_ghost_register_kb")
	register_native("zp_class_ghost_register_dm", "native_class_ghost_register_dm")
	register_native("zp_class_ghost_get_id", "native_class_ghost_get_id")
	register_native("zp_class_ghost_get_name", "native_class_ghost_get_name")
	register_native("zp_class_ghost_get_real_name", "_class_ghost_get_real_name")
	register_native("zp_class_ghost_get_desc", "native_class_ghost_get_desc")
	register_native("zp_class_ghost_get_kb", "native_class_ghost_get_kb")
	register_native("zp_class_ghost_get_dm", "native_class_ghost_get_dm")
	register_native("zp_class_ghost_get_count", "native_class_ghost_get_count")
	register_native("zp_class_ghost_show_menu", "native_class_ghost_show_menu")
	register_native("zp_class_ghost_menu_text_add", "_class_ghost_menu_text_add")
	register_native("zp_class_ghost_get", "native_class_ghost_get")
	register_native("zp_class_ghost_set", "native_class_ghost_set")
	register_native("zp_class_ghost_get_alive_count", "_class_ghost_get_alive_count")
	register_native("zp_class_ghost_get_infection", "_class_ghost_get_infection")
	register_native("zp_get_primary_interval", "_get_interval_primary_attack")
	register_native("zp_get_secondary_interval", "_get_interval_secondary_attack")
	register_native("zp_get_primary_damage", "_get_damage_primary_attack")
	register_native("zp_get_secondary_damage", "_get_damage_secondary_attack")
	
	// 初始化动态数组
	g_GhostClassRealName = ArrayCreate(32, 1)
	g_GhostClassName = ArrayCreate(32, 1)
	g_GhostClassDesc = ArrayCreate(32, 1)
	g_GhostClassHealth = ArrayCreate(1, 1)
	g_GhostClassSpeed = ArrayCreate(1, 1)
	g_GhostClassGravity = ArrayCreate(1, 1)
	g_GhostClassKnockback = ArrayCreate(1, 1)
	g_GhostClassKnockbackFile = ArrayCreate(1, 1)
	g_GhostClassDMFile = ArrayCreate(1, 1)
	g_GhostClassDamageMultiplier = ArrayCreate(1, 1)
	g_GhostClassModelsHandle = ArrayCreate(1, 1)
	g_GhostClassModelsFile = ArrayCreate(1, 1)
	g_GhostClassClawsHandle = ArrayCreate(1, 1)
	g_GhostClassClawsFile = ArrayCreate(1, 1)
	g_GhostClassAllowInfection = ArrayCreate(1, 1)
	g_IntervalPrimaryAttack = ArrayCreate(1, 1)
	g_IntervalSecondaryAttack = ArrayCreate(1, 1)
	g_DamagePrimaryAttack = ArrayCreate(1, 1)
	g_DamageSecondaryAttack = ArrayCreate(1, 1)
}

public client_putinserver(id)
{
	g_GhostClass[id] = ZP_INVALID_GHOST_CLASS
	g_GhostClassNext[id] = ZP_INVALID_GHOST_CLASS
}

public client_disconnect(id)
{
	// 重置菜单页
	MENU_PAGE_CLASS = 0
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was nemesis before disconnecting)
	flag_unset(g_IsGhost, id)
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsGhost, id))
	{
		// Remove nemesis flag
		flag_unset(g_IsGhost, id)
	}
}

public show_class_menu(id)
{
	if (zp_core_is_zombie(id))
		show_menu_ghostclass(id)
}

public show_menu_ghostclass(id)
{
	static menu[128], name[32], description[32], transkey[64]
	new menuid, itemdata[2], index
	
	formatex(menu, charsmax(menu), "%L\r", id, "MENU_GCLASS")
	menuid = menu_create(menu, "menu_ghostclass")
	
	for (index = 0; index < g_GhostClassCount; index++)
	{
		// Additional text to display
		g_AdditionalMenuText[0] = 0
		
		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
		
		// 展示类型给玩家?
		if (g_ForwardResult >= ZP_CLASS_DONT_SHOW)
			continue;
		
		ArrayGetString(g_GhostClassName, index, name, charsmax(name))
		ArrayGetString(g_GhostClassDesc, index, description, charsmax(description))
		
		// ML support for class name + description
		formatex(transkey, charsmax(transkey), "GHOSTDESC %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(description, charsmax(description), "%L", id, transkey)
		formatex(transkey, charsmax(transkey), "GHOSTDNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		// 类型属性展示?
		if (g_ForwardResult >= ZP_CLASS_NOT_AVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %s %s", name, description, g_AdditionalMenuText)
		// Class is current class?
		else if (index == g_GhostClassNext[id])
			formatex(menu, charsmax(menu), "\r%s \y%s \w%s", name, description, g_AdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%s \w%s", name, description, g_AdditionalMenuText)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}
	
	// 没有类型显示?
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_CLASSES")
		menu_destroy(menuid)
		return;
	}
	
	// 返回 - 下一页 - 退出
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

public menu_ghostclass(id, menuid, item)
{
	// 菜单已经关闭
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
	g_GhostClassNext[id] = index
	
	new name[32], transkey[64], msg[256]
	new Float:maxspeed = Float:ArrayGetCell(g_GhostClassSpeed, g_GhostClassNext[id])
	ArrayGetString(g_GhostClassName, g_GhostClassNext[id], name, charsmax(name))
	// ML support for class name
	formatex(transkey, charsmax(transkey), "GHOSTNAME %s", name)
	if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
	
	// Show selected ghost class
	formatex(msg, charsmax(msg), "%L: %s", id, "GHOST_SELECT", name)
	zp_colored_print(id, msg)
	formatex(msg, charsmax(msg), "%L: %d %L: %d %L: %.2fx %L %.2fx", id, "GHOST_ATTRIB1", ArrayGetCell(g_GhostClassHealth, g_GhostClassNext[id]), id, "GHOST_ATTRIB2", cs_maxspeed_display_value(maxspeed), id, "GHOST_ATTRIB3", Float:ArrayGetCell(g_GhostClassGravity, g_GhostClassNext[id]), id, "GHOST_ATTRIB4", Float:ArrayGetCell(g_GhostClassKnockback, g_GhostClassNext[id]))
	zp_colored_print(id, msg)
	
	// Execute class select post forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_POST], g_ForwardResult, id, index)
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

public zp_fw_core_infect_post(id, attacker)
{
	if (!flag_get(g_IsGhost, id))
		return;
	
	// 如果没有选择的话展示幽灵类型菜单 (e.g. just connected)
	if (g_GhostClassNext[id] == ZP_INVALID_GHOST_CLASS)
	{
		if (g_GhostClassCount > 1)
			show_menu_ghostclass(id)
		else // If only one class is registered, choose it automatically
			g_GhostClassNext[id] = 0
	}
	
	// 机器人自动选择类型
	if (is_user_bot(id))
	{
		// 试着选择类型
		new index, start_index = random_num(0, g_GhostClassCount - 1)
		for (index = start_index + 1; /* no condition */; index++)
		{
			// Start over when we reach the end
			if (index >= g_GhostClassCount)
				index = 0
			
			// Execute class select attempt forward
			ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_ForwardResult, id, index)
			
			// Class available to player?
			if (g_ForwardResult < ZP_CLASS_NOT_AVAILABLE)
			{
				g_GhostClassNext[id] = index
				break;
			}
			
			// Loop completed, no class could be chosen
			if (index == start_index)
				break;
		}
	}
	
	// 选择幽灵类型. 如果还没选择, 使用第一个类型
	g_GhostClass[id] = g_GhostClassNext[id]
	if (g_GhostClass[id] == ZP_INVALID_GHOST_CLASS) g_GhostClass[id] = 0
	
	// 添加幽灵属性
	set_user_health(id, ArrayGetCell(g_GhostClassHealth, g_GhostClass[id]))
	set_user_gravity(id, Float:ArrayGetCell(g_GhostClassGravity, g_GhostClass[id]))
	cs_set_player_maxspeed_auto(id, Float:ArrayGetCell(g_GhostClassSpeed, g_GhostClass[id]))
	
	// 添加幽灵模型
	new Array:class_models = ArrayGetCell(g_GhostClassModelsHandle, g_GhostClass[id])
	if (class_models != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_models) - 1)
		new player_model[32]
		ArrayGetString(class_models, index, player_model, charsmax(player_model))
		cs_set_player_model(id, player_model)
	}
	else
	{
		// 当前类型没有模型, 使用默认模型
		cs_set_player_model(id, GHOSTS_DEFAULT_MODEL)
	}
	
	// 添加幽灵手臂模型
	new claw_model[64], Array:class_claws = ArrayGetCell(g_GhostClassClawsHandle, g_GhostClass[id])
	if (class_claws != Invalid_Array)
	{
		new index = random_num(0, ArraySize(class_claws) - 1)
		ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
		cs_set_player_view_model(id, CSW_KNIFE, claw_model)
	}
	else
	{
		// 当前类型没有模型, 使用默认模型
		cs_set_player_view_model(id, CSW_KNIFE, GHOSTS_DEFAULT_CLAWMODEL)
	}
	cs_set_player_weap_model(id, CSW_KNIFE, "")
	
	// 添加武器给幽灵
	cs_set_player_weap_restrict(id, true, GHOST_ALLOWED_WEAPONS_BITSUM, GHOST_DEFAULT_ALLOWED_WEAPON)
}

public zp_fw_core_cure(id, attacker)
{
	if (!flag_get(g_IsGhost, id))
		return;
	// 移除幽灵手臂模型
	cs_reset_player_view_model(id, CSW_KNIFE)
	cs_reset_player_weap_model(id, CSW_KNIFE)
	
	// 移除幽灵武器
	cs_set_player_weap_restrict(id, false)
	
	// Remove ghost flag
	flag_unset(g_IsGhost, id)
}

public native_class_ghost_get_current(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return ZP_INVALID_GHOST_CLASS;
	}
	
	return g_GhostClass[id];
}

public native_class_ghost_get_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return ZP_INVALID_GHOST_CLASS;
	}
	
	return g_GhostClassNext[id];
}

public native_class_ghost_set_next(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return false;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	g_GhostClassNext[id] = classid
	return true;
}

public _class_ghost_get_max_health(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return -1;
	}
	
	new classid = get_param(2)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return -1;
	}
	
	return ArrayGetCell(g_GhostClassHealth, classid);
}

public native_class_ghost_register(plugin_id, num_params)
{
	new name[32]
	get_string(1, name, charsmax(name))
	
	if (strlen(name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't register ghost class with an empty name")
		return ZP_INVALID_GHOST_CLASS;
	}
	
	new index, ghostclass_name[32]
	for (index = 0; index < g_GhostClassCount; index++)
	{
		ArrayGetString(g_GhostClassRealName, index, ghostclass_name, charsmax(ghostclass_name))
		if (equali(name, ghostclass_name))
		{
			log_error(AMX_ERR_NATIVE, "[ZP] Ghost class already registered (%s)", name)
			return ZP_INVALID_GHOST_CLASS;
		}
	}
	
	new description[32]
	get_string(2, description, charsmax(description))
	new health = get_param(3)
	new Float:speed = get_param_f(4)
	new Float:gravity = get_param_f(5)
	new infection = get_param(6)
	new Float:intervalPrimaryAttack = get_param_f(7)
	new Float:intervalSecondaryAttack = get_param_f(8)
	new Float:damagePrimaryAttack = get_param_f(9)
	new Float:damageSecondaryAttack = get_param_f(10)
	
	// 从有另类性文件载入配置
	new real_name[32]
	copy(real_name, charsmax(real_name), name)
	ArrayPushString(g_GhostClassRealName, real_name)
	
	// Name
	if (!amx_load_setting_string(ZP_GHOSTCLASSES_FILE, real_name, "NAME", name, charsmax(name)))
		amx_save_setting_string(ZP_GHOSTCLASSES_FILE, real_name, "NAME", name)
	ArrayPushString(g_GhostClassName, name)
	
	// Description
	if (!amx_load_setting_string(ZP_GHOSTCLASSES_FILE, real_name, "INFO", description, charsmax(description)))
		amx_save_setting_string(ZP_GHOSTCLASSES_FILE, real_name, "INFO", description)
	ArrayPushString(g_GhostClassDesc, description)
	
	// Models
	new Array:class_models = ArrayCreate(32, 1)
	amx_load_setting_string_arr(ZP_GHOSTCLASSES_FILE, real_name, "MODELS", class_models)
	if (ArraySize(class_models) > 0)
	{
		ArrayPushCell(g_GhostClassModelsFile, true)
		
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
		ArrayPushCell(g_GhostClassModelsFile, false)
		ArrayDestroy(class_models)
		amx_save_setting_string(ZP_GHOSTCLASSES_FILE, real_name, "MODELS", GHOSTS_DEFAULT_MODEL)
	}
	ArrayPushCell(g_GhostClassModelsHandle, class_models)
	
	// Claw models
	new Array:class_claws = ArrayCreate(64, 1)
	amx_load_setting_string_arr(ZP_GHOSTCLASSES_FILE, real_name, "CLAWMODEL", class_claws)
	if (ArraySize(class_claws) > 0)
	{
		ArrayPushCell(g_GhostClassClawsFile, true)
		
		// Precache claw models
		new index, claw_model[64]
		for (index = 0; index < ArraySize(class_claws); index++)
		{
			ArrayGetString(class_claws, index, claw_model, charsmax(claw_model))
			precache_model(claw_model)
		}
	}
	else
	{
		ArrayPushCell(g_GhostClassClawsFile, false)
		ArrayDestroy(class_claws)
		amx_save_setting_string(ZP_GHOSTCLASSES_FILE, real_name, "CLAWMODEL", GHOSTS_DEFAULT_CLAWMODEL)
	}
	ArrayPushCell(g_GhostClassClawsHandle, class_claws)
	
	// Infection
	if (!amx_load_setting_int(ZP_GHOSTCLASSES_FILE, real_name, "INFECTION", infection))
		amx_save_setting_int(ZP_GHOSTCLASSES_FILE, real_name, "INFECTION", infection)
	ArrayPushCell(g_GhostClassAllowInfection, infection)
	
	// Health
	if (!amx_load_setting_int(ZP_GHOSTCLASSES_FILE, real_name, "HEALTH", health))
		amx_save_setting_int(ZP_GHOSTCLASSES_FILE, real_name, "HEALTH", health)
	ArrayPushCell(g_GhostClassHealth, health)
	
	// Speed
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "SPEED", speed))
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "SPEED", speed)
	ArrayPushCell(g_GhostClassSpeed, speed)
	
	// Interval PrimaryAttack
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "PRIMARY ATTACK INTERVAL", intervalPrimaryAttack))
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "PRIMARY ATTACK INTERVAL", intervalPrimaryAttack)
	ArrayPushCell(g_IntervalPrimaryAttack, intervalPrimaryAttack)
	
	// Interval SecondaryAttack
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "SECONDARY ATTACK INTERVAL", intervalSecondaryAttack))
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "SECONDARY ATTACK INTERVAL", intervalSecondaryAttack)
	ArrayPushCell(g_IntervalSecondaryAttack, intervalSecondaryAttack)
	
	// Damage PrimaryAttack
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "PRIMARY ATTACK DAMAGE", damagePrimaryAttack))
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "PRIMARY ATTACK DAMAGE", damagePrimaryAttack)
	ArrayPushCell(g_DamagePrimaryAttack, damagePrimaryAttack)
	
	// Damage SecondaryAttack
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "SECONDARY ATTACK DAMAGE", damageSecondaryAttack))
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "SECONDARY ATTACK DAMAGE", damageSecondaryAttack)
	ArrayPushCell(g_DamageSecondaryAttack, damageSecondaryAttack)
	
	// Gravity
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "GRAVITY", gravity))
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "GRAVITY", gravity)
	ArrayPushCell(g_GhostClassGravity, gravity)
	
	// Damage multiplier
	new Float:damage_multiplier = GHOSTS_DEFAULT_DMULTIPLIER
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "DAMAGE MULTIPLIER", damage_multiplier))
	{
		ArrayPushCell(g_GhostClassDMFile, false)
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "DAMAGE MULTIPLIER", damage_multiplier)
	}
	else
		ArrayPushCell(g_GhostClassDMFile, true)
	ArrayPushCell(g_GhostClassDamageMultiplier, damage_multiplier)
	
	// Knockback
	new Float:knockback = GHOSTS_DEFAULT_KNOCKBACK
	if (!amx_load_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "KNOCKBACK", knockback))
	{
		ArrayPushCell(g_GhostClassKnockbackFile, false)
		amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "KNOCKBACK", knockback)
	}
	else
		ArrayPushCell(g_GhostClassKnockbackFile, true)
	ArrayPushCell(g_GhostClassKnockback, knockback)
	
	g_GhostClassCount++
	return g_GhostClassCount - 1;
}

public _class_ghost_register_model(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Ghost class id (%d)", classid)
		return false;
	}
	
	// Player models already loaded from file
	if (ArrayGetCell(g_GhostClassModelsFile, classid))
		return true;
	
	new player_model[32]
	get_string(2, player_model, charsmax(player_model))
	
	new model_path[128]
	formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
	
	precache_model(model_path)
	
	// Support modelT.mdl files
	formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
	if (file_exists(model_path)) precache_model(model_path)
	
	new Array:class_models = ArrayGetCell(g_GhostClassModelsHandle, classid)
	
	// No models registered yet?
	if (class_models == Invalid_Array)
	{
		class_models = ArrayCreate(32, 1)
		ArraySetCell(g_GhostClassModelsHandle, classid, class_models)
	}
	ArrayPushString(class_models, player_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_GhostClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_GHOSTCLASSES_FILE, real_name, "MODELS", class_models)
	
	return true;
}

public _class_ghost_register_claw(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	// Claw models already loaded from file
	if (ArrayGetCell(g_GhostClassClawsFile, classid))
		return true;
	
	new claw_model[64]
	get_string(2, claw_model, charsmax(claw_model))
	
	precache_model(claw_model)
	
	new Array:class_claws = ArrayGetCell(g_GhostClassClawsHandle, classid)
	
	// No models registered yet?
	if (class_claws == Invalid_Array)
	{
		class_claws = ArrayCreate(64, 1)
		ArraySetCell(g_GhostClassClawsHandle, classid, class_claws)
	}
	ArrayPushString(class_claws, claw_model)
	
	// Save models to file
	new real_name[32]
	ArrayGetString(g_GhostClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_string_arr(ZP_GHOSTCLASSES_FILE, real_name, "CLAWMODEL", class_claws)
	
	return true;
}

public native_class_ghost_register_kb(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	// Knockback already loaded from file
	if (ArrayGetCell(g_GhostClassKnockbackFile, classid))
		return true;
	
	new Float:knockback = get_param_f(2)
	
	// Set ghost class knockback
	ArraySetCell(g_GhostClassKnockback, classid, knockback)
	
	// Save to file
	new real_name[32]
	ArrayGetString(g_GhostClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "KNOCKBACK", knockback)
	
	return true;
}

public native_class_ghost_register_dm(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	// Damage multiplier already loaded from file
	if (ArrayGetCell(g_GhostClassDMFile, classid))
		return true;
	
	new Float:damage_multiplier = get_param_f(2)
	
	// Set ghost class damage multiplier
	ArraySetCell(g_GhostClassDamageMultiplier, classid, damage_multiplier)
	
	// Save to file
	new real_name[32]
	ArrayGetString(g_GhostClassRealName, classid, real_name, charsmax(real_name))
	amx_save_setting_float(ZP_GHOSTCLASSES_FILE, real_name, "DAMAGE MULTIPLIER", damage_multiplier)
	
	return true;
}

public native_class_ghost_get_id(plugin_id, num_params)
{
	new real_name[32]
	get_string(1, real_name, charsmax(real_name))
	
	// Loop through every class
	new index, ghostclass_name[32]
	for (index = 0; index < g_GhostClassCount; index++)
	{
		ArrayGetString(g_GhostClassRealName, index, ghostclass_name, charsmax(ghostclass_name))
		if (equali(real_name, ghostclass_name))
			return index;
	}
	
	return ZP_INVALID_GHOST_CLASS;
}

public native_class_ghost_get_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	new name[32]
	ArrayGetString(g_GhostClassName, classid, name, charsmax(name))
	
	new len = get_param(3)
	set_string(2, name, len)
	return true;
}

public _class_ghost_get_real_name(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	new real_name[32]
	ArrayGetString(g_GhostClassRealName, classid, real_name, charsmax(real_name))
	
	new len = get_param(3)
	set_string(2, real_name, len)
	return true;
}

public native_class_ghost_get_desc(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return false;
	}
	
	new description[32]
	ArrayGetString(g_GhostClassDesc, classid, description, charsmax(description))
	
	new len = get_param(3)
	set_string(2, description, len)
	return true;
}

public Float:native_class_ghost_get_kb(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return GHOSTS_DEFAULT_KNOCKBACK;
	}
	
	// Return ghost class knockback
	return ArrayGetCell(g_GhostClassKnockback, classid);
}

public Float:native_class_ghost_get_dm(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return GHOSTS_DEFAULT_DMULTIPLIER;
	}
	
	// Return ghost class damage multiplier)
	return ArrayGetCell(g_GhostClassDamageMultiplier, classid);
}

public native_class_ghost_get_count(plugin_id, num_params)
{
	return g_GhostClassCount;
}

public native_class_ghost_show_menu(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return false;
	}
	
	show_menu_ghostclass(id)
	return true;
}

public _class_ghost_menu_text_add(plugin_id, num_params)
{
	static text[32]
	get_string(1, text, charsmax(text))
	format(g_AdditionalMenuText, charsmax(g_AdditionalMenuText), "%s%s", g_AdditionalMenuText, text)
}

public native_class_ghost_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsGhost, id);
}

public native_class_ghost_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsGhost, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a ghost (%d)", id)
		return false;
	}
	
	new attacker = get_param(2)
	
	if (attacker && !is_user_connected(attacker))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Ghost Invalid Player (%d)", attacker)
		return false;
	}
	flag_set(g_IsGhost, id)
	return zp_core_infect(id, attacker)
}

public _class_ghost_get_alive_count(plugin_id, num_params)
{
	return GetGhostCount();
}


public _class_ghost_get_infection(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return -1;
	}
	
	return bool:ArrayGetCell(g_GhostClassAllowInfection, classid);
}

public Float:_get_interval_primary_attack(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return DEFAULT_INTERVAL_PRIMARYATTACK;
	}
	
	return ArrayGetCell(g_IntervalPrimaryAttack, classid);
}

public Float:_get_interval_secondary_attack(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return DEFAULT_INTERVAL_SECONDARYATTACK;
	}
	
	return ArrayGetCell(g_IntervalSecondaryAttack, classid);
}

public Float:_get_damage_primary_attack(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return DEFAULT_DAMAGE_PRIMARYATTACK;
	}
	
	return ArrayGetCell(g_DamagePrimaryAttack, classid);
}

public Float:_get_damage_secondary_attack(plugin_id, num_params)
{
	new classid = get_param(1)
	
	if (classid < 0 || classid >= g_GhostClassCount)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid ghost class id (%d)", classid)
		return DEFAULT_DAMAGE_SECONDARYATTACK;
	}
	
	return ArrayGetCell(g_DamageSecondaryAttack, classid);
}

// Get Ghost Count -returns alive ghost number-
GetGhostCount()
{
	new iGhost, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsGhost, id))
			iGhost++
	}
	
	return iGhost;
}
