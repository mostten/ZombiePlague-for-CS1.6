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
new g_ambience_thunder = 1;
new g_ambience_fog = 1;
new g_ambience_fog_density[FOG_VALUE_MAX_LENGTH] = "0.0018";
new g_ambience_fog_color[FOG_VALUE_MAX_LENGTH] = "128 128 128";
new const g_ambience_ents[][] = { "env_fog", "env_rain", "env_snow" };


#define MAXPLAYERS 32
#define MAX_LIGHT_POINTS 4
#define TASK_AMBIENCE_LIGHT 100
#define ID_AMBIENCE_LIGHT (taskid - TASK_AMBIENCE_LIGHT)
#define CLASS_WEATHER_EFFECTS "weather_effects"
#define CLASS_HUD_ENTITY "hud_entity"
#define ZOMBIE_THUNDER_1 "ambience/thunder_clap.wav"
#define ZOMBIE_THUNDER_2 "de_torn/torn_thndrstrike.wav"

enum _:Ambience_Effects{
	Ambience_Sunny = 0,
	Ambience_Rain,
	Ambience_Snow,
	Ambience_RainAndSnow
};

enum _:Flash_Level{
	Flash_Min = 0,
	Flash_Mid,
	Flash_Max
};

new g_hud;
new g_weather = Ambience_Sunny;
new g_msg_recieve;
new g_flash_count;
new bool:g_is_flashing;
new bool:g_is_hud_removed;
new g_light_beam;
new g_light_style[3][] = { "b", "c", "n" };
new g_light_points[MAX_LIGHT_POINTS];

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
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "THUNDER", g_ambience_thunder))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Weather Effects", "THUNDER", g_ambience_thunder)
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
	precache_flash();
}

ambience_create()
{
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"));
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"));
	ambient_generic_create();
	register_forward(FM_Think, "Fwd_Think", 1);
}

get_ambience_random()
{
	return random_num(Ambience_Sunny, Ambience_Effects - 1);
}

precache_flash()
{
	precache_sound(ZOMBIE_THUNDER_1);
	precache_sound(ZOMBIE_THUNDER_2);
	g_light_beam = precache_model("sprites/laserbeam.spr");
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
	
	if (equal(classname, CLASS_WEATHER_EFFECTS))
	{
		Fwd_Thunder_Think(entity);
	}
	else if(equal(classname, CLASS_HUD_ENTITY))
	{
		Fwd_Weather_Think(entity);
	}
	
	return FMRES_HANDLED;
}

bool:is_thunder_enable()
{
	return (g_ambience_thunder > 0 && g_weather == Ambience_Rain)
}

Fwd_Thunder_Think(entity)
{
	if (!g_is_flashing)
	{
		switch(random_num(0, 1))
		{
			case 0:{set_pev(entity, pev_message, ZOMBIE_THUNDER_1);}
			case 1:{set_pev(entity, pev_message, ZOMBIE_THUNDER_2);}
		}
		if(is_thunder_enable())
			dllfunc(DLLFunc_Use, entity, 0);
		
		static target;
		target = get_random_player();
		if (target && is_thunder_enable())
			CreateLightningPoints(target);
		g_is_flashing = true;
	}
	
	if (Ambience_LightsEffect())
		set_pev(entity, pev_nextthink, get_gametime() + random_float(2.5, 12.5));
	else
		set_pev(entity, pev_nextthink, get_gametime() + 0.1);
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

set_keyvalue(entity, key[], value[])
{
	new classname[32];
	pev(entity, pev_classname, classname, sizeof(classname));
	fm_set_kvd(entity, key, value, classname);
}

ambient_generic_create()
{
	new ambient_generic = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "ambient_generic"));
	
	if (ambient_generic)
	{
		dllfunc(DLLFunc_Think, ambient_generic);
		set_pev(ambient_generic, pev_classname, CLASS_WEATHER_EFFECTS);
		
		set_keyvalue(ambient_generic, "message", ZOMBIE_THUNDER_1);
		set_keyvalue(ambient_generic, "targetname", "wather");
		set_keyvalue(ambient_generic, "pitchstart", "100");
		set_keyvalue(ambient_generic, "pitch", "100");
		set_keyvalue(ambient_generic, "health", "10");
		set_keyvalue(ambient_generic, "spawnflags", "49");
		
		dllfunc(DLLFunc_Spawn, ambient_generic);
		set_pev(ambient_generic, pev_nextthink, get_gametime() + 2.0);
	}
	return -1;
}

Ambience_LightsEffect()
{
	new style;
	switch(random_num(0, Flash_Level))
	{
		case Flash_Min:
		{
			g_flash_count += 1;
			switch(g_flash_count)
			{
				case 1: { style = 1; }
				case 2: { style = 2; }
				case 3: { style = 1; }
				case 4: { style = 0; }
			}
			if(is_thunder_enable())
				engfunc(EngFunc_LightStyle, 0, g_light_style[style]);
			
			if (g_flash_count >= 4)
			{
				g_flash_count = 0;
				g_is_flashing = false;
				
				return 1;
			}
			else
				return 0;
		}
		case Flash_Mid:
		{
			g_flash_count += 1;
			switch(g_flash_count)
			{
				case 1: { style = 1; }
				case 2: { style = 2; }
				case 3: { style = 1; }
				case 4: { style = 2; }
				case 5: { style = 1; }
				case 6: { style = 0; }
			}
			if(is_thunder_enable())
				engfunc(EngFunc_LightStyle, 0, g_light_style[style]);
			
			if (g_flash_count >= 6)
			{
				g_flash_count = 0;
				g_is_flashing = false;
				
				return 1;
			}
			else
				return 0;
		}
		case Flash_Max:
		{
			g_flash_count += 1;
			switch(g_flash_count)
			{
				case 1: { style = 1; }
				case 2: { style = 2; }
				case 3: { style = 1; }
				case 4: { style = 2; }
				case 5: { style = 1; }
				case 6: { style = 2; }
				case 7: { style = 1; }
				case 8: { style = 0; }
			}
			if(is_thunder_enable())
				engfunc(EngFunc_LightStyle, 0, g_light_style[style]);
			
			if (g_flash_count >= 8)
			{
				g_flash_count = 0;
				g_is_flashing = false;
				
				return 1;
			}
			else
				return 0;
		}
	}
	return 1;
}

public CreateLightningPoints(client) 
{
	static entity, x, Float:vel[3], Float:origin[3];
	static Float:Mins[3] = { -1.0, -1.0, -1.0 };
	static Float:Maxs[3] = { 1.0, 1.0, 1.0 };
	
	new Float:dist = is_user_outside(client) - 5.0;
	
	pev(client, pev_origin, origin);
	
	if (dist > 700.0)
		dist = 700.0;
	
	origin[2] += dist;
	
	for(x = 0 ; x < MAX_LIGHT_POINTS ; x++) 
	{
		entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"));
		set_pev(entity, pev_movetype, MOVETYPE_FLY);
		set_pev(entity, pev_solid, SOLID_TRIGGER);
		set_pev(entity, pev_renderamt, 0.0);
		set_pev(entity, pev_rendermode, kRenderTransAlpha);
		engfunc(EngFunc_SetModel, entity, "models/w_usp.mdl");
		
		set_pev(entity, pev_mins, Mins);
		set_pev(entity, pev_maxs, Maxs);
		
		vel[0] = random_float(-500.0, 500.0);
		vel[1] = random_float(-500.0, 500.0);
		vel[2] = random_float((dist <= 700.0 ? 0.0 : -100.0), (dist <= 700.0 ? 0.0 : 50.0));
		
		set_pev(entity, pev_origin, origin);
		set_pev(entity, pev_velocity, vel);
		
		g_light_points[x] = entity;
	}
	remove_task(client+TASK_AMBIENCE_LIGHT);
	set_task(0.3, "Ambience_Lightning", client+TASK_AMBIENCE_LIGHT);
	return 1;
}

public Ambience_Lightning(taskid)
{
	new x, a, b, rand;
	static endpoint = MAX_LIGHT_POINTS - 1;
	
	while(x < endpoint)
	{
		a = g_light_points[x];
		b = g_light_points[x + 1];
		x++;
		
		if (x == endpoint)
		{
			rand = random_num(0, 100);
			
			if (rand == 1)
				b = ID_AMBIENCE_LIGHT;
		}
		CreateBeam(a, b);
	}
	
	for(x = 0 ; x < MAX_LIGHT_POINTS ; x++)
	{
		if (pev_valid(g_light_points[x]))
			engfunc(EngFunc_RemoveEntity, g_light_points[x]);
	}
}

get_random_player()
{
	new random_client = 1;
	new Array:players = ArrayCreate(1, 1);
	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		if (is_user_connected(client) && is_user_alive(client) && is_user_outside(client))
			ArrayPushCell(players, client);
	}
	
	if (players != Invalid_Array && ArraySize(players))
		random_client = ArrayGetCell(players, random_num(0, ArraySize(players) - 1));
	ArrayDestroy(players);
	
	return random_client;
}

Float:is_user_outside(client)
{
	new Float:origin[3], Float:dist;
	
	pev(client, pev_origin, origin);
	
	dist = origin[2];
	
	while(engfunc(EngFunc_PointContents, origin) == -1)
		origin[2] += 5.0;
	
	if (engfunc(EngFunc_PointContents, origin) == -6)
		return (origin[2] - dist);
	
	return 0.0;
}

CreateBeam(client, entity)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(8);
	write_short(client);
	write_short(entity);
	write_short(g_light_beam);
	write_byte(0);
	write_byte(10);
	write_byte(5);
	write_byte(8);
	write_byte(100);
	write_byte(200); //R
	write_byte(200); //G
	write_byte(255); //B
	write_byte(255);
	write_byte(10);
	message_end();
}