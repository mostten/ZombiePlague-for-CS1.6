/*================================================================================
	
	-----------------------------
	-*- [ZP] Ambience Effects -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_core_const>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";

#define FOG_VALUE_MAX_LENGTH 16

new g_fwSpawn;
new g_ambience_random = 1;
new g_ambience_rain = 1;
new g_ambience_snow = 1;
new g_ambience_fog = 1;
new g_ambience_fog_density[FOG_VALUE_MAX_LENGTH] = "0.0018";
new g_ambience_fog_color[FOG_VALUE_MAX_LENGTH] = "128 128 128";
new const g_ambience_ents[][] = { "env_fog", "env_rain", "env_snow" };


#define MAXPLAYERS 32
#define CLASS_HUD_ENTITY "hud_entity"

enum _:Ambience_Effects{
	Ambience_Sunny = 0,
	Ambience_Rain,
	Ambience_Snow,
	Ambience_RainAndSnow
};

new g_hud;
new g_weather = Ambience_Sunny;
new g_msg_recieve;
new bool:g_is_hud_removed;

public plugin_init()
{
	register_plugin("[ZP] Ambience Effects", ZP_VERSION_STRING, "ZP Dev Team rewrite by Mostten");
	g_msg_recieve = get_user_msgid("ReceiveW");
	register_message(g_msg_recieve, "MsgReceived");
	register_logevent("Event_RoundEnd", 2, "1&Restart_Round");
	register_logevent("Event_RoundEnd", 2, "1=Game_Commencing");
	register_logevent("Event_RoundEnd", 2, "1=Round_End");
	unregister_forward(FM_Spawn, g_fwSpawn);
}

public plugin_precache()
{
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG DENSITY", g_ambience_fog_density, charsmax(g_ambience_fog_density)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG DENSITY", g_ambience_fog_density)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG COLOR", g_ambience_fog_color, charsmax(g_ambience_fog_color)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weather Effects", "FOG COLOR", g_ambience_fog_color)
	
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "FOG", g_ambience_fog))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "FOG", g_ambience_fog)
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "SNOW", g_ambience_snow))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "SNOW", g_ambience_snow)
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RAIN", g_ambience_rain))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RAIN", g_ambience_rain)
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RANDOM", g_ambience_random))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "RANDOM", g_ambience_random)
	
	if (g_ambience_fog)
	{
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", g_ambience_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", g_ambience_fog_color, "env_fog")
		}
	}
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	
	ambience_create();
}

ambience_create()
{
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"));
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"));
	register_forward(FM_Think, "Fwd_Think", 1);
}

get_ambience_random()
{
	switch(random_num(Ambience_Sunny, Ambience_Effects - 1))
	{
		case Ambience_Rain:
		{
			if(g_ambience_rain > 0)
				return  Ambience_Rain;
			else if(g_ambience_snow > 0)
				return Ambience_Snow;
		}
		case Ambience_Snow:
		{
			if(g_ambience_snow > 0)
				return  Ambience_Snow;
			else if(g_ambience_rain > 0)
				return Ambience_Rain;
		}
		case Ambience_RainAndSnow:
		{
			if(g_ambience_rain > 0 && g_ambience_snow > 0)
				return Ambience_RainAndSnow;
		}
	}
	return Ambience_Sunny;
}

hud_entity_remove(){
	if (pev_valid(g_hud))
	{
		new classname[32];
		pev(g_hud, pev_classname, classname, charsmax(classname));
		if (equal(classname, CLASS_HUD_ENTITY))
			engfunc(EngFunc_RemoveEntity, g_hud);
		g_is_hud_removed = true;
	}
}

hud_entity_create()
{
	new info_target = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	if(info_target)
	{
		dllfunc(DLLFunc_Think, info_target);
		set_pev(g_hud, pev_classname, CLASS_HUD_ENTITY);
		dllfunc(DLLFunc_Spawn, info_target);
		set_pev(info_target, pev_nextthink, get_gametime() + 0.1);
	}
	return info_target;
}

get_ambience_config()
{
	if (g_ambience_random > 0)
	{
		return get_ambience_random();
	}
	else
	{
		if(g_ambience_rain > 0 && g_ambience_snow > 0)
		{
			return Ambience_RainAndSnow;
		}
		else if (g_ambience_rain > 0)
		{
			return  Ambience_Rain;
		}
		else if (g_ambience_snow > 0)
		{
			return Ambience_Snow;
		}
	}
	return Ambience_Sunny;
}

public Event_RoundEnd()
{
	switch(get_ambience_config())
	{
		case Ambience_Rain:
		{
			hud_entity_remove();
			g_weather = Ambience_Rain;
		}
		case Ambience_Snow:
		{
			hud_entity_remove();
			g_weather = Ambience_Snow;
		}
		case Ambience_RainAndSnow:
		{
			g_weather = Ambience_Snow;
			if(g_is_hud_removed)
			{
				g_hud = hud_entity_create();
				g_is_hud_removed = false;
			}
		}
		default:{g_weather = Ambience_Sunny;}
	}
}

public MsgReceived(msg_id, msg_dest, msg_entity)
{
	if(get_ambience_config() != Ambience_RainAndSnow)
		set_msg_arg_int(1, ARG_BYTE, g_weather);
}

// Entity Spawn Forward
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	// Get classname
	new classname[32]
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	new index
	for (index = 0; index < sizeof g_ambience_ents; index++)
	{
		if (equal(classname, g_ambience_ents[index]))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public Fwd_Think(entity)
{
	if (!pev_valid(entity))
		return FMRES_IGNORED;
	
	new classname[32];
	pev(entity, pev_classname, classname, sizeof(classname));
	
	if(equal(classname, CLASS_HUD_ENTITY))
		Fwd_Weather_Think(entity);
	
	return FMRES_HANDLED;
}

Fwd_Weather_Think(entity)
{
	if (entity != g_hud)
		return;
	
	switch(g_weather)
	{
		case Ambience_Sunny:{g_weather = Ambience_Rain;}
		case Ambience_Rain:{g_weather = Ambience_Snow;}
		case Ambience_Snow:{g_weather = Ambience_Rain;}
		default:{g_weather = Ambience_Rain;}
	}
	for(new client = 1; client <= MAXPLAYERS; client++) 
	{
		if(is_user_connected(client))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_msg_recieve, {0,0,0}, client);
			write_byte(g_weather);
			message_end();
		}
	}
	set_pev(g_hud, pev_nextthink, get_gametime() + 0.1);
}

// Set an entity's key value (from fakemeta_util)
fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}