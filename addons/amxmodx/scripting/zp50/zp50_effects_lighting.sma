/*================================================================================
	
	------------------------------
	-*- [ZP] Effects: Lighting -*-
	------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_core_const>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Defaults
new const sky_names[][] = { "space" }
new const thunder_lights[][] = { "ijklmnonmlkjihgfedcb" , "klmlkjihgfedcbaabcdedcb" , "bcdefedcijklmlkjihgfedcb" }
new const map_lights[][] = { "b", "c" , "" , "d" }
new const sound_thunder[][] = { "zombie_plague/thunder1.wav" , "zombie_plague/thunder2.wav" }

#define SOUND_MAX_LENGTH 64
#define LIGHT_MAX_LENGTH 2
#define LIGHTS_MAX_LENGTH 32
#define SKYNAME_MAX_LENGTH 32

new g_sky_custom_enable = 1
new Array:g_sky_names
new Array:g_thunder_lights
new Array:g_map_lights
new Array:g_sound_thunder

#define TASK_THUNDER 100
#define TASK_THUNDER_LIGHTS 200

new g_SkyArrayIndex
new g_ThunderLightIndex, g_ThunderLightMaxLen
new g_ThunderLight[LIGHTS_MAX_LENGTH]
new g_MapLight[LIGHT_MAX_LENGTH]

new cvar_lighting, cvar_thunder_time
new cvar_triggered_lights

public plugin_init()
{
	register_plugin("[ZP] Effects: Lighting", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	cvar_lighting = register_cvar("zp_lighting", "1")
	cvar_thunder_time = register_cvar("zp_thunder_time", "10")
	cvar_triggered_lights = register_cvar("zp_triggered_lights", "1")
	
	// Set a random skybox?
	if (g_sky_custom_enable)
	{
		new skyname[SKYNAME_MAX_LENGTH]
		ArrayGetString(g_sky_names, g_SkyArrayIndex, skyname, charsmax(skyname))
		set_cvar_string("sv_skyname", skyname)
	}
	
	// Disable sky lighting so it doesn't mess with our custom lighting
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
}

public plugin_precache()
{
	// Initialize arrays
	g_sky_names = ArrayCreate(SKYNAME_MAX_LENGTH, 1)
	g_thunder_lights = ArrayCreate(LIGHTS_MAX_LENGTH, 1)
	g_map_lights = ArrayCreate(LIGHTS_MAX_LENGTH, 1)
	g_sound_thunder = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	if (!amx_load_setting_int(ZP_SETTINGS_FILE, "Custom Skies", "ENABLE", g_sky_custom_enable))
		amx_save_setting_int(ZP_SETTINGS_FILE, "Custom Skies", "ENABLE", g_sky_custom_enable)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Custom Skies", "SKY NAMES", g_sky_names)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Lightning Lights Cycle", "LIGHTS", g_thunder_lights)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Map Lights Cycle", "LIGHTS", g_map_lights)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "THUNDER", g_sound_thunder)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_sky_names) == 0)
	{
		for (index = 0; index < sizeof sky_names; index++)
			ArrayPushString(g_sky_names, sky_names[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Custom Skies", "SKY NAMES", g_sky_names)
	}
	if (ArraySize(g_thunder_lights) == 0)
	{
		for (index = 0; index < sizeof thunder_lights; index++)
			ArrayPushString(g_thunder_lights, thunder_lights[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Lightning Lights Cycle", "LIGHTS", g_thunder_lights)
	}
	if (ArraySize(g_map_lights) == 0)
	{
		for (index = 0; index < sizeof map_lights; index++)
			ArrayPushString(g_map_lights, map_lights[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Map Lights Cycle", "LIGHTS", g_map_lights)
	}
	if (ArraySize(g_sound_thunder) == 0)
	{
		for (index = 0; index < sizeof sound_thunder; index++)
			ArrayPushString(g_sound_thunder, sound_thunder[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "THUNDER", g_sound_thunder)
	}
	
	if (g_sky_custom_enable)
	{
		// Choose random sky and precache sky files
		new path[128], skyname[SKYNAME_MAX_LENGTH]
		g_SkyArrayIndex = random_num(0, ArraySize(g_sky_names) - 1)
		ArrayGetString(g_sky_names, g_SkyArrayIndex, skyname, charsmax(skyname))
		formatex(path, charsmax(path), "gfx/env/%sbk.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%sdn.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%sft.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%slf.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%srt.tga", skyname)
		precache_generic(path)
		formatex(path, charsmax(path), "gfx/env/%sup.tga", skyname)
		precache_generic(path)
	}
	
	// Precache thunder sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_thunder); index++)
	{
		ArrayGetString(g_sound_thunder, index, sound, charsmax(sound))
		precache_sound(sound)
	}
}

public plugin_cfg()
{
	// Prevents seeing enemies in the dark exploit
	server_cmd("mp_playerid 1")
	
	// Lighting task
	set_task(5.0, "lighting_task", _, _, _, "b")
	
	// Call roundstart manually
	event_round_start()
}

// Event Round Start
public event_round_start()
{
	// Map lights random
	get_random_map_light(g_MapLight);
	
	// Remove lights?
	if (!get_pcvar_num(cvar_triggered_lights))
		set_task(0.1, "remove_lights")
}

// Remove Stuff Task
public remove_lights()
{
	new ent
	
	// Triggered lights
	ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "light")) != 0)
	{
		dllfunc(DLLFunc_Use, ent, 0); // turn off the light
		set_pev(ent, pev_targetname, 0) // prevent it from being triggered
	}
}

// Lighting Task
public lighting_task()
{
	// Get lighting style
	new lighting[LIGHT_MAX_LENGTH];
	switch(get_lights_configs(lighting))
	{
		case 0:{return;}
		case 1:{format(lighting, charsmax(lighting), g_MapLight);}
	}
	
	// Set thunder task if enabled and not already in place
	if (get_pcvar_float(cvar_thunder_time) > 0.0 && !task_exists(TASK_THUNDER) && !task_exists(TASK_THUNDER_LIGHTS))
	{
		g_ThunderLightIndex = 0
		ArrayGetString(g_thunder_lights, random_num(0, ArraySize(g_thunder_lights) - 1), g_ThunderLight, charsmax(g_ThunderLight))
		g_ThunderLightMaxLen = strlen(g_ThunderLight)
		set_task(get_pcvar_float(cvar_thunder_time), "thunder_task", TASK_THUNDER)
	}
	
	// Set lighting only when no thunders are going on
	if (!task_exists(TASK_THUNDER_LIGHTS)) engfunc(EngFunc_LightStyle, 0, lighting)
}

// Thunder task
public thunder_task()
{
	// Lighting cycle starting?
	if (g_ThunderLightIndex == 0)
	{	
		// Play thunder sound
		static sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_thunder, random_num(0, ArraySize(g_sound_thunder) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
		
		// Set thunder lights task
		set_task(0.1, "thunder_task", TASK_THUNDER_LIGHTS, _, _, "b")
	}
	
	// Apply current thunder light index
	new lighting[LIGHT_MAX_LENGTH], lighting_config[LIGHT_MAX_LENGTH];
	lighting[0] = g_ThunderLight[g_ThunderLightIndex]
	switch(get_lights_configs(lighting_config))
	{
		case 0:{engfunc(EngFunc_LightStyle, 0, lighting);}
		case 1:
		{
			if(get_light_level(lighting) >= get_light_level(g_MapLight))
				engfunc(EngFunc_LightStyle, 0, lighting);
		}
		default:
		{
			if(get_light_level(lighting) >= get_light_level(lighting_config))
				engfunc(EngFunc_LightStyle, 0, lighting);
		}
	}
	
	// Increase thunder light index
	g_ThunderLightIndex++
	
	// Lighting cycle end?
	if (g_ThunderLightIndex >= g_ThunderLightMaxLen)
	{
		remove_task(TASK_THUNDER_LIGHTS)
		lighting_task()
	}
}

// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

get_lights_configs(lighting[LIGHT_MAX_LENGTH])
{
	// Get lighting style
	get_pcvar_string(cvar_lighting, lighting, LIGHT_MAX_LENGTH);
	
	// Lighting disabled? ["0"]
	if (lighting[0] == '0')
		return 0;
	
	// Lighting random? ["1"]
	if (lighting[0] == '1')
		return 1;
	
	return 2;
}

get_random_map_lights(lights[])
{
	new index = -1;
	new lights_count = ArraySize(g_map_lights);
	if(lights_count > 0)
	{
		index = random_num(0, lights_count - 1);
		ArrayGetString(g_map_lights, index, lights, LIGHTS_MAX_LENGTH);
	}
	return index;
}

get_random_map_light(light[LIGHT_MAX_LENGTH])
{
	new index = -1;
	new lights[LIGHTS_MAX_LENGTH];
	if(get_random_map_lights(lights) >= 0)
	{
		new lights_count = strlen(lights);
		if(lights_count > 0)
		{
			index = random_num(0, lights_count - 1);
			light[0] = lights[index];
		}
	}
	return index;
}

get_light_level(light[LIGHT_MAX_LENGTH])
{
	if(tolower(light[0]) == 'a')
		return 1;
	else if(tolower(light[0]) == 'b')
		return 2;
	else if(tolower(light[0]) == 'c')
		return 3;
	else if(tolower(light[0]) == 'd')
		return 4;
	else if(tolower(light[0]) == 'e')
		return 5;
	else if(tolower(light[0]) == 'f')
		return 6;
	else if(tolower(light[0]) == 'g')
		return 7;
	else if(tolower(light[0]) == 'h')
		return 8;
	else if(tolower(light[0]) == 'i')
		return 9;
	else if(tolower(light[0]) == 'j')
		return 10;
	else if(tolower(light[0]) == 'k')
		return 11;
	else if(tolower(light[0]) == 'l')
		return 12;
	else if(tolower(light[0]) == 'm')
		return 13;
	else if(tolower(light[0]) == 'n')
		return 14;
	else if(tolower(light[0]) == 'o')
		return 15;
	else if(tolower(light[0]) == 'p')
		return 16;
	else if(tolower(light[0]) == 'q')
		return 17;
	else if(tolower(light[0]) == 'r')
		return 18;
	else if(tolower(light[0]) == 's')
		return 19;
	else if(tolower(light[0]) == 't')
		return 20;
	else if(tolower(light[0]) == 'u')
		return 21;
	else if(tolower(light[0]) == 'v')
		return 22;
	else if(tolower(light[0]) == 'w')
		return 23;
	else if(tolower(light[0]) == 'x')
		return 24;
	else if(tolower(light[0]) == 'y')
		return 25;
	else if(tolower(light[0]) == 'z')
		return 26;
	else if(equal(light, ""))
		return 27;
	return 0;
}