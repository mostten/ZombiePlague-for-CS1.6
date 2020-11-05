#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <zp50_class_npc>

new const npc_name[] = "alien";
new const npc_classname[] = "zp_npc_alien";
new const npc_model[] = "models/zombie_plague/zp_predator/npc_alien.mdl";

new const npc_sound_hurt[] = "zombie_plague/predator/alien_pain_01.wav";
new const npc_sound_attack[] = "zombie_plague/zaphie/claw/zombie_hit1.wav";
new const npc_sound_die[] = "zombie_plague/predator/alien_die_01.wav";

new const Float:npc_size_maxs[3] = {16.0, 16.0, 36.0};
new const Float:npc_size_mins[3] = {-16.0, -16.0, 2.0};

new const Float:npc_speed = 250.0;
new const Float:npc_health = 100.0;
new const Float:npc_damage = 90.0;
new const Float:npc_gravity = 1.0;
new const Float:npc_jump_height = 90.0;

new const npc_anim_idle[] = "idle";
new const npc_anim_run[] = "run";
new const npc_anim_attack[] = "attack";
new const npc_anim_die[] = "death";
new const npc_anim_jump[] = "run";
new const npc_anim_fall[] = "run";

new npc_classid = -1;

public plugin_init()
{
	register_plugin("[ZP] Class: Npc: Alien", "1.0", "Mostten");
}

public plugin_precache()
{
	npc_classid = zp_class_npc_register(npc_name,
										npc_classname,
										npc_model,
										npc_size_mins,
										npc_size_maxs,
										npc_speed,
										npc_health,
										npc_damage,
										npc_gravity,
										npc_jump_height);
	
	zp_class_npc_sound_register(npc_classid,
								npc_sound_hurt,
								npc_sound_attack,
								npc_sound_die);
	
	zp_class_npc_anim_register(npc_classid,
								npc_anim_idle,
								npc_anim_run,
								npc_anim_attack,
								npc_anim_die,
								npc_anim_jump,
								npc_anim_fall);
}

public plugin_natives()
{
	register_library("zp50_class_npc_alien");
	
	register_native("zp_npc_alien_get", "native_npc_alien_get");
	register_native("zp_npc_alien_get_count", "native_npc_alien_get_count");
	register_native("zp_npc_alien_spawn", "native_npc_alien_spawn");
}

bool:is_valid_alien(const entity)
{
	return (is_valid_ent(entity) && is_valid_classid(zp_class_npc_get_classid(entity)));
}

bool:is_valid_classid(const classid)
{
	return (npc_classid >= 0 && classid == npc_classid);
}

public native_npc_alien_get(plugin_id, num_params)
{
	new entity = get_param(1)
	
	return is_valid_alien(entity);
}

public native_npc_alien_get_count(plugin_id, num_params)
{
	if(npc_classid >= 0)
		return zp_class_npc_get_count(npc_classid);
	
	return 0;
}

public native_npc_alien_spawn(plugin_id, num_params)
{
	return zp_class_npc_spawn(npc_classid);
}