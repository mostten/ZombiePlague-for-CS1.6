#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

// CS Player PData Offsets (win32)
#define OFFSET_CSMENUCODE	205
#define TASK_ATTACK_STOP	100
#define ID_ATTACK_STOP		(taskid - TASK_ATTACK_STOP)
#define MAX_POINT			128
#define STRING_MAX_LENGTH 	256

// Npc Classes file
//new const ZP_NPCCLASSES_FILE[] = "zp_npclasses.ini";

#define NPCS_DEFAULT_CLASSNAME 		"zp_npc_default"
#define NPCS_DEFAULT_MODEL 			"models/zombie_plague/zp_predator/npc_alien.mdl"

#define NPCS_DEFAULT_SOUND_HURT	 	"zombie_plague/predator/alien_pain_01.wav"
#define NPCS_DEFAULT_SOUND_ATTACK 	"zombie_plague/zaphie/claw/zombie_hit1.wav"
#define NPCS_DEFAULT_SOUND_DIE 		"zombie_plague/predator/alien_die_01.wav"

#define NPCS_DEFAULT_ANIM_IDLE		"idle"
#define NPCS_DEFAULT_ANIM_RUN		"run"
#define NPCS_DEFAULT_ANIM_ATTACK	"attack"
#define NPCS_DEFAULT_ANIM_DIE		"death"
#define NPCS_DEFAULT_ANIM_JUMP		"run"
#define NPCS_DEFAULT_ANIM_FALL		"run"

#define NPCS_DEFAULT_SPEED 			250.0
#define NPCS_DEFAULT_HEALTH 		100.0
#define NPCS_DEFAULT_DAMAGE 		10.0
#define NPCS_DEFAULT_GRAVITY 		1.0
#define NPCS_DEFAULT_JUMP_HEIGHT 	90.0

new const Float:npc_size_maxs[3] = {16.0, 16.0, 36.0};
new const Float:npc_size_mins[3] = {-16.0, -16.0, 2.0};

new static info_target;

enum SoundType{
	SoundType_Hurt = 0,
	SoundType_Attack,
	SoundType_Die
};

enum AnimType{
	AnimType_Idle = 0,
	AnimType_Run,
	AnimType_Attack,
	AnimType_Die,
	AnimType_Jump,
	AnimType_Fall
};

enum SoundInfo{
	SoundInfo_ClassId = 0,
	SoundInfo_FileIndex,
	SoundType:SoundInfo_Type
};

enum AnimInfo{
	AnimInfo_ClassId = 0,
	AnimInfo_FileIndex,
	AnimType:AnimInfo_Type
};

enum EntInfo{
	EntInfo_ClassId = 0,
	EntInfo_Entity
};

enum NpcInfo{
	NpcInfo_Name = 0,
	NpcInfo_Class,
	NpcInfo_Model,
	Float:NpcInfo_Speed,
	Float:NpcInfo_Health,
	Float:NpcInfo_Damage,
	Float:NpcInfo_Gravity,
	Float:NpcInfo_JumpHeight,
	Float:NpcInfo_MinsX,
	Float:NpcInfo_MinsY,
	Float:NpcInfo_MinsZ,
	Float:NpcInfo_MaxsX,
	Float:NpcInfo_MaxsY,
	Float:NpcInfo_MaxsZ
};

enum PointInfo{
	Float:Point_X = 0,
	Float:Point_Y,
	Float:Point_Z,
	Point_Jump
}

enum _:TotalForwards
{
	FW_NPC_SPAWN_POST = 0,
	FW_NPC_DEAD_POST,
	FW_NPC_ATTACK_PRE,
	FW_NPC_ATTACK_POST
};

new g_maxplayers;
new g_point_index = 0;
new bool:g_round_Start = false;
new g_spawn_points[MAX_POINT][_:PointInfo];

new g_ForwardResult;
new g_Forwards[TotalForwards];

new Array:g_NpcClassEntsInfos = Invalid_Array;
new Array:g_NpcClassNpcsInfos = Invalid_Array;
new Array:g_NpcClassSoundsInfos = Invalid_Array;
new Array:g_NpcClassAnimsInfos = Invalid_Array;
new Array:g_NpcClassStringList = Invalid_Array;

