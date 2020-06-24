/*================================================================================
	
	------------------------
	-*- [ZP] Nightvision -*-
	------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_core>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_GHOST "zp50_class_ghost"
#include <zp50_class_ghost>

#define TASK_NIGHTVISION 100
#define ID_NIGHTVISION (taskid - TASK_NIGHTVISION)

#define MAXPLAYERS 32
#define TASK_SCREENFADE 200
#define ID_SCREENFADE (taskid - TASK_SCREENFADE)

const UNIT_SECOND = (1<<12);
const FFADE_IN = 0x0000;
const FFADE_STAYOUT = 0x0004;

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_NightVisionActive

new g_MsgNVGToggle, g_MsgScreenFade;

new cvar_nvision_custom, cvar_nvision_radius
new cvar_nvision_zombie, cvar_nvision_zombie_color_R, cvar_nvision_zombie_color_G, cvar_nvision_zombie_color_B
new cvar_nvision_human, cvar_nvision_human_color_R, cvar_nvision_human_color_G, cvar_nvision_human_color_B
new cvar_nvision_spec, cvar_nvision_spec_color_R, cvar_nvision_spec_color_G, cvar_nvision_spec_color_B
new cvar_nvision_nemesis, cvar_nvision_nemesis_color_R, cvar_nvision_nemesis_color_G, cvar_nvision_nemesis_color_B
new cvar_nvision_survivor, cvar_nvision_survivor_color_R, cvar_nvision_survivor_color_G, cvar_nvision_survivor_color_B
new cvar_nvision_ghost, cvar_nvision_ghost_color_R, cvar_nvision_ghost_color_G, cvar_nvision_ghost_color_B

new g_szCurrentLight[MAXPLAYERS+1][ZP_LIGHTSTYLE_LENGTH];

public plugin_init()
{
	register_plugin("[ZP] Nightvision", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MsgNVGToggle = get_user_msgid("NVGToggle")
	register_message(g_MsgNVGToggle, "message_nvgtoggle")
	
	g_MsgScreenFade = get_user_msgid("ScreenFade");
	register_message(g_MsgScreenFade, "message_screenfade");
	
	register_clcmd("nightvision", "clcmd_nightvision_toggle")
	register_event("ResetHUD", "event_reset_hud", "b")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	cvar_nvision_custom = register_cvar("zp_nvision_custom", "0")
	cvar_nvision_radius = register_cvar("zp_nvision_radius", "80")
	
	cvar_nvision_zombie = register_cvar("zp_nvision_zombie", "2") // 1-give only // 2-give and enable
	cvar_nvision_zombie_color_R = register_cvar("zp_nvision_zombie_color_R", "0")
	cvar_nvision_zombie_color_G = register_cvar("zp_nvision_zombie_color_G", "150")
	cvar_nvision_zombie_color_B = register_cvar("zp_nvision_zombie_color_B", "0")
	cvar_nvision_human = register_cvar("zp_nvision_human", "0") // 1-give only // 2-give and enable
	cvar_nvision_human_color_R = register_cvar("zp_nvision_human_color_R", "0")
	cvar_nvision_human_color_G = register_cvar("zp_nvision_human_color_G", "150")
	cvar_nvision_human_color_B = register_cvar("zp_nvision_human_color_B", "0")
	cvar_nvision_spec = register_cvar("zp_nvision_spec", "2") // 1-give only // 2-give and enable
	cvar_nvision_spec_color_R = register_cvar("zp_nvision_spec_color_R", "0")
	cvar_nvision_spec_color_G = register_cvar("zp_nvision_spec_color_G", "150")
	cvar_nvision_spec_color_B = register_cvar("zp_nvision_spec_color_B", "0")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		cvar_nvision_nemesis = register_cvar("zp_nvision_nemesis", "2")
		cvar_nvision_nemesis_color_R = register_cvar("zp_nvision_nemesis_color_R", "150")
		cvar_nvision_nemesis_color_G = register_cvar("zp_nvision_nemesis_color_G", "0")
		cvar_nvision_nemesis_color_B = register_cvar("zp_nvision_nemesis_color_B", "0")
	}
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
	{
		cvar_nvision_survivor = register_cvar("zp_nvision_survivor", "0")
		cvar_nvision_survivor_color_R = register_cvar("zp_nvision_survivor_color_R", "0")
		cvar_nvision_survivor_color_G = register_cvar("zp_nvision_survivor_color_G", "0")
		cvar_nvision_survivor_color_B = register_cvar("zp_nvision_survivor_color_B", "150")
	}
	
	// Ghost Class loaded?
	if (LibraryExists(LIBRARY_GHOST, LibType_Library))
	{
		cvar_nvision_ghost = register_cvar("zp_nvision_ghost", "2")
		cvar_nvision_ghost_color_R = register_cvar("zp_nvision_ghost_color_R", "150")
		cvar_nvision_ghost_color_G = register_cvar("zp_nvision_ghost_color_G", "0")
		cvar_nvision_ghost_color_B = register_cvar("zp_nvision_ghost_color_B", "0")
	}
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_GHOST))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
	{
		if (get_pcvar_num(cvar_nvision_nemesis))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_nemesis) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	// Ghost Class loaded?
	if (LibraryExists(LIBRARY_GHOST, LibType_Library) && zp_class_ghost_get(id))
	{
		if (get_pcvar_num(cvar_nvision_ghost))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_ghost) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	else
	{
		if (get_pcvar_num(cvar_nvision_zombie))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_zombie) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	
	// Always give nightvision to PODBots
	if (is_user_bot(id) && !cs_get_user_nvg(id))
		cs_set_user_nvg(id, 1)
}

public zp_fw_core_cure_post(id, attacker)
{
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
	{
		if (get_pcvar_num(cvar_nvision_survivor))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_survivor) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	else
	{
		if (get_pcvar_num(cvar_nvision_human))
		{
			if (!cs_get_user_nvg(id)) cs_set_user_nvg(id, 1)
			
			if (get_pcvar_num(cvar_nvision_human) == 2)
			{
				if (!flag_get(g_NightVisionActive, id))
					clcmd_nightvision_toggle(id)
			}
			else if (flag_get(g_NightVisionActive, id))
				clcmd_nightvision_toggle(id)
		}
		else
		{
			cs_set_user_nvg(id, 0)
			
			if (flag_get(g_NightVisionActive, id))
				DisableNightVision(id)
		}
	}
	
	// Always give nightvision to PODBots
	if (is_user_bot(id) && !cs_get_user_nvg(id))
		cs_set_user_nvg(id, 1)
}

public clcmd_nightvision_toggle(id)
{
	if (is_user_alive(id))
	{
		// Player owns nightvision?
		if (!cs_get_user_nvg(id))
			return PLUGIN_CONTINUE;
	}
	else
	{
		// Spectator nightvision disabled?
		if (!get_pcvar_num(cvar_nvision_spec))
			return PLUGIN_CONTINUE;
	}
	
	if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
	else
		EnableNightVision(id)
	
	return PLUGIN_HANDLED;
}

// ResetHUD Removes CS Nightvision (bugfix)
public event_reset_hud(id)
{
	if (flag_get(g_NightVisionActive, id))
		switch(get_pcvar_num(cvar_nvision_custom)){case 0:{cs_set_user_nvg_active(id, 1);}}
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Enable spectators nightvision?
	spectator_nightvision(victim)
}

public zp_fw_core_set_lightstyle_pre(id, const light_style[ZP_LIGHTSTYLE_LENGTH])
{
	g_szCurrentLight[id][0] = light_style[0];
	if(get_pcvar_num(cvar_nvision_custom) == 2 && flag_get(g_NightVisionActive, id))
	{
		zp_core_set_lightstyle(id, "#", false);
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	// Enable spectators nightvision?
	set_task(0.1, "spectator_nightvision", id)
}

public spectator_nightvision(id)
{
	// Player disconnected
	if (!is_user_connected(id))
		return;
	
	// Not a spectator
	if (is_user_alive(id))
		return;
	
	if (get_pcvar_num(cvar_nvision_spec) == 2)
	{
		if (!flag_get(g_NightVisionActive, id))
			clcmd_nightvision_toggle(id)
	}
	else if (flag_get(g_NightVisionActive, id))
		DisableNightVision(id)
}

public client_disconnected(id)
{
	// Reset nightvision flags
	flag_unset(g_NightVisionActive, id);
	remove_task(id+TASK_NIGHTVISION);
	remove_task(id+TASK_SCREENFADE);
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_nvgtoggle(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

public message_screenfade(msg_id, msg_dest, msg_entity)
{
	// Nightvision was disabled?
	if (!flag_get(g_NightVisionActive, msg_entity))
		return PLUGIN_CONTINUE;
	
	// Is this a flashbang?
	if (get_msg_arg_int(4) != 255 || get_msg_arg_int(5) != 255 || get_msg_arg_int(6) != 255 || get_msg_arg_int(7) < 200)
		return PLUGIN_CONTINUE;
	
	if(get_pcvar_num(cvar_nvision_custom) == 2)
	{
		remove_task(msg_entity+TASK_SCREENFADE);
		set_task(get_msg_arg_int(1)/UNIT_SECOND*1.0, "restore_screenfade_task", msg_entity+TASK_SCREENFADE);
	}
	return PLUGIN_CONTINUE;
}

public zp_fw_core_set_screenfade_post(id, duration, hold_time, fade_type, red, green, blue, alpha)
{
	remove_task(id+TASK_SCREENFADE);
	set_task(duration/UNIT_SECOND*1.0, "restore_screenfade_task", id+TASK_SCREENFADE);
}

// Custom Night Vision Task
public custom_nightvision_task(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_NIGHTVISION, origin)
	
	// Getplayer's config color
	new red, green, blue;
	get_user_nvg_color(ID_NIGHTVISION, red, green, blue);
	
	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NIGHTVISION)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(get_pcvar_num(cvar_nvision_radius)) // radius
	write_byte(red) // r
	write_byte(green) // g
	write_byte(blue) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

EnableNightVision(id)
{
	flag_set(g_NightVisionActive, id)
	
	switch(get_pcvar_num(cvar_nvision_custom))
	{
		case 0:{cs_set_user_nvg_active(id, 1);}
		case 1:{set_task(0.1, "custom_nightvision_task", id+TASK_NIGHTVISION, _, _, "b");}
		case 2:{set_user_nightvision(id, true);}
	}
}

DisableNightVision(id)
{
	flag_unset(g_NightVisionActive, id)
	
	switch(get_pcvar_num(cvar_nvision_custom))
	{
		case 0:{cs_set_user_nvg_active(id, 0);}
		case 1:{remove_task(id+TASK_NIGHTVISION);}
		case 2:{set_user_nightvision(id, false);}
	}
}

stock cs_set_user_nvg_active(id, active)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_MsgNVGToggle, _, id)
	write_byte(active) // toggle
	message_end()
}

set_user_nightvision(client, bool:on)
{
	new red, green, blue, alpha = 73;
	get_user_nvg_color(client, red, green, blue);
	if(on)
	{
		zp_core_set_lightstyle(client, "#", false);
		RequestFrame("restore_screenfade_task", client+TASK_SCREENFADE);
	}
	else
	{
		zp_core_set_lightstyle(client, g_szCurrentLight[client], false);
		zp_core_set_screenfade(client, 0, 0, FFADE_IN, red, green, blue, alpha, false);
	}
}

get_user_nvg_color(client, &red, &green, &blue)
{
	// Spectator
	if (!is_user_alive(client))
	{
		red = get_pcvar_num(cvar_nvision_spec_color_R);
		green = get_pcvar_num(cvar_nvision_spec_color_G);
		blue = get_pcvar_num(cvar_nvision_spec_color_B);
	}
	// Zombie
	else if (zp_core_is_zombie(client))
	{
		// Nemesis Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(client))
		{
			red = get_pcvar_num(cvar_nvision_nemesis_color_R);
			green = get_pcvar_num(cvar_nvision_nemesis_color_G);
			blue = get_pcvar_num(cvar_nvision_nemesis_color_B);
		}
		// Ghost Class loaded?
		else if (LibraryExists(LIBRARY_GHOST, LibType_Library) && zp_class_ghost_get(client))
		{
			red = get_pcvar_num(cvar_nvision_ghost_color_R);
			green = get_pcvar_num(cvar_nvision_ghost_color_G);
			blue = get_pcvar_num(cvar_nvision_ghost_color_B);
		}
		else
		{
			red = get_pcvar_num(cvar_nvision_zombie_color_R);
			green = get_pcvar_num(cvar_nvision_zombie_color_G);
			blue = get_pcvar_num(cvar_nvision_zombie_color_B);
		}
	}
	// Human
	else
	{
		// Survivor Class loaded?
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(client))
		{
			red = get_pcvar_num(cvar_nvision_survivor_color_R);
			green = get_pcvar_num(cvar_nvision_survivor_color_G);
			blue = get_pcvar_num(cvar_nvision_survivor_color_B);
		}
		else
		{
			red = get_pcvar_num(cvar_nvision_human_color_R);
			green = get_pcvar_num(cvar_nvision_human_color_G);
			blue = get_pcvar_num(cvar_nvision_human_color_B);
		}
	}
}

public restore_screenfade_task(taskid)
{
	if(!flag_get(g_NightVisionActive, ID_SCREENFADE))
		return;
	
	new red, green, blue, alpha = 73;
	get_user_nvg_color(ID_SCREENFADE, red, green, blue);
	zp_core_set_screenfade(ID_SCREENFADE, 0, 0, FFADE_STAYOUT, red, green, blue, alpha, false);
}