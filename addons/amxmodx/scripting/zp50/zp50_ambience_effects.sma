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
#include <zp50_ambience_effects>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini";
new const FOG_CHANCE = 2;

#define FOG_VALUE_MAX_LENGTH 16

new g_fwSpawn;
new g_ambience_random = 1;
new g_ambience_rain = 1;
new g_ambience_snow = 1;
new g_ambience_fog = 1;
new g_ambience_fog_density[FOG_VALUE_MAX_LENGTH] = "0.0018";
new g_ambience_fog_color[FOG_VALUE_MAX_LENGTH] = "128 128 128";
new const g_ambience_ents[][] = { "env_fog", "env_rain", "env_snow" };

new g_msg_fog, g_msg_recieve;
new Ambience_Weather:g_weather = Weather_Sunny;

public plugin_init()
{
	register_plugin("[ZP] Ambience Effects", ZP_VERSION_STRING, "ZP Dev Team rewrite by Mostten");
	g_msg_fog = get_user_msgid ("Fog");
	g_msg_recieve = get_user_msgid("ReceiveW");
	register_message(g_msg_recieve, "MsgReceived");
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
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

public plugin_natives()
{
	register_library("zp50_ambience_effects");
	register_native("zp_ambience_get_weather", "native_ambience_get_weather");
}

public native_ambience_get_weather(plugin_id, num_params)
{
	return _:g_weather;
}

ambience_create()
{
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"));
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"));
}

fog_create(const client = 0, const color_string[FOG_VALUE_MAX_LENGTH], const Float:density_f = 0.001, bool:clear = false)
{
	new color[3];
	str_tocolor(color_string, color);
	if (g_msg_fog)
	{
		new density = _:floatclamp(density_f, 0.0001, 0.25) * _:!clear;
		message_begin(client ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_msg_fog, .player = client);
		write_byte(clamp(color[0], 0, 255));
		write_byte(clamp(color[1], 0, 255));
		write_byte(clamp(color[2], 0, 255));
		write_long(_:density);
		message_end();
	}
}

str_tocolor(const color_string[FOG_VALUE_MAX_LENGTH], color_array[3])
{
	new color_temp[FOG_VALUE_MAX_LENGTH];
	format(color_temp, FOG_VALUE_MAX_LENGTH, color_string);
	
	new index = 0;
	new num[FOG_VALUE_MAX_LENGTH];
	for(new i = 0; i < FOG_VALUE_MAX_LENGTH; i++)
	{
		if(color_temp[i] == ' ' || color_temp[i] == ',' || !isalnum(color_temp[i]))
		{
			if(strlen(num) > 0 && is_str_num(num))
				color_array[index] = str_to_num(num);
			format(num, FOG_VALUE_MAX_LENGTH, "");
			index++;
			if(index >= sizeof(color_array))
				return;
			continue;
		}
		format(num, FOG_VALUE_MAX_LENGTH, "%s%c", num, color_temp[i]);
	}
}

Ambience_Weather:get_ambience_random()
{
	switch(random_num(_:Weather_Sunny, _:Weather_Snow))
	{
		case Weather_Rain:
		{
			if(g_ambience_rain > 0)
				return  Weather_Rain;
			else if(g_ambience_snow > 0)
				return Weather_Snow;
		}
		case Weather_Snow:
		{
			if(g_ambience_snow > 0)
				return  Weather_Snow;
			else if(g_ambience_rain > 0)
				return  Weather_Rain;
		}
	}
	return Weather_Sunny;
}

bool:has_fog()
{
	return (g_ambience_fog > 0 && random_num(1, FOG_CHANCE) == 1);
}

Ambience_Weather:get_ambience_config()
{
	if (g_ambience_random > 0)
	{
		return get_ambience_random();
	}
	else
	{
		if(get_ambience_config_count() > 1)
			return get_ambience_random();
		else if (g_ambience_rain > 0)
			return  Weather_Rain;
		else if (g_ambience_snow > 0)
			return Weather_Snow;
	}
	return Weather_Sunny;
}

get_ambience_config_count()
{
	new count = 0;
	if(g_ambience_rain > 0)
		count++;
	if(g_ambience_snow > 0)
		count++;
	return count;
}

// Event Round Start
public event_round_start()
{
	if(has_fog())
		fog_create(0, g_ambience_fog_color, str_to_float(g_ambience_fog_density), false);
}

public Event_RoundEnd()
{
	fog_create(0, g_ambience_fog_color, str_to_float(g_ambience_fog_density), true);
	switch(get_ambience_config())
	{
		case Weather_Rain:
		{
			g_weather = Weather_Rain;
		}
		case Weather_Snow:
		{
			g_weather = Weather_Snow;
		}
		default:{g_weather = Weather_Sunny;}
	}
}

public MsgReceived(msg_id, msg_dest, msg_entity)
{
	set_msg_arg_int(1, ARG_BYTE, _:g_weather);
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

// Set an entity's key value (from fakemeta_util)
fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}