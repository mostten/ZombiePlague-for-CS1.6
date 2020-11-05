/*================================================================================
	
	--------------------------
	-*- [ZP] Zombie Damage -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_HUMAN "zp50_class_human"
#include <zp50_class_human>

new cvar_zombie_defense, cvar_zombie_hitzones

public plugin_init()
{
	register_plugin("[ZP] Zombie Damage", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_zombie_defense = register_cvar("zp_zombie_defense", "0.75")
	cvar_zombie_hitzones = register_cvar("zp_zombie_hitzones", "0")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
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

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Zombie custom hitzones disabled
	if (!get_pcvar_num(cvar_zombie_hitzones))
		return HAM_IGNORED;
	
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Not bullet damage or victim isn't a zombie
	if (!(damage_type & DMG_BULLET) || !zp_core_is_zombie(victim))
		return HAM_IGNORED;
	
	// Check whether we hit an allowed one
	if (!(get_pcvar_num(cvar_zombie_hitzones) & (1<<get_tr2(tracehandle, TR_iHitgroup))))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Human attacking zombie...
	if (!zp_core_is_zombie(attacker) && zp_core_is_zombie(victim))
	{
		// Reset damage
		new Float:damage_old = damage;
		reset_user_damage(attacker, damage);
		
		// Armor multiplier for the final damage
		damage *= get_pcvar_float(cvar_zombie_defense);
		
		if(damage != damage_old)
		{
			SetHamParamFloat(4, damage);
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

bool:reset_user_damage(client, &Float:damage)
{
	new Float:damage_new = get_user_damage_math(client, damage);
	if(damage_new != damage && damage_new > 0.0)
	{
		damage = damage_new;
		return true;
	}
	return false;
}

Float:get_user_damage_math(client, const Float:damage)
{
	new Float:damage_new = damage;
	new Float:damage_multiplier = get_user_damage_multiplier(client);
	damage_new *= damage_multiplier;
	return damage_new;
}

Float:get_user_damage_multiplier(client)
{
	new Float:damage_multiplier = 1.0;
	new classid = zp_class_human_get_current(client);
	if(classid != ZP_INVALID_HUMAN_CLASS)
		damage_multiplier = zp_class_human_get_dm(classid);
	if(damage_multiplier < 0.0)
		damage_multiplier = 1.0;
	return damage_multiplier;
}