public plugin_init()
{
	register_plugin("[ZP] Class: Npc", "1.0", "Mostten");
	
	register_clcmd("say /nclass", "show_menu_npcclass", ADMIN_ADMIN);
	
	g_Forwards[FW_NPC_SPAWN_POST] = CreateMultiForward("zp_fw_npc_spawn_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[FW_NPC_DEAD_POST] = CreateMultiForward("zp_fw_npc_dead_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[FW_NPC_ATTACK_PRE] = CreateMultiForward("zp_fw_npc_attack_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_NPC_ATTACK_POST] = CreateMultiForward("zp_fw_npc_attack_post", ET_IGNORE, FP_CELL, FP_CELL);
	
	register_forward(FM_CmdStart, "fw_cmdstart");
	
	register_logevent("event_round_start",2, "1=Round_Start");
	register_logevent("event_round_end", 2, "1&Restart_Round");
	register_logevent("event_round_end", 2, "1=Game_Commencing");
	register_logevent("event_round_end", 2, "1=Round_End");
	
	g_maxplayers = get_maxplayers();
	
	info_target = engfunc(EngFunc_AllocString, "info_target");
}

public plugin_cfg()
{
	PointArraysInit();
}

public plugin_precache()
{
	precache_model(NPCS_DEFAULT_MODEL);
	
	PrecacheSound(NPCS_DEFAULT_SOUND_HURT);
	PrecacheSound(NPCS_DEFAULT_SOUND_ATTACK);
	PrecacheSound(NPCS_DEFAULT_SOUND_DIE);
}

public plugin_natives()
{
	register_library("zp50_class_npc");
	
	register_native("zp_class_npc_get_classid", "native_class_npc_get_classid");
	register_native("zp_class_npc_get", "native_class_npc_get");
	register_native("zp_class_npc_get_count", "native_class_npc_get_count");
	register_native("zp_class_npc_register", "native_class_npc_register");
	register_native("zp_class_npc_sound_register", "native_class_npc_sound_register");
	register_native("zp_class_npc_anim_register", "native_class_npc_anim_register");
	register_native("zp_class_npc_get_name", "native_class_npc_get_name");
	register_native("zp_class_npc_spawn", "native_class_npc_spawn");
	register_native("zp_class_npc_show_menu", "native_class_npc_show_menu");
	register_native("zp_class_npc_random_point", "native_class_npc_random_point");
	
	ArraysInit();
}

public show_menu_npcclass(id)
{
	// Player dead
	if (!is_user_alive(id))
		return;
	
	ShowNpcsListMenu(id);
}

public native_class_npc_get_classid(plugin_id, num_params)
{
	new entity = get_param(1);
	return GetNpcClassid(entity);
}

public native_class_npc_get(plugin_id, num_params)
{
	new entity = get_param(1);
	return (GetNpcClassid(entity) >= 0);
}


public native_class_npc_get_count(plugin_id, num_params)
{
	new classid = get_param(1);
	return GetNpcsCount(classid);
}

public native_class_npc_register(plugin_id, num_params)
{
	new name[STRING_MAX_LENGTH];
	new classname[STRING_MAX_LENGTH];
	new model[STRING_MAX_LENGTH];
	new Float:mins[3], Float:maxs[3];
	new Float:speed, Float:health, Float:damage, Float:gravity, Float:jump_height;
	
	get_string(1, name, charsmax(name));
	get_string(2, classname, charsmax(classname));
	get_string(3, model, charsmax(model));
	get_array_f(4, mins, sizeof(mins));
	get_array_f(5, maxs, sizeof(maxs));
	speed = get_param_f(6);
	health = get_param_f(7);
	damage = get_param_f(8);
	gravity = get_param_f(9);
	jump_height = get_param_f(10);
	
	return PushNpcInfosToArray(name, classname, model, mins, maxs, speed, health, damage, gravity, jump_height);
}

public native_class_npc_sound_register(plugin_id, num_params)
{
	new classid = get_param(1);
	new sound[STRING_MAX_LENGTH];
	
	get_string(2, sound, charsmax(sound));
	PushSoundToArray(classid, sound, SoundType_Hurt);
	
	get_string(3, sound, charsmax(sound));
	PushSoundToArray(classid, sound, SoundType_Attack);
	
	get_string(4, sound, charsmax(sound));
	PushSoundToArray(classid, sound, SoundType_Die);
}

public native_class_npc_anim_register(plugin_id, num_params)
{
	new classid = get_param(1);
	new anim[STRING_MAX_LENGTH];
	
	get_string(2, anim, charsmax(anim));
	PushAnimToArray(classid, anim, AnimType_Idle);
	
	get_string(3, anim, charsmax(anim));
	PushAnimToArray(classid, anim, AnimType_Run);
	
	get_string(4, anim, charsmax(anim));
	PushAnimToArray(classid, anim, AnimType_Attack);
	
	get_string(5, anim, charsmax(anim));
	PushAnimToArray(classid, anim, AnimType_Die);
	
	get_string(6, anim, charsmax(anim));
	PushAnimToArray(classid, anim, AnimType_Jump);
	
	get_string(7, anim, charsmax(anim));
	PushAnimToArray(classid, anim, AnimType_Fall);
}

public native_class_npc_get_name(plugin_id, num_params)
{
	new bool:result = false;
	new name[STRING_MAX_LENGTH];
	
	new classid = get_param(1);
	result = GetNpcInfosName(classid, name, charsmax(name));
	
	if(result)
	{
		new len = get_param(3);
		set_string(2, name, len);
	}
	
	return result;
}

public native_class_npc_spawn(plugin_id, num_params)
{
	new classid = get_param(1);
	return SpawnNpcRandomPoint(classid);
}

public native_class_npc_show_menu(plugin_id, num_params)
{
	new id = get_param(1);
	ShowNpcsListMenu(id);
}

public native_class_npc_random_point(plugin_id, num_params)
{
	new bool:jump;
	new Float:origin[3];
	
	if(GetArrayRandomPoint(origin, jump))
	{
		set_array_f(1, origin, sizeof(origin));
		set_param_byref(2, jump);
		
		return is_hull_vacant(origin);
	}
	
	return false;
}

ArraysInit()
{
	if(g_NpcClassEntsInfos == Invalid_Array)
		g_NpcClassEntsInfos = ArrayCreate(_:EntInfo, 1);
	
	if(g_NpcClassNpcsInfos == Invalid_Array)
		g_NpcClassNpcsInfos = ArrayCreate(_:NpcInfo, 1);
	
	if(g_NpcClassSoundsInfos == Invalid_Array)
		g_NpcClassSoundsInfos = ArrayCreate(_:SoundInfo, 1);
	
	if(g_NpcClassAnimsInfos == Invalid_Array)
		g_NpcClassAnimsInfos = ArrayCreate(_:AnimInfo, 1);
	
	if(g_NpcClassStringList == Invalid_Array)
		g_NpcClassStringList = ArrayCreate(STRING_MAX_LENGTH, 1);
}

PushNpcInfosToArray(const name[], const classname[], const model[], const Float:mins[3], const Float:maxs[3], const Float:speed, const Float:health, const Float:damage, const Float:gravity, const Float:jump_height)
{
	new name_index, classname_index, model_index;
	
	new info_index = GetArrayNpcInfosIndex(name, classname, model, name_index, classname_index, model_index);
	
	if(info_index >= 0){return info_index;}
	
	if(name_index < 0)
		name_index = ArrayPushString(g_NpcClassStringList, name);
	if(classname_index < 0)
	{
		classname_index = ArrayPushString(g_NpcClassStringList, classname);
		register_think(classname, "fw_npc_think");
	}
	if(model_index < 0 && file_exists(model))
	{
		precache_model(model);
		model_index = ArrayPushString(g_NpcClassStringList, model);
	}
	
	new any:infos[_:NpcInfo];
	
	infos[_:NpcInfo_Name] = name_index;
	infos[_:NpcInfo_Class] = classname_index;
	infos[_:NpcInfo_Model] = model_index;
	infos[_:NpcInfo_Speed] = speed;
	infos[_:NpcInfo_Health] = health;
	infos[_:NpcInfo_Damage] = damage;
	infos[_:NpcInfo_Gravity] = gravity;
	infos[_:NpcInfo_JumpHeight] = jump_height;
	infos[_:NpcInfo_MinsX] = mins[0];
	infos[_:NpcInfo_MinsY] = mins[1];
	infos[_:NpcInfo_MinsZ] = mins[2];
	infos[_:NpcInfo_MaxsX] = maxs[0];
	infos[_:NpcInfo_MaxsY] = maxs[1];
	infos[_:NpcInfo_MaxsZ] = maxs[2];
	
	return ArrayPushArray(g_NpcClassNpcsInfos, infos);
}

PushEntInfoToArray(const entity, const classid)
{
	new index = GetArrayEntInfoIndex(entity);
	
	if(index < 0)
	{
		new infos[_:EntInfo];
		infos[_:EntInfo_Entity] = entity;
		infos[_:EntInfo_ClassId] = classid;
		
		index = ArrayPushArray(g_NpcClassEntsInfos, infos);
	}
	return index;
}

bool:RemoveEntInfoFromArray(const entity)
{
	new index = GetArrayEntInfoIndex(entity);
	
	if(index >= 0)
	{
		ArrayDeleteItem(g_NpcClassEntsInfos, index);
		return true;
	}
	return false;
}

RemoveAllEntInfoFromArray()
{
	new count = ArraySize(g_NpcClassEntsInfos);
	
	if(count <= 0){return 0;}
	
	new infos[_:EntInfo];
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_NpcClassEntsInfos, i, infos);
		
		if(is_valid_ent(infos[_:EntInfo_Entity]))
		{
			remove_entity(infos[_:EntInfo_Entity]);
		}
	}
	
	ArrayClear(g_NpcClassEntsInfos);
	
	return count;
}

GetNpcsCount(const classid = -1)
{
	new maxcount = ArraySize(g_NpcClassEntsInfos);
	
	if(maxcount <= 0 || classid < 0){return maxcount;}
	
	new count = 0;
	new infos[_:EntInfo];
	for(new i = 0; i < maxcount; i++)
	{
		ArrayGetArray(g_NpcClassEntsInfos, i, infos);
		
		if(infos[_:EntInfo_ClassId] == classid){count++;}
	}
	return count;
}

bool:IsValidNpc(const entity)
{
	return (is_valid_ent(entity) && (GetNpcClassid(entity) >= 0));
}

GetNpcClassid(const npc)
{
	new count = ArraySize(g_NpcClassEntsInfos);
	
	if(count <= 0){return -1;}
	
	new infos[_:EntInfo];
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_NpcClassEntsInfos, i, infos);
		if(infos[_:EntInfo_Entity] == npc){return infos[_:EntInfo_ClassId];}
	}
	return -1;
}

GetArrayEntInfoIndex(const entity)
{
	new count = ArraySize(g_NpcClassEntsInfos);
	
	if(count <= 0){return -1;}
	
	new infos[_:EntInfo];
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_NpcClassEntsInfos, i, infos);
		if(infos[_:EntInfo_Entity] == entity){return i;}
	}
	return -1;
}

ShowNpcsListMenu(id)
{
	new count = ArraySize(g_NpcClassNpcsInfos);
	
	if(count <= 0){return;}
	
	new buffer[STRING_MAX_LENGTH];
	new menuid = menu_create("Npcs List", "npcs_list_menu_handle");
	
	for(new i = 0; i < count; i++)
	{
		new itemdata[32];
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, i, infos);
		
		GetArrayString(infos[_:NpcInfo_Name], buffer, charsmax(buffer));
		
		formatex(itemdata, charsmax(itemdata), "%d", i);
		
		menu_additem(menuid, buffer, itemdata);
	}
	
	// Back - Next - Exit
	formatex(buffer, charsmax(buffer), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, buffer)
	formatex(buffer, charsmax(buffer), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, buffer)
	formatex(buffer, charsmax(buffer), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, buffer)
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0);
	menu_display(id, menuid);
}
public npcs_list_menu_handle(id, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	new itemdata[32], dummy;
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy);
	
	new classid = str_to_num(itemdata);
	
	if(classid >= 0)
	{
		new Float:origin[3];
		GetClientAimPosition(id, origin);
		
		SpawnNpc(classid, origin);
	}
	
	menu_destroy(menuid);
	return PLUGIN_HANDLED;
}

GetClientAimPosition(id, Float:origin[3])
{
	new position[3];
	get_user_origin(id, position, Origin_AimEndEyes);
	
	origin[0] = float(position[0]);
	origin[1] = float(position[1]);
	origin[1] = float(position[1]);
}

bool:GetNpcInfosName(const classid, name[], const name_size)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return GetArrayString(infos[_:NpcInfo_Name], name, name_size);
	}
	
	return false;
}

bool:GetNpcInfosClassname(const classid, classname[], const classname_size)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return GetArrayString(infos[_:NpcInfo_Class], classname, classname_size);
	}
	
	formatex(classname, classname_size, NPCS_DEFAULT_CLASSNAME);
	return false;
}

bool:GetNpcInfosModel(const classid, model[], const model_size)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return GetArrayString(infos[_:NpcInfo_Model], model, model_size);
	}
	
	formatex(model, model_size, NPCS_DEFAULT_MODEL);
	return false;
}

Float:GetNpcInfosSpeed(const classid)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return infos[_:NpcInfo_Speed];
	}
	return NPCS_DEFAULT_SPEED;
}

Float:GetNpcInfosHealth(const classid)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return infos[_:NpcInfo_Health];
	}
	return NPCS_DEFAULT_HEALTH;
}

Float:GetNpcInfosDamage(const classid)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return infos[_:NpcInfo_Damage];
	}
	return NPCS_DEFAULT_DAMAGE;
}

Float:GetNpcInfosGravity(const classid)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return infos[_:NpcInfo_Gravity];
	}
	return NPCS_DEFAULT_GRAVITY;
}

Float:GetNpcInfosJumpHeight(const classid)
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		return infos[_:NpcInfo_JumpHeight];
	}
	return NPCS_DEFAULT_JUMP_HEIGHT;
}

bool:GetNpcInfosMinsMaxs(const classid, Float:mins[3], Float:maxs[3])
{
	if(0 <= classid < ArraySize(g_NpcClassNpcsInfos))
	{
		new any:infos[_:NpcInfo];
		
		ArrayGetArray(g_NpcClassNpcsInfos, classid, infos);
		
		mins[0] = infos[_:NpcInfo_MinsX];
		mins[1] = infos[_:NpcInfo_MinsY];
		mins[2] = infos[_:NpcInfo_MinsZ];
		
		maxs[0] = infos[_:NpcInfo_MaxsX];
		maxs[1] = infos[_:NpcInfo_MaxsY];
		maxs[2] = infos[_:NpcInfo_MaxsZ];
		
		return true;
	}
	
	mins[0] = npc_size_mins[0];
	mins[1] = npc_size_mins[1];
	mins[2] = npc_size_mins[2];
	
	maxs[0] = npc_size_maxs[0];
	maxs[1] = npc_size_maxs[1];
	maxs[2] = npc_size_maxs[2];
	
	return false;
}

GetArrayNpcInfosIndex(const name[], const classname[], const model[], &name_index, &classname_index, &model_index)
{
	name_index = -1;
	classname_index = -1;
	model_index = -1;
	
	new count = ArraySize(g_NpcClassNpcsInfos);
	
	if(count > 0)
	{
		new any:infos[_:NpcInfo];
		new temp[STRING_MAX_LENGTH];
		for(new i = 0; i < count; i++)
		{
			ArrayGetArray(g_NpcClassNpcsInfos, i, infos);
			
			if(!GetArrayString(infos[_:NpcInfo_Name], temp, charsmax(temp))){continue;}
			
			if(equal(temp, name))
			{
				name_index = infos[_:NpcInfo_Name];
				classname_index = ArrayFindString(g_NpcClassStringList, classname);
				model_index = ArrayFindString(g_NpcClassStringList, model);
				
				return i;
			}
		}
	}
	return -1;
}

PushSoundToArray(const classid, const sound[], SoundType:type)
{
	if(strlen(sound))
	{
		new sound_index;
		new info_index = GetArraySoundIndex(classid, sound, type, sound_index);
		
		if(info_index >= 0){return info_index;}
		
		if(sound_index < 0)
		{
			PrecacheSound(sound);
			sound_index = ArrayPushString(g_NpcClassStringList, sound);
		}
		
		new infos[_:SoundInfo];
		infos[_:SoundInfo_ClassId] = classid;
		infos[_:SoundInfo_FileIndex] = sound_index;
		infos[_:SoundInfo_Type] = type;
		
		return ArrayPushArray(g_NpcClassSoundsInfos, infos);
	}
	
	return -1;
}

bool:GetArrayRandomSound(const classid, const SoundType:type, sound[], const sound_size)
{
	new bool:result = false;
	new count = ArraySize(g_NpcClassSoundsInfos);
	
	if(count < 0){return result;}
	
	new infos[_:SoundInfo];
	new temp[STRING_MAX_LENGTH];
	new Array:sounds = ArrayCreate(STRING_MAX_LENGTH, 1);
	
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_NpcClassSoundsInfos, i, infos);
		
		if(infos[_:SoundInfo_ClassId] != classid || infos[_:SoundInfo_Type] != type){continue;}
		
		if(!GetArrayString(infos[_:SoundInfo_FileIndex], temp, charsmax(temp))){continue;}
		
		ArrayPushString(sounds, temp);
	}
	
	new random_count = ArraySize(sounds);
	
	if(random_count > 0)
	{
		ArrayGetString(sounds, random_num(0, random_count - 1), sound, sound_size);
		result = strlen(sound) > 0;
	}
	else
	{
		GetDefaultSound(type, sound, sound_size);
		result = false;
	}
	ArrayDestroy(sounds);
	
	return strlen(sound) > 0;
}

GetDefaultSound(const SoundType:type, sound[], const sound_size)
{
	switch(type)
	{
		case SoundType_Hurt:{formatex(sound, sound_size, NPCS_DEFAULT_SOUND_HURT);}
		case SoundType_Attack:{formatex(sound, sound_size, NPCS_DEFAULT_SOUND_ATTACK);}
		case SoundType_Die:{formatex(sound, sound_size, NPCS_DEFAULT_SOUND_DIE);}
	}
	return strlen(sound);
}

GetArraySoundIndex(const classid, const sound[], const SoundType:type, &sound_index)
{
	sound_index = -1;
	new count = ArraySize(g_NpcClassSoundsInfos);
	
	if(count > 0)
	{
		new infos[_:SoundInfo];
		new temp[STRING_MAX_LENGTH];
		for(new i = 0; i < count; i++)
		{
			ArrayGetArray(g_NpcClassSoundsInfos, i, infos);
			
			if(!GetArrayString(infos[_:SoundInfo_FileIndex], temp, charsmax(temp))){continue;}
			
			sound_index = infos[_:SoundInfo_FileIndex];
			
			if(equal(temp, sound) && infos[_:SoundInfo_Type] == type && infos[_:SoundInfo_ClassId] == classid){return i;}
		}
	}
	
	return -1;
}

PushAnimToArray(const classid, const anim[], AnimType:type)
{
	if(strlen(anim))
	{
		new anim_index;
		new info_index = GetArrayAnimIndex(classid, anim, type, anim_index);
		
		if(info_index >= 0){return info_index;}
		
		if(anim_index < 0){anim_index = ArrayPushString(g_NpcClassStringList, anim);}
		
		new infos[_:AnimInfo];
		infos[_:AnimInfo_ClassId] = classid;
		infos[_:AnimInfo_FileIndex] = anim_index;
		infos[_:AnimInfo_Type] = type;
		
		return ArrayPushArray(g_NpcClassSoundsInfos, infos);
	}
	
	return -1;
}

bool:GetArrayRandomAnim(const classid, const AnimType:type, anim[], const anim_size)
{
	new bool:result = false;
	new count = ArraySize(g_NpcClassAnimsInfos);
	
	if(count < 0){return result;}
	
	new infos[_:AnimInfo];
	new temp[STRING_MAX_LENGTH];
	new Array:anims = ArrayCreate(STRING_MAX_LENGTH, 1);
	
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_NpcClassAnimsInfos, i, infos);
		
		if(infos[_:AnimInfo_ClassId] != classid || infos[_:AnimInfo_Type] != type){continue;}
		
		if(!GetArrayString(infos[_:AnimInfo_FileIndex], temp, charsmax(temp))){continue;}
		
		ArrayPushString(anims, temp);
	}
	
	new random_count = ArraySize(anims);
	
	if(random_count > 0)
	{
		ArrayGetString(anims, random_num(0, random_count - 1), anim, anim_size);
		result = strlen(anim) > 0;
	}
	else
	{
		GetDefaultAnim(type, anim, anim_size);
		result = false;
	}
	ArrayDestroy(anims);
	
	return result;
}

GetDefaultAnim(const AnimType:type, anim[], const anim_size)
{
	switch(type)
	{
		case AnimType_Idle:{formatex(anim, anim_size, NPCS_DEFAULT_ANIM_IDLE);}
		case AnimType_Run:{formatex(anim, anim_size, NPCS_DEFAULT_ANIM_RUN);}
		case AnimType_Attack:{formatex(anim, anim_size, NPCS_DEFAULT_ANIM_ATTACK);}
		case AnimType_Die:{formatex(anim, anim_size, NPCS_DEFAULT_ANIM_DIE);}
		case AnimType_Jump:{formatex(anim, anim_size, NPCS_DEFAULT_ANIM_JUMP);}
		case AnimType_Fall:{formatex(anim, anim_size, NPCS_DEFAULT_ANIM_FALL);}
	}
	return strlen(anim);
}

GetArrayAnimIndex(const classid, const anim[], const AnimType:type, &anim_index)
{
	anim_index = -1;
	new count = ArraySize(g_NpcClassAnimsInfos);
	
	if(count > 0)
	{
		new infos[_:AnimInfo];
		new temp[STRING_MAX_LENGTH];
		for(new i = 0; i < count; i++)
		{
			ArrayGetArray(g_NpcClassAnimsInfos, i, infos);
			
			if(!GetArrayString(infos[_:AnimInfo_FileIndex], temp, charsmax(temp))){continue;}
			
			anim_index = infos[_:AnimInfo_FileIndex];
			
			if(equal(temp, anim) && infos[_:AnimInfo_Type] == type && infos[_:AnimInfo_ClassId] == classid){return i;}
		}
	}
	
	return -1;
}

bool:GetArrayString(const index, string[], const string_size)
{
	new bool:result = false;
	
	if(0 <= index < ArraySize(g_NpcClassStringList))
	{
		ArrayGetString(g_NpcClassStringList, index, string, string_size);
		result = true;
	}
	
	return result;
}

PrecacheSound(const sound[])
{
	new bool:result = false;
	new length = strlen(sound);
	new startpos = length - 4;
	
	if(startpos >= 0 && equal(sound[startpos], ".mp3"))
	{
		new path[STRING_MAX_LENGTH];
		format(path, charsmax(path), "sound/%s", sound);
		precache_generic(path);
		result = true;
	}
	else if(length > 0)
	{
		precache_sound(sound);
		result = true;
	}
	
	return result;
}

SpawnNpcRandomPoint(const classid)
{
	new npc = -1;
	new Float:origin[3];
	if(GetRandomVacantPoint(origin) > 0)
		npc = SpawnNpc(classid, origin);
	
	return npc;
}

SpawnNpc(const classid, const Float:origin[3])
{
	new buffer[STRING_MAX_LENGTH];
	new npc = engfunc(EngFunc_CreateNamedEntity, info_target);
	
	RemoveEntInfoFromArray(npc);
	
	entity_set_origin(npc, origin);
	
	entity_set_float(npc, EV_FL_takedamage, DAMAGE_YES);
	entity_set_float(npc, EV_FL_health, GetNpcInfosHealth(classid));
	
	entity_set_float(npc, EV_FL_maxspeed, GetNpcInfosSpeed(classid));
	entity_set_float(npc, EV_FL_gravity, GetNpcInfosGravity(classid));
	entity_set_int(npc, EV_INT_gamestate, 1);
	
	GetNpcInfosClassname(classid, buffer, charsmax(buffer));
	entity_set_string(npc, EV_SZ_classname, buffer);
	
	GetNpcInfosModel(classid, buffer, charsmax(buffer));
	entity_set_model(npc, buffer);
	entity_set_int(npc, EV_INT_solid, SOLID_BBOX);
	
	entity_set_int(npc, EV_INT_movetype, MOVETYPE_PUSHSTEP);
	
	entity_set_edict(npc, EV_ENT_enemy, 0);
	
	entity_set_byte(npc, EV_BYTE_controller1, 125);
	entity_set_byte(npc, EV_BYTE_controller2, 125);
	entity_set_byte(npc, EV_BYTE_controller3, 125);
	entity_set_byte(npc, EV_BYTE_controller4, 125);
	
	new Float:mins[3], Float:maxs[3];
	GetNpcInfosMinsMaxs(classid, mins, maxs);
	entity_set_size(npc, mins, maxs);
	
	GetArrayRandomAnim(classid, AnimType_Idle, buffer, charsmax(buffer));
	play_anim(npc, buffer, 1.0);
	
	entity_set_float(npc, EV_FL_nextthink, halflife_time() + 0.01);
	drop_to_floor(npc);
	
	PushEntInfoToArray(npc, classid);
	
	RegisterHamFromEntity(Ham_TakeDamage, npc, "fw_npc_takedmg", 0);
	RegisterHamFromEntity(Ham_Killed, npc, "fw_npc_killed", 1);
	
	ExecuteForward(g_Forwards[FW_NPC_SPAWN_POST], g_ForwardResult, npc, classid);
	
	return npc;
}

public event_round_start()
{
	g_round_Start = true;
}

public event_round_end()
{
	g_round_Start = false;
	
	RemoveAllEntInfoFromArray();
}

public fw_cmdstart(id, const uc_handle, random_seed)
{
	if(!is_user_valid(id))
		return FMRES_IGNORED;
	
	new user_flags = entity_get_int(id, EV_INT_flags);
	if(user_flags & FL_ONGROUND
	&& !(user_flags & FL_DUCKING))
	{
		new bool:jump = false;
		if(get_uc(uc_handle, UC_Buttons) & IN_JUMP)
			jump = true;
		
		new Float:origin[3];
		entity_get_vector(id, EV_VEC_origin, origin);
		
		AddPointToArrays(origin, jump);
	}
	
	return FMRES_IGNORED;
}

public fw_npc_takedmg(npc, inflictor, attacker, Float:damage, damagebits)
{
	new sound[STRING_MAX_LENGTH];
	new classid = GetNpcClassid(npc);
	
	GetArrayRandomSound(classid, SoundType_Hurt, sound, charsmax(sound));
	emit_sound(npc, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public fw_npc_killed(npc, attacker, shouldgib)
{
	new buffer[STRING_MAX_LENGTH];
	new Float:origin[3], Float:angles[3];
	new classid = GetNpcClassid(npc);
	
	if(classid < 0){return;}
	
	new corpse = engfunc(EngFunc_CreateNamedEntity, info_target);
	
	entity_get_vector(npc, EV_VEC_origin, origin);
	entity_get_vector(npc, EV_VEC_angles, angles);
	
	entity_set_origin(corpse, origin);
	entity_set_vector(corpse, EV_VEC_angles, angles);
	
	GetNpcInfosClassname(classid, buffer, charsmax(buffer));
	format(buffer, charsmax(buffer), "%s_corpse", buffer);
	entity_set_string(corpse, EV_SZ_classname, buffer);
	
	GetNpcInfosModel(classid, buffer, charsmax(buffer));
	entity_set_model(corpse, buffer);
	
	new Float:mins[3], Float:maxs[3];
	GetNpcInfosMinsMaxs(classid, mins, maxs);
	entity_set_size(corpse, mins, maxs);
	
	drop_to_floor(corpse);
	
	GetArrayRandomAnim(classid, AnimType_Die, buffer, charsmax(buffer));
	play_anim(corpse, buffer, 1.0, true);
	
	GetArrayRandomSound(classid, SoundType_Die, buffer, charsmax(buffer));
	emit_sound(corpse, CHAN_BODY, buffer, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_task(2.5, "remove_corpse", corpse);
	
	ExecuteForward(g_Forwards[FW_NPC_DEAD_POST], g_ForwardResult, npc, attacker);
	
	RemoveEntInfoFromArray(npc);
}

public remove_corpse(corpse)
{
	if(is_valid_ent(corpse))
		remove_entity(corpse);
}

public fw_npc_think(npc)
{
	if(!is_valid_ent(npc))
	{
		RemoveEntInfoFromArray(npc);
		
		return PLUGIN_HANDLED;
	}
	
	if(!g_round_Start){return PLUGIN_CONTINUE;}
	
	// 修复贴墙不坠落的bug
	if(!IsNpcOnGround(npc)){npc_fall(npc);}
	
	new anim[STRING_MAX_LENGTH];
	new classid = GetNpcClassid(npc);
	new target = find_closes_enemy(npc);
	if(!is_user_valid(target))
	{
		GetArrayRandomAnim(classid, AnimType_Idle, anim, charsmax(anim));
		play_anim(npc, anim, 1.0);
		
		npc_set_nextthink(npc, get_gametime() + 0.1);
		return PLUGIN_HANDLED;
	}
	
	new Float:npc_origin[3], Float:target_origin[3];
	
	entity_get_vector(npc, EV_VEC_origin, npc_origin);
	entity_get_vector(target, EV_VEC_origin, target_origin);
	
	new Float:distance = get_distance_f(npc_origin, target_origin);
	
	if(distance <= 60.0)
	{
		npc_attack(npc, classid, target);
		npc_set_nextthink(npc, get_gametime() + 2.5);
	}
	else
	{
		GetArrayRandomAnim(classid, AnimType_Run, anim, charsmax(anim));
		play_anim(npc, anim, 1.0);
		
		npc_turntotarget(npc, target);
		
		npc_move(npc, classid, target);
		
		npc_set_nextthink(npc, get_gametime() + 0.1);
	}
	
	return PLUGIN_HANDLED;
}

npc_set_nextthink(const npc, const Float:time)
{
	if(IsValidNpc(npc)){entity_set_float(npc, EV_FL_nextthink, time);}
}

npc_attack(npc, classid, target)
{
	if(classid < 0){return;}
	
	ExecuteForward(g_Forwards[FW_NPC_ATTACK_PRE], g_ForwardResult, npc, target);
	
	if(g_ForwardResult >= PLUGIN_HANDLED){return;}
	
	npc_turntotarget(npc, target);
	
	new buffer[STRING_MAX_LENGTH];
	GetArrayRandomAnim(classid, AnimType_Attack, buffer, charsmax(buffer));
	play_anim(npc, buffer, 1.0);
	
	new Float:damage = GetNpcInfosDamage(classid);
	server_print("TakeDamage:npc:%d, classid:%d, damage:%f", npc, classid, damage);
	ExecuteHam(Ham_TakeDamage, target, 0, target, damage, DMG_GENERIC);
	
	GetArrayRandomSound(classid, SoundType_Attack, buffer, charsmax(buffer));
	emit_sound(target, CHAN_BODY, buffer, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	create_stop_attack_task(npc);
	
	ExecuteForward(g_Forwards[FW_NPC_ATTACK_POST], g_ForwardResult, npc, target);
}

public stop_attack(taskid)
{
	if(is_valid_ent(ID_ATTACK_STOP))
	{
		new anim[STRING_MAX_LENGTH];
		GetArrayRandomAnim(GetNpcClassid(ID_ATTACK_STOP), AnimType_Idle, anim, charsmax(anim));
		play_anim(ID_ATTACK_STOP, anim, 1.0);
	}
	remove_task(taskid);
}

npc_turntotarget(npc, target) 
{
	if(is_user_valid(target)) 
	{
		new Float:npc_origin[3], Float:target_origin[3];
		entity_get_vector(npc, EV_VEC_origin, npc_origin);
		entity_get_vector(target, EV_VEC_origin, target_origin);
		
		new Float:new_angle[3];
		entity_get_vector(npc, EV_VEC_angles, new_angle);
		new Float:x = target_origin[0] - npc_origin[0];
		new Float:z = target_origin[1] - npc_origin[1];

		new Float:radians = floatatan(z/x, radian);
		new_angle[1] = radians * (180 / 3.14);
		if (target_origin[0] < npc_origin[0])
			new_angle[1] -= 180.0;
		
		entity_set_vector(npc, EV_VEC_angles, new_angle);
	}
}

npc_move(npc, classid, target)
{
	new waterlevel = entity_get_int(npc, EV_INT_waterlevel);
	
	//在水里
	if(waterlevel > 1){npc_water_move(npc, classid);}
	
	//在地面上
	else if(IsNpcOnGround(npc))
	{
		// 在地面实时更新水溅跃的CD,防止刚刚碰到水就能进行水溅跃
		entity_set_float(npc, EV_FL_ltime, get_gametime() + 2.0);
		
		new Float:target_origin[3], Float:npc_origin[3];
		entity_get_vector(npc, EV_VEC_origin, npc_origin);
		entity_get_vector(target, EV_VEC_origin, target_origin);
		
		//被物体挡住或者是悬崖
		if(GetEntitySpeed(npc) == 0)
		{
			//尝试跳跃
			npc_jump(npc, classid, npc_origin, target_origin);
		}
		else
		{
			//无障碍正常行走
			//engfunc(EngFunc_MoveToOrigin, npc, target_origin, speed * 0.01, MOVE_STRAFE);
			NpcMoveToOrigin(npc, classid, npc_origin, target_origin);
		}
	}
	
	//刚接触水面
	else if (waterlevel == 1){npc_water_jump(npc, classid);}
	
	//尝试旋转跳
	else{npc_superjump(npc);}
}

GetEntitySpeed(ent)
{
	static Float:velocity[3];
	entity_get_vector(ent, EV_VEC_velocity, velocity);
	
	return floatround(vector_length(velocity));
}

NpcMoveToOrigin(npc, classid, Float:start[3], Float:end[3])
{
	new Float:Velocity[3], Float:Angles[3], Float:Vector[3], Float:Len;
	
	xs_vec_sub(end, start, Vector);
	Len = xs_vec_len(Vector);
	vector_to_angle(Vector, Angles);
	Angles[0] = 0.0;
	Angles[2] = 0.0;
	xs_vec_normalize(Vector, Vector);
	xs_vec_mul_scalar(Vector, GetNpcInfosSpeed(classid), Velocity);
	Velocity[2] = 0.0;
	
	entity_set_vector(npc, EV_VEC_velocity, Velocity);
	entity_set_vector(npc, EV_VEC_angles, Angles);
	
	return floatround(Len, floatround_round);
}

npc_fall(npc)
{
	new Float:gravity = entity_get_float(npc, EV_FL_gravity);
	
	new Float:fallVec = entity_get_float(npc, EV_FL_flFallVelocity);
	
	fallVec += 8.0 * gravity;
	
	entity_set_float(npc, EV_FL_flFallVelocity, fallVec);
}

bool:is_user_valid(id)
{
	return (id && (1 <= id <= g_maxplayers) && is_user_connected(id) && is_user_alive(id));
}

public find_closes_enemy(npc)
{
	new Float:distance;
	new Float:maxdistance = 4000.0;
	new enemy = 0;
	for(new i = 1; i <= g_maxplayers; i++)
	{
		if(is_user_alive(i) && is_valid_ent(i) && can_see_fm(npc, i))
		{
			distance = entity_range(npc, i);
			if(distance <= maxdistance)
			{
				maxdistance = distance;
				enemy = i;
			}
		}
	}
	return enemy;
}

public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = entity_get_int(entindex1, EV_INT_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		entity_get_vector(entindex1, EV_VEC_origin, lookerOrig)
		entity_get_vector(entindex1, EV_VEC_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		entity_get_vector(entindex2, EV_VEC_origin, targetBaseOrig)
		entity_get_vector(entindex2, EV_VEC_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		//  checks the had of seen player
		if (IsOriginInWater(lookerOrig, targetOrig, entindex1))
		{
			return false
		} 
		else 
		{
			new hit_ent;
			new Float:flFraction = GetOriginFraction(lookerOrig, targetOrig, entindex1, hit_ent);
			if (flFraction == 1.0 || (hit_ent == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				
				//  checks the body of seen player
				flFraction = GetOriginFraction(lookerOrig, targetOrig, entindex1, hit_ent);
				if (flFraction == 1.0 || (hit_ent == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					
					//  checks the legs of seen player
					flFraction = GetOriginFraction(lookerOrig, targetOrig, entindex1, hit_ent);
					if (flFraction == 1.0 || (hit_ent == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}

bool:IsOriginInWater(const Float:origin1[3], const Float:origin2[3], const skip)
{
	new trace = GetTraceLineHandle(origin1, origin2, skip);
	new bool:result = (get_tr2(trace, TraceResult:TR_InOpen) && get_tr2(trace, TraceResult:TR_InWater));
	free_tr2(trace);
	
	return result;
}

Float:GetOriginFraction(const Float:origin1[3], const Float:origin2[3], const skip, &hit)
{
	new Float:flFraction;
	new trace = GetTraceLineHandle(origin1, origin2, skip);
	get_tr2(trace, TraceResult:TR_flFraction, flFraction);
	hit = get_tr2(trace, TraceResult:TR_pHit)
	free_tr2(trace);
	
	return flFraction;
}

GetTraceLineHandle(const Float:origin1[3], const Float:origin2[3], const skip)
{
	new trace = create_tr2();
	engfunc(EngFunc_TraceLine, origin1, origin2, 0, skip, trace);
	return trace;
}

play_anim(ent, const anim[], Float:framerate = 1.0, bool:immediate = false, Float:startframe = 0.0)
{
	new sequence = lookup_sequence(ent, anim);
	entity_set_float(ent, EV_FL_framerate, framerate);
	
	if(immediate){entity_set_float(ent, EV_FL_frame, startframe);}
	
	
	if(entity_get_int(ent, EV_INT_sequence) != sequence)
	{
		if(!immediate){entity_set_float(ent, EV_FL_frame, startframe);}
		entity_set_float(ent, EV_FL_animtime, get_gametime());
		entity_set_int(ent, EV_INT_sequence, sequence);
	}
}

remove_stop_attack_task(ent)
{
	if(task_exists(ent+TASK_ATTACK_STOP))
		remove_task(ent+TASK_ATTACK_STOP);
}

create_stop_attack_task(ent)
{
	remove_stop_attack_task(ent);
	set_task(1.5, "stop_attack", ent+TASK_ATTACK_STOP);
}

PointArraysInit()
{
	for(new i = 0; i < MAX_POINT; i++)
	{
		g_spawn_points[i][_:Point_X] = 0.0;
		g_spawn_points[i][_:Point_Y] = 0.0;
		g_spawn_points[i][_:Point_Z] = 0.0;
		g_spawn_points[i][_:Point_Jump] = -1;
	}
	g_point_index = 0;
}

GetArrayPointIndex(Float:origin[3], bool:jump = false)
{
	for(new index = 0; index < MAX_POINT; index++)
	{
		new bool:point_jump = g_spawn_points[index][_:Point_Jump] > 0;
		if(point_jump == jump)
		{
			new Float:point_origin[3];
			point_origin[0] = Float:g_spawn_points[index][_:Point_X];
			point_origin[1] = Float:g_spawn_points[index][_:Point_Y];
			point_origin[2] = Float:g_spawn_points[index][_:Point_Z];
			
			if(get_distance_f(origin, point_origin) < 120.0)
				return index;
		}
	}
	return -1;
}

bool:GetArrayPoint(index, Float:origin[3], &bool:jump)
{
	if(0 <= index < MAX_POINT)
	{
		origin[0] = Float:g_spawn_points[index][_:Point_X];
		origin[1] = Float:g_spawn_points[index][_:Point_Y];
		origin[2] = Float:g_spawn_points[index][_:Point_Z];
		jump = g_spawn_points[index][_:Point_Jump] > 0;
		
		return true;
	}
	return false;
}

bool:GetArrayRandomPoint(Float:origin[3], &bool:jump)
{
	new point_count = GetPointCount();
	if(point_count > 0)
		return GetArrayPoint(random_num(0, point_count - 1), origin, jump);
	
	return false;
}

GetPointCount()
{
	new count = 0;
	for(new index = 0; index < MAX_POINT; index++)
	{
		if(g_spawn_points[index][_:Point_Jump] >= 0)
			count++;
	}
	return count;
}

GetRandomVacantPoint(Float:origin[3])
{
	new Float:point[3];
	new Array:points = ArrayCreate(sizeof(point), 1);
	for(new index = 0; index < MAX_POINT; index++)
	{
		if(g_spawn_points[index][_:Point_Jump] >= 0)
		{
			point[0] = g_spawn_points[index][_:Point_X];
			point[1] = g_spawn_points[index][_:Point_Y];
			point[2] = g_spawn_points[index][_:Point_Z];
			
			if(is_hull_vacant(point, HULL_HUMAN))
				ArrayPushArray(points, point);
		}
	}
	
	new count = ArraySize(points);
	if(count > 0)
		ArrayGetArray(points, random_num(0, count - 1), origin, sizeof(origin));
	
	ArrayDestroy(points);
	
	return count;
}

AddPointToArrays(Float:origin[3], bool:jump = false)
{
	new index = GetArrayPointIndex(origin, jump);
	if(index < 0)
	{
		if(g_point_index >= MAX_POINT || g_point_index < 0)
			g_point_index = 0;
		
		index = g_point_index;
		
		g_spawn_points[index][_:Point_X] = origin[0];
		g_spawn_points[index][_:Point_Y] = origin[1];
		g_spawn_points[index][_:Point_Z] = origin[2];
		g_spawn_points[index][_:Point_Jump] = jump?1:0;
		
		g_point_index++;
	}
	return index;
}

bool:IsNpcOnGround(npc)
{
	if(entity_get_int(npc, EV_INT_flags) & FL_ONGROUND)
		return true;
	return false;
}

GetNpcTraceHullEndPos(npc, Float:start[3], Float:end[3], hull = HULL_HUMAN)
{
	new trace = GetTraceHullHandle(start, end, hull, npc);
	get_tr2(trace, TR_vecEndPos, end);
	free_tr2(trace);
}

bool:is_hull_vacant(Float:origin[3], hull = HULL_HUMAN, skip = 0)
{
	new trace = GetTraceHullHandle(origin, origin, hull, skip);
	
	new bool:result = (!get_tr2(trace, TR_StartSolid)
					&& !get_tr2(trace, TR_AllSolid)
					&& get_tr2(trace, TR_InOpen));
	
	free_tr2(trace);
	
	return result;
}

GetTraceHullHandle(Float:start[3], Float:end[3], hull = HULL_HUMAN, skip = 0)
{
	new trace = create_tr2();
	engfunc(EngFunc_TraceHull, start, end, 0, hull, skip, trace);
	return trace;
}

npc_water_move(npc, classid)
{
	new Float:vector[3];
	new anim[STRING_MAX_LENGTH];
	velocity_by_aim(npc, floatround(GetNpcInfosSpeed(classid) * 2.0 / 3.0), vector);
	entity_set_vector(npc, EV_VEC_velocity, vector);
	
	GetArrayRandomAnim(classid, AnimType_Fall, anim, charsmax(anim));
	play_anim(npc, anim);
}

npc_jump(npc, classid, Float:start[3], Float:end[3])
{
	//复制起始与结束点位置置临时数组
	new Float:t_start[3], Float:t_end[3], Float:hull_end[3];
	xs_vec_copy(start, t_start);
	xs_vec_copy(end, t_end);
	xs_vec_copy(start, hull_end);
	
	//增加起始点高度36.0
	t_start[2]+=36.0;
	
	new Float:angles[3], Float:vector[3], Float:bestVec[3];
	
	//获取npc角度向量
	entity_get_vector(npc, EV_VEC_angles, angles);
	
	//计算跳跃角度向量
	new Float:maxspeed = GetNpcInfosSpeed(classid);
	new Float:height = GetNpcInfosJumpHeight(classid);
	angle_vector(angles, 1, bestVec);
	bestVec[0] *= maxspeed;
	bestVec[1] *= maxspeed;
	bestVec[2] = floatsqroot(2.0*height*800.0);
	angles[1]-=135.0;
	
	//计算往左和往右跳哪个能靠近目标
	new Float:maxdist = 0.0;
	for(new i=0;i<5;i++)
	{
		angles[1] += 45.0;
		angle_vector(angles, 1, vector);
		vector[0] *= 32.0;
		vector[1] *= 32.0;
		vector[2] = 0.0;
		xs_vec_add(t_start, vector, hull_end);
		
		GetNpcTraceHullEndPos(npc, t_start, hull_end, HULL_HEAD);
		
		new trace = GetTraceHullHandle(hull_end, t_end, HULL_HEAD, npc);
		get_tr2(trace, TR_vecEndPos, hull_end);
		free_tr2(trace);
		
		new Float:dist = get_distance_f(hull_end, t_end);
		if (dist < maxdist || maxdist == 0.0)
		{
			xs_vec_copy(hull_end, t_start);
			hull_end[2]-=9999.0
			
			GetNpcTraceHullEndPos(npc, t_start, hull_end, HULL_HEAD);
			
			if (get_distance_f(t_start, hull_end)> 16.0){continue;}
			
			maxdist = dist;
			angle_vector(angles, 1, bestVec);
			bestVec[0] *= maxspeed;
			bestVec[1] *= maxspeed;
			bestVec[2] = floatsqroot(2.0*height*800.0);
		}
	}
	entity_set_vector(npc, EV_VEC_velocity, bestVec);
	
	new anim[STRING_MAX_LENGTH];
	GetArrayRandomAnim(classid, AnimType_Jump, anim, charsmax(anim));
	play_anim(npc, anim, 5.0, true);
}

npc_water_jump(npc, classid)
{
	new Float:leaptime = entity_get_float(npc, EV_FL_ltime);
	
	if (leaptime < get_gametime())
	{
		new Float:vector[3];
		velocity_by_aim(npc, floatround(GetNpcInfosSpeed(classid)), vector);
		vector[2] = floatsqroot(2.0*72.0*800.0);		// 72.0是跳跃高度
		entity_set_vector(npc, EV_VEC_velocity, vector);
		entity_set_float(npc, EV_FL_ltime, get_gametime() + 3.0);
		
		new anim[STRING_MAX_LENGTH];
		GetArrayRandomAnim(classid, AnimType_Attack, anim, charsmax(anim));
		play_anim(npc, anim, 3.0, true);
	}
}

npc_superjump(npc)
{
	new Float:angles[3];
	entity_get_vector(npc, EV_VEC_angles, angles);
	
	new Float:vector[3];
	angle_vector(angles, 1, vector);
	
	new Float:origin[3];
	entity_get_vector(npc, EV_VEC_origin, origin);
	origin[2] += 36.0;
	
	new Float:nextOrg[3];
	xs_vec_add(origin, vector, nextOrg);	// 模拟旋转跳
	
	GetNpcTraceHullEndPos(npc, origin, nextOrg, HULL_HUMAN);
	
	nextOrg[2] -= 36.0;
	entity_set_vector(npc, EV_VEC_origin, nextOrg);
}