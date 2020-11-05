#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <cs_ham_bots_api>
#include <cs_weap_restrict_api>
#include <zp50_colorchat>
#include <zp50_zombie_sounds>
#include <zp50_radio>
#include <zp50_class_zombie>

#define MAXPLAYERS 32
#define COLOR_GREEN		192
#define TASK_NVG 100
#define ID_NVG (taskid - TASK_NVG)

enum NvgType{
	NvgType_None = 0,
	NvgType_Heat,
	NvgType_Grey
};

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_PREDATOR_INIT_PRE = 0,
	FW_PREDATOR_INIT_POST
};

new const FFADE_IN = 0x0000;

// Predator Attributes
new const predator_name[] = "Predator";
new const predator_info[] = "=Predator=";
new const predator_health = 200;
new const predator_armor = 200;
new const predator_maxvisib = 200;
new const Float:predator_speed = 350.0;
new const Float:predator_gravity = 0.5;
new const Float:predator_knockback = 1.0;
new const bool:predator_infection = false;
new const Float:interval_primary_attack = 0.5;
new const Float:interval_secondary_attack = 0.8;
new const Float:damage_primary_attack = 15.0;
new const Float:damage_secondary_attack = 25.0;
new const predator_pound_range = 150;
new const Float:predator_pound_delay = 4.0;
new const bool:predator_blood = false;

new predator_classid = ZP_INVALID_ZOMBIE_CLASS;
new bool:is_predator_hide[MAXPLAYERS+1];
new predator_visib[MAXPLAYERS+1];
new bool:predator_speedlock[MAXPLAYERS+1];
new Float:predator_wall_origin[MAXPLAYERS+1][3];
new Float:predator_pound_next[MAXPLAYERS+1];
new bool:predator_pound_enabled[MAXPLAYERS+1];
new NvgType:predator_nvg[MAXPLAYERS+1];

new g_ForwardResult;
new g_Forwards[TOTAL_FORWARDS];

new spr_shockwave;

new const model_predator[][] =
{
	"zp_predator"
};

new const model_claws[] = "models/zombie_plague/zp_predator/v_claws_predator.mdl";

new const sound_crpredator[] = "zombie_plague/predator/crpredator.wav";
new const sound_depredator[] = "zombie_plague/predator/depredator.wav";
new const sound_vision_change_1[] = "zombie_plague/predator/vision_change_01.wav";
new const sound_vision_change_2[] = "zombie_plague/predator/vision_change_02.wav";
new const sound_vision_end[] = "zombie_plague/predator/vision_mode_end.wav";
new const sound_slamsnd[] =	"zombie_plague/predator/dirtpound.wav";

new const predator_die_sound[][] =
{
	"agrunt/ag_die2.wav",
	"agrunt/ag_die3.wav",
	"agrunt/ag_die5.wav",
	"zombie_plague/predator/dieing.wav"
};

new const predator_pain_sound[][] =
{
	"aslave/slv_pain1.wav",
	"aslave/slv_pain2.wav",
	"bullchicken/bc_idle5.wav",
	"controller/con_pain1.wav",
	"controller/con_pain2.wav",
	"controller/con_pain3.wav"
};

new const predator_radio_sound[][] =
{
	"zombie_plague/predator/Predyell.wav",
	"zombie_plague/predator/predclick.wav",
	"zombie_plague/predator/predgrowl.wav",
	"zombie_plague/predator/predyell2.wav"
};

new const predator_radio_message[][] =
{
	"Scream",
	"Click",
	"Growl",
	"Yell"
};

public plugin_init()
{
	// 注册翻译文件
	//register_dictionary("zombie_plague_zombie_predator.txt");
	
	g_Forwards[FW_PREDATOR_INIT_PRE] = CreateMultiForward("zp_fw_predator_init_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_PREDATOR_INIT_POST] = CreateMultiForward("zp_fw_predator_init_post", ET_IGNORE, FP_CELL, FP_CELL);
	
	register_clcmd("nightvision", "clcmd_nightvision");
	register_clcmd("drop", "clcmd_drop");
	
	register_forward(FM_Touch, "fw_touch");
	register_forward(FM_CmdStart, "fw_cmdstart");
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1);
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre", 0);
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Pre", 0);
	
	set_task(0.85, "lowhp_blood", 0, "", 0, "b");
}

public plugin_precache()
{
	// 注册插件
	register_plugin("[ZP] Class: Predator", ZP_VERSION_STRING, "Mostten");
	
	// 注册铁血
	reg_zombie_predator();
	
	// 缓存声音文件
	precache_sound(sound_crpredator);
	precache_sound(sound_depredator);
	precache_sound(sound_vision_change_1);
	precache_sound(sound_vision_change_2);
	precache_sound(sound_vision_end);
	precache_sound(sound_slamsnd);
	
	// 缓存spr文件
	spr_shockwave = precache_model("sprites/shockwave.spr");
}

public plugin_natives()
{
	register_library("zp50_class_predator");
	register_native("zp_class_predator_get", "native_class_predator_get");
	register_native("zp_class_predator_set", "native_class_predator_set");
	register_native("zp_class_predator_get_count", "native_class_predator_get_count");
}

public native_class_predator_get(plugin_id, num_params)
{
	new client = get_param(1)
	
	if (!is_user_connected(client))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", client)
		return -1;
	}
	
	return is_user_predator(client);
}

public native_class_predator_set(plugin_id, num_params)
{
	new client = get_param(1);
	
	if(!is_user_alive(client))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", client);
		return false;
	}
	
	if(is_user_predator(client))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a predator (%d)", client);
		return false;
	}
	
	return zp_class_zombie_set_current(client, predator_classid);
}

public native_class_predator_get_count(plugin_id, num_params)
{
	new players[MAXPLAYERS], num, count = 0;
	get_players(players, num, "a");
	for(new i = 0; i < num; i++)
	{
		if(is_user_predator(players[i]))
			count++;
	}
	return count;
}

public client_disconnected(client, bool:drop, message[], maxlen)
{
	predator_clear(client);
}

reg_zombie_predator()
{
	// 注册铁血战士
	predator_classid = zp_class_zombie_register(predator_name,
												predator_info,
												predator_health,
												predator_speed,
												predator_gravity,
												predator_infection,
												interval_primary_attack,
												interval_secondary_attack,
												damage_primary_attack,
												damage_secondary_attack,
												predator_blood,
												predator_health);
	
	// 注册击退
	zp_class_zombie_register_kb(predator_classid, predator_knockback);
	
	// 注册铁血爪子模型
	new index = 0;
	zp_class_zombie_register_claw(predator_classid, model_claws);
	
	// 注册铁血身体模型
	for(index = 0; index < sizeof(model_predator); index++)
		zp_class_zombie_register_model(predator_classid, model_predator[index]);
	
	// 注册无线电音频
	for(index = 0; index < sizeof(predator_radio_sound); index++)
	{
		zp_radio_reg_zombie(predator_radio_message[index], false, predator_radio_message[index], false, predator_radio_sound[index], RadioMenu_1, predator_classid);
		zp_radio_reg_zombie(predator_radio_message[index], false, predator_radio_message[index], false, predator_radio_sound[index], RadioMenu_2, predator_classid);
		zp_radio_reg_zombie(predator_radio_message[index], false, predator_radio_message[index], false, predator_radio_sound[index], RadioMenu_3, predator_classid);
	}
	
	// 注册铁血受伤音效
	for(index = 0; index < sizeof(predator_pain_sound); index++)
		zp_zombie_register_sound(predator_classid, predator_pain_sound[index]);
	
	// 注册铁血死亡音效
	for(index = 0; index < sizeof(predator_die_sound); index++)
		zp_zombie_register_sound(predator_classid, _, predator_die_sound[index]);
}

public zp_fw_core_cure(client, attacker)
{
	if(is_user_valid(client))
	{
		if(is_user_predator(client))
			PlaySoundToClient(client, sound_depredator);
		predator_clear(client);
	}
}

public zp_fw_class_zombie_init_pre(client, classid)
{
	if(is_classid_predator(classid))
	{
		ExecuteForward(g_Forwards[FW_PREDATOR_INIT_PRE], g_ForwardResult, client, classid);
		
		return g_ForwardResult;
	}
	
	return PLUGIN_CONTINUE;
}

public zp_fw_class_zombie_init_post(client, classid)
{
	// Apply predator attributes?
	if(is_classid_predator(classid))
	{
		predator_init(client);
		
		ExecuteForward(g_Forwards[FW_PREDATOR_INIT_POST], g_ForwardResult, client, classid);
	}
}

public zp_fw_class_zombie_select_pre(client, classid)
{
	if(is_classid_predator(classid))
		return ZP_CLASS_DONT_SHOW;//ZP_CLASS_DONT_SHOW;
	return ZP_CLASS_AVAILABLE;
}

bool:is_classid_predator(classid)
{
	return (predator_classid != ZP_INVALID_ZOMBIE_CLASS && classid == predator_classid);
}

predator_init(client)
{
	cs_set_user_armor(client, predator_armor, CS_ARMOR_VESTHELM);
	predator_visib[client] = 0;
	is_predator_hide[client] = true;
	predator_speedlock[client] = false;
	predator_pound_enabled[client] = false;
	predator_pound_next[client] = 0.0;
	
	cs_set_player_weap_restrict(client, false);
	
	PlaySoundToClient(client, sound_crpredator);
}

predator_clear(client)
{
	predator_visib[client] = predator_maxvisib;
	is_predator_hide[client] = false;
	predator_speedlock[client] = true;
	predator_pound_enabled[client] = false;
	predator_pound_next[client] = 0.0;
	
	remove_task(client+TASK_NVG);
}

public lowhp_blood()
{
	new client, players[MAXPLAYERS], num, origin[3];
	get_players(players, num, "a");
	for(new i = 0; i < num; i++)
	{
		client = players[i];
		if(is_user_predator(client)
		&& get_user_health(client) <= get_user_maxhealth(client)/2)
		{
			get_user_origin(client, origin);
			fx_bleed_green(origin, 1);
			fx_blood_small_green(origin, 5);
		}
	}
}

public fw_AddToFullPack_Post(es_handle, e, ent, host, hostflags, player, pSet) 
{
	if(!pev_valid(ent))
		return FMRES_IGNORED;
	if(is_user_valid(host) && is_user_predator(host))
		predator_view_render(host, ent, es_handle);
	else if(is_user_valid(ent) && is_user_predator(ent))
	{
		if(!is_user_alive(host)){predator_es_render(es_handle, true);}
		else
		{
			if(!is_predator_hide[ent])
				predator_es_render(es_handle, false);
			else
				predator_es_hide(ent, host, es_handle);
		}
	}
	return FMRES_IGNORED
}

public fw_touch(client, touch_entity)
{
	if(!is_user_valid(client) || !is_user_alive(client) || !is_user_predator(client))
		return FMRES_IGNORED;
	
	new classname[32];
	if(pev_valid(touch_entity))
	{
		pev(touch_entity, pev_classname, classname, charsmax(classname));
		if(equal(classname, "weaponbox")
		|| equal(classname, "armoury_entity")
		|| equal(classname, "weapon_shield")){return FMRES_SUPERCEDE;}
	}
	
	if(touch_entity == 0 || equal(classname, "func_wall"))
		pev(client, pev_origin, predator_wall_origin[client]);
	
	return FMRES_IGNORED;
}

public clcmd_drop(client)
{
	if(is_user_alive(client) && is_user_predator(client))
	{
		predator_skill_pound(client);
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public clcmd_nightvision(client)
{
	if(is_user_alive(client) && is_user_predator(client))
	{
		switch_predator_nvg(client);
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public fw_cmdstart(client, const uc_handle, random_seed)
{
	if(!is_user_valid(client) || !is_user_alive(client) || !is_user_predator(client))
		return FMRES_IGNORED;
	
	new buttons = get_uc(uc_handle, UC_Buttons);
	new holdflags = pev(client, pev_flags);
	
	if(buttons & IN_USE)
		predator_skill_cling(client, buttons);
	
	if(holdflags & FL_ONGROUND)
	{
		if(predator_pound_enabled[client])
		{
			predator_pound_enabled[client] = false;
			ground_skill_pound(client);
		}
	}
	return FMRES_IGNORED;
}

// Ham Take Damage Forward
public fw_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(predator_pound_enabled[victim]
	&& damage_type & DMG_FALL
	&& damage > 0.0
	&& is_user_predator(victim))
	{
		// Block fall damage of dirtpound
		SetHamParamFloat(4, 0.0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA)
{
	if(!is_user_valid(victim)
		|| !is_user_alive(victim)
		|| !is_user_predator(victim)
		|| !is_user_valid(attacker)
		|| zp_core_is_zombie(attacker)
		|| damage < 1){return;}
	
	// 当铁血缓慢移动时恢复其移动速度
	if(predator_speedlock[victim])
	{
		predator_speedlock[victim] = false;
		set_pev(victim, pev_maxspeed, predator_speed);
	}
	
	// 解除恢复pound技能冷却限制
	predator_pound_next[victim] = 0.0;
	
	// 增加铁血显示度和screen fade效果
	new alpha = floatround(damage*1.25);
	if(alpha > 255){alpha = 255;}
	new duration = alpha*100;
	zp_core_set_screenfade(victim, duration, 0, FFADE_IN, 0, 0, 200, alpha, true);
	add_predator_visib(victim, damage * 2);
}

bool:is_user_predator(client)
{
	if(zp_core_is_zombie(client))
		return (predator_classid != ZP_INVALID_ZOMBIE_CLASS && predator_classid == zp_class_zombie_get_current(client));

	return false;
}

get_user_maxhealth(client)
{
	if(zp_core_is_zombie(client))
	{
		new classid = zp_class_zombie_get_current(client);
		if(classid != ZP_INVALID_ZOMBIE_CLASS)
			return zp_class_zombie_get_max_health(client);
	}
	return get_user_health(client);
}

predator_skill_cling(client, button)
{
	static Float:origin[3];
	pev(client, pev_origin, origin);
	
	if(get_distance_f(origin, predator_wall_origin[client]) > 25.0)
		return;  // if not near wall
	
	if(pev(client, pev_flags) & FL_ONGROUND)
		return;
	
	if(button & IN_FORWARD)
	{
		static Float:velocity[3];
		velocity_by_aim(client, 120, velocity);
		set_pev(client, pev_velocity, velocity);
	}
	else if(button & IN_BACK)
	{
		static Float:velocity[3];
		velocity_by_aim(client, -120, velocity);
		set_pev(client, pev_velocity, velocity);
	}
}

predator_skill_pound(client)
{
	if(pev(client, pev_flags) & FL_ONGROUND){return;}
	
	new Float:now = get_gametime();
	if(now < predator_pound_next[client]){return;}
	
	new Float:velocity[3];
	pev(client, pev_velocity, velocity);
	velocity[0] = velocity[1] = 0.0;
	velocity[2] *= (velocity[2] > 0.0)?-5.0:5.0;
	set_pev(client, pev_velocity, velocity);
	
	predator_pound_next[client] = now + predator_pound_delay;
	predator_pound_enabled[client] = true;
}

ground_skill_pound(client)
{
	new origin_predator[3];
	get_user_origin(client, origin_predator);
	message_dirtpound(origin_predator);
	zp_core_set_screenfade(client, 15000, 0, FFADE_IN, 200, 0, 0, 150, true);
	emit_sound(client, CHAN_AUTO, sound_slamsnd, 1.0, ATTN_NORM, 0, PITCH_NORM);
	predator_speed_adjust(client, 200.0, predator_pound_delay, 10);
	
	new target, players[MAXPLAYERS], num, origin_target[3], distance_target;
	get_players(players, num, "a");
	for(new i = 0; i < num; i++)
	{
		target = players[i];
		if(zp_core_is_zombie(target)){continue;}
		get_user_origin(target, origin_target);
		distance_target = get_distance(origin_predator, origin_target);
		if(distance_target <= predator_pound_range)
		{
			distance_target = predator_pound_range - distance_target;
			TakeDamage(target, get_user_weapon(client), client, float(distance_target/3), DMG_CLUB);
			make_user_punch(target, distance_target*3);
		}
	}
}

predator_speed_adjust(client, Float:newspeed, Float:delay, increase)
{
	predator_speedlock[client] = true;
	set_pev(client, pev_maxspeed, newspeed);
	new data_pack[2];
	data_pack[0] = client;
	data_pack[1] = increase;
	set_task(delay, "task_speedupagain", _, data_pack, 2);
}

public task_speedupagain(data_pack[2])
{
	//Speed Increase Effect (After Using Groundpound)
	new client = data_pack[0];
	new increase = data_pack[1];
	if(!is_user_valid(client)
		|| !is_user_alive(client)
		|| !is_user_predator(client)
		|| !predator_speedlock[client])
		return;
	
	new Float:speed_current;
	pev(client, pev_maxspeed, speed_current)
	if(speed_current < predator_speed - increase)
	{
		set_pev(client, pev_maxspeed, speed_current + increase);
		set_task(0.1, "task_speedupagain", _, data_pack, 2);
	}
	else if(speed_current > predator_speed + increase)
	{
		set_pev(client, pev_maxspeed, speed_current - increase);
		set_task(0.1, "task_speedupagain", _, data_pack, 2);
	}
	else
	{
		set_pev(client, pev_maxspeed, predator_speed);
		predator_speedlock[client] = false;
	}
}

make_user_punch(client, range)
{
	new Float:angles[3], direction;
	pev(client, pev_punchangle, angles);
	//Pitch	-	Directly related to range.
	angles[0] += (range / 4.0);
	//Yaw	-	May be minimal regardless of range.
	angles[1] += (random_float(-(range / 4.0), (range / 4.0)));
	//Roll	-	Directly related to range.
	direction = random_num(0, 1);
	if(direction == 0){angles[2] += (range / 4.0);}
	else{angles[2] -= (range / 4.0);}
	set_pev(client, pev_punchangle, angles);
}

fx_bleed_green(const origin[3], const count)
{
	new vector[3], z_offset = 10;
	new speed = random_num(50,100);
	vector[0] = random_num(-100,100);
	vector[1] = random_num(-100,100);
	vector[2] = random_num(-10,10);
	message_blood_stream(origin, vector, z_offset, COLOR_GREEN, speed, count);
}

fx_blood_small_green(const origin[3], const count)
{
	new blood_small[6] = {3,4,5,6,7,8};
	new xy_offset = random_num(-65,65);
	message_blood_decals(origin, xy_offset, blood_small[random_num(0,5)], count);
}

message_blood_stream(const origin[3], const vector[3], const z_offset, const color_index, const speed, const count)
{
	for(new i = 0; i < count; i++)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BLOODSTREAM);
		write_coord(origin[0]);
		write_coord(origin[1]);
		write_coord(origin[2] + z_offset);
		write_coord(vector[0]);
		write_coord(vector[1]);
		write_coord(vector[2]);
		write_byte(color_index);
		write_byte(speed);//speed
		message_end();
	}
}

message_blood_decals(const origin[3], const xy_offset, const texture_index, const count)
{
	for(new i = 0; i < count; i++)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_WORLDDECAL)
		write_coord(origin[0]+xy_offset);//decal position (center of texture in world)
		write_coord(origin[1]+xy_offset);
		write_coord(origin[2]-36);
		write_byte(texture_index);//texture index of precached decal texture name
		message_end();
	}
}

message_dirtpound(origin[3])
{
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2] + 500);
	write_short(spr_shockwave);
	write_byte(0); 	// startframe
	write_byte(0); 	// framerate
	write_byte(4); 	// life
	write_byte(20); 	// width
	write_byte(100); // noise
	write_byte(255); // R
	write_byte(100); // G
	write_byte(0); 	// B
	write_byte(128); // brightness
	write_byte(5); 	// speed
	message_end();
}

predator_view_render(predator, view_ent, es_handle)
{
	new classname[32];
	pev(view_ent, pev_classname, classname, charsmax(classname));
	switch(predator_nvg[predator])
	{
		case NvgType_Heat:
		{
			if(equal(classname, "func_wall")
				|| equal(classname, "func_door")
				|| equal(classname, "func_button")
				|| equal(classname, "func_rot_button")
				|| equal(classname, "func_door_rotating")
				|| equal(classname, "func_momentary_door")
				|| equal(classname, "func_momentary_button")
				|| equal(classname, "func_wall_toggle")){cold_es_render(es_handle);}
			else if(equal(classname, "func_breakable")
				|| equal(classname, "func_pushable")){medium_es_render(es_handle);}
			else if(equal(classname, "func_vehicle")
				|| equal(classname, "func_plat")
				|| equal(classname, "func_train")
				|| equal(classname, "func_rotating")
				|| equal(classname, "func_tracktrain")
				|| equal(classname, "func_tank")){hot_es_render(es_handle);}
			else if(equal(classname, "env_sprite")
				|| equal(classname, "env_glow")
				|| equal(classname, "cycler_sprite")
				|| equal(classname, "cycler_sprite")){removals_es_render(es_handle);}
			else if(equal(classname, "player")){human_es_render(es_handle);}
			else if(equal(classname, "hostage_entity")){hostage_es_render(es_handle, {100, 0, 0});}
		}
		case NvgType_Grey:
		{
			if(equal(classname, "hostage_entity")){hostage_es_render(es_handle, {50, 50, 50});}
		}
	}
}

cold_es_render(es_handle)
{
	set_es(es_handle, ES_RenderAmt, 100);
	set_es(es_handle, ES_RenderMode, kRenderTransColor);
	set_es(es_handle, ES_RenderColor, {0, 0, 100});
}

medium_es_render(es_handle)
{
	set_es(es_handle, ES_RenderAmt, 100);
	set_es(es_handle, ES_RenderMode, kRenderTransColor);
	set_es(es_handle, ES_RenderColor, {75, 0, 25});
}

hot_es_render(es_handle)
{
	set_es(es_handle, ES_RenderAmt, 100);
	set_es(es_handle, ES_RenderMode, kRenderTransColor);
	set_es(es_handle, ES_RenderColor, {100, 0, 0});
}

removals_es_render(es_handle)
{
	set_es(es_handle, ES_RenderAmt, 0);
	set_es(es_handle, ES_RenderMode, kRenderTransColor);
	set_es(es_handle, ES_RenderFx, kRenderFxNone);
	set_es(es_handle, ES_RenderColor, {0, 0, 0});
}

human_es_render(es_handle)
{
	set_es(es_handle, ES_RenderAmt, 25);
	set_es(es_handle, ES_RenderMode, kRenderNormal);
	set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
	set_es(es_handle, ES_RenderColor, {150, 25, 0});
}

hostage_es_render(es_handle, color[3])
{
	set_es(es_handle, ES_RenderMode, kRenderNormal);
	set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
	set_es(es_handle, ES_RenderAmt, 25);
	set_es(es_handle, ES_RenderColor, color);
}

predator_es_render(es_handle, bool:viewer_dead)
{
	if(viewer_dead)
	{
		set_es(es_handle, ES_RenderAmt, 50);
		set_es(es_handle, ES_RenderMode, kRenderNormal);
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
		set_es(es_handle, ES_RenderColor, {10, 10, 10});
	}
	else
	{
		set_es(es_handle, ES_RenderAmt, 0);
		set_es(es_handle, ES_RenderMode, kRenderNormal);
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
		set_es(es_handle, ES_RenderColor, {0, 0, 0});
	}
}

predator_es_hide(predator, human, es_handle)
{
	new max_alpha = 30;
	new Float:origin_human[3];
	new Float:origin_predator[3];
	new Float:see_pred_dist = 450.0;
	pev(human, pev_origin, origin_human);
	pev(predator, pev_origin, origin_predator);
	new Float:distance = get_distance_f(origin_human, origin_predator);
	if(distance < see_pred_dist)
	{
		new render_this = floatround((see_pred_dist - distance)/10.0);
		if(render_this > max_alpha){render_this = max_alpha;}
		render_this += predator_visib[predator];
		if(render_this > 255){render_this = 255;}
		new color_alpha[3];
		color_alpha[0] = render_this;
		color_alpha[1] = render_this;
		color_alpha[2] = render_this;
		set_es(es_handle, ES_RenderAmt, 1);
		set_es(es_handle, ES_RenderMode, kRenderTransTexture);
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
		set_es(es_handle, ES_RenderColor, color_alpha);
	}
	else if(predator_visib[predator] > 0)
	{
		new color_alpha[3];
		color_alpha[0] = predator_visib[predator];
		color_alpha[1] = predator_visib[predator];
		color_alpha[2] = predator_visib[predator];
		set_es(es_handle, ES_RenderAmt, 1);
		set_es(es_handle, ES_RenderMode, kRenderTransTexture);
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
		set_es(es_handle, ES_RenderColor, color_alpha);
	}
}

add_predator_visib(client, add)
{
	if(predator_visib[client] + add < predator_maxvisib)
		predator_visib[client] += add;
	else
		predator_visib[client] = predator_maxvisib;
}

// Plays a sound on client
PlaySoundToClient(client, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(client, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(client, "spk ^"%s^"", sound);
}

bool:is_user_valid(client)
{
	return (1 <= client <= MAXPLAYERS && is_user_connected(client));
}

switch_predator_nvg(client)
{
	switch(predator_nvg[client])
	{
		case NvgType_Heat:
		{
			predator_nvg[client] = NvgType_Grey;
			PlaySoundToClient(client, sound_vision_change_2);
		}
		case NvgType_Grey:
		{
			predator_nvg[client] = NvgType_None;
			remove_task(client+TASK_NVG);
			PlaySoundToClient(client, sound_vision_end);
			return;
		}
		default:
		{
			predator_nvg[client] = NvgType_Heat;
			PlaySoundToClient(client, sound_vision_change_1);
		}
	}
	set_task(0.1, "predator_nvg_task", client+TASK_NVG, _, _, "b");
}

public predator_nvg_task(taskid)
{
	draw_predator_nvg(ID_NVG);
}

//BLUE LIGHT AROUND THE PREDATOR
draw_predator_nvg(client)
{
	new origin[3];
	get_user_origin(client, origin);
	switch(predator_nvg[client])
	{
		case NvgType_Heat:
		{
			//DRAW GLOW
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, client);
			write_byte(TE_DLIGHT);
			write_coord(origin[0]);
			write_coord(origin[1]);
			write_coord(origin[2]);
			write_byte(40);	//RADIUS
			write_byte(0);	//R
			write_byte(0);	//G
			write_byte(15);	//B
			write_byte(4);	//LIFE
			write_byte(0);	//DECAY
			message_end();
		}
		case NvgType_Grey:
		{
			//DRAW GLOW
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0,0,0}, client);
			write_byte(TE_DLIGHT);
			write_coord(origin[0]);
			write_coord(origin[1]);
			write_coord(origin[2]);
			write_byte(40);	//RADIUS
			write_byte(0);	//R
			write_byte(15);	//G
			write_byte(0);	//B
			write_byte(4);	//LIFE
			write_byte(0);	//DECAY
			message_end();
		}
	}
}

TakeDamage(victim, inflictor, attacker, Float:damage, damagetype)
{
	new Float:health;
	new m_bitsDamageType = 76;
	pev(victim, pev_health, health);

	health -= damage;

	if(health <= 0.0)
	{
		ExecuteHamB(Ham_Killed, victim, attacker, 0);
		return;
	}

	set_pev(victim, pev_health, health);
	set_pev(victim, pev_dmg_take, damage);
	set_pdata_int(victim, m_bitsDamageType, damagetype);
	set_pev(victim, pev_dmg_inflictor, inflictor);
}