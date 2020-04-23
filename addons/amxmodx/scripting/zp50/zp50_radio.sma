#include <amxmodx>
#include <fakemeta>

#include <zp50_core>
#include <zp50_class_zombie>
#include <zp50_class_human>
#include <zp50_radio>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_GHOST "zp50_class_ghost"
#include <zp50_class_ghost>

#define NAME_MAX_LENGTH 128
#define SOUND_MAX_LENGTH 64
#define MESSAGE_MAX_LENGTH 256
#define MAXPLAYERS 32
#define PRINT_RADIO 5
#define PITCH_RADIO 100

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

new g_MaxPlayers;
new g_msg_send_audio;
new g_msg_text_msg;

new Array:g_radio_names;
new Array:g_radio_sounds;
new Array:g_radio_messages;
new Array:g_radio_infos;
new Array:g_radio_replaces;

enum RadioTeam{
	RadioTeam_Zombie = 0,
	RadioTeam_Human,
	RadioTeam_Ghost,
	RadioTeam_Nemesis,
	RadioTeam_Survivor
};

enum _:RadioInfo{
	RadioInfo_Sound = 0,
	RadioInfo_Name,
	RadioInfo_Message,
	RadioInfo_Class,
	RadioTeam:RadioInfo_Team,
	bool:RadioInfo_Msg_Trans,
	bool:RadioInfo_Name_Trans,
	RadioMenu:RadioInfo_Menu
};

enum _:ReplaceInfo{
	ReplaceInfo_Search = 0,
	ReplaceInfo_Replace,
	ReplaceInfo_Class,
	RadioTeam:ReplaceInfo_Team,
};

public plugin_init()
{
	register_plugin("[ZP] Radio", "1.0", "Mostten");
	
	register_clcmd("radio1", "clcmd_radio1");
	register_clcmd("radio2", "clcmd_radio2");
	register_clcmd("radio3", "clcmd_radio3");
	
	g_MaxPlayers = get_maxplayers()
	g_msg_send_audio = get_user_msgid("SendAudio");
	g_msg_text_msg = get_user_msgid("TextMsg");
	
	register_message(g_msg_send_audio, "message_sendaudio");
}

public plugin_natives()
{
	register_library("zp50_radio");
	
	register_native("zp_radio_reg_zombie", "native_radio_reg_zombie");
	register_native("zp_radio_reg_human", "native_radio_reg_human");
	register_native("zp_radio_reg_ghost", "native_radio_reg_ghost");
	register_native("zp_radio_reg_nemesis", "native_radio_reg_nemesis");
	register_native("zp_radio_reg_survivor", "native_radio_reg_survivor");
	
	register_native("zp_radio_replace_zombie", "native_radio_replace_zombie");
	register_native("zp_radio_replace_human", "native_radio_replace_human");
	register_native("zp_radio_replace_ghost", "native_radio_replace_ghost");
	register_native("zp_radio_replace_nemesis", "native_radio_replace_nemesis");
	register_native("zp_radio_replace_survivor", "native_radio_replace_survivor");
	
	// Initialize dynamic arrays
	arrays_init();
	
	set_module_filter("module_filter");
	set_native_filter("native_filter");
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

public clcmd_radio1(client)
{
	new Array:infos = ArrayCreate(RadioInfo, 1);
	if(get_radio_info_arrays(RadioMenu_1, get_user_radio_team(client), get_user_radio_class(client), infos))
	{
		show_menu_radio(client, RadioMenu_1);
		return PLUGIN_HANDLED;
	}
	ArrayDestroy(infos);
	return PLUGIN_CONTINUE;
}

public clcmd_radio2(client)
{
	new Array:infos = ArrayCreate(RadioInfo, 1);
	if(get_radio_info_arrays(RadioMenu_2, get_user_radio_team(client), get_user_radio_class(client), infos))
	{
		show_menu_radio(client, RadioMenu_2);
		return PLUGIN_HANDLED;
	}
	ArrayDestroy(infos);
	return PLUGIN_CONTINUE;
}

public clcmd_radio3(client)
{
	new Array:infos = ArrayCreate(RadioInfo, 1);
	if(get_radio_info_arrays(RadioMenu_3, get_user_radio_team(client), get_user_radio_class(client), infos))
	{
		show_menu_radio(client, RadioMenu_3);
		return PLUGIN_HANDLED;
	}
	ArrayDestroy(infos);
	return PLUGIN_CONTINUE;
}

arrays_init()
{
	if(g_radio_names == Invalid_Array)
		g_radio_names = ArrayCreate(NAME_MAX_LENGTH, 1);
	if(g_radio_sounds == Invalid_Array)
		g_radio_sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	if(g_radio_messages == Invalid_Array)
		g_radio_messages = ArrayCreate(MESSAGE_MAX_LENGTH, 1);
	if(g_radio_infos == Invalid_Array)
		g_radio_infos = ArrayCreate(RadioInfo, 1);
	if(g_radio_replaces == Invalid_Array)
		g_radio_replaces = ArrayCreate(ReplaceInfo, 1);
}

public native_radio_reg_zombie(plugin_id, num_params)
{
	new name[NAME_MAX_LENGTH];
	get_string(1, name, charsmax(name));
	
	new bool:name_trans = bool:get_param(2);
	
	new message[MESSAGE_MAX_LENGTH];
	get_string(3, message, charsmax(message));
	
	new bool:message_trans = bool:get_param(4);
	
	new sound[SOUND_MAX_LENGTH];
	get_string(5, sound, charsmax(sound));
	
	new RadioMenu:radio_menu = RadioMenu:get_param(6);
	
	new RadioTeam:radio_team = RadioTeam_Zombie;
	
	new radio_class = get_param(7);
	
	return push_radio_array(name, name_trans, message, message_trans, sound, radio_menu, radio_team, radio_class);
}

public native_radio_reg_human(plugin_id, num_params)
{
	new name[NAME_MAX_LENGTH];
	get_string(1, name, charsmax(name));
	
	new bool:name_trans = bool:get_param(2);
	
	new message[MESSAGE_MAX_LENGTH];
	get_string(3, message, charsmax(message));
	
	new bool:message_trans = bool:get_param(4);
	
	new sound[SOUND_MAX_LENGTH];
	get_string(5, sound, charsmax(sound));
	
	new RadioMenu:radio_menu = RadioMenu:get_param(6);
	
	new RadioTeam:radio_team = RadioTeam_Human;
	
	new radio_class = get_param(7);
	
	return push_radio_array(name, name_trans, message, message_trans, sound, radio_menu, radio_team, radio_class);
}

public native_radio_reg_ghost(plugin_id, num_params)
{
	new name[NAME_MAX_LENGTH];
	get_string(1, name, charsmax(name));
	
	new bool:name_trans = bool:get_param(2);
	
	new message[MESSAGE_MAX_LENGTH];
	get_string(3, message, charsmax(message));
	
	new bool:message_trans = bool:get_param(4);
	
	new sound[SOUND_MAX_LENGTH];
	get_string(5, sound, charsmax(sound));
	
	new RadioMenu:radio_menu = RadioMenu:get_param(6);
	
	new RadioTeam:radio_team = RadioTeam_Ghost;
	
	new radio_class = get_param(7);
	
	return push_radio_array(name, name_trans, message, message_trans, sound, radio_menu, radio_team, radio_class);
}

public native_radio_reg_nemesis(plugin_id, num_params)
{
	new name[NAME_MAX_LENGTH];
	get_string(1, name, charsmax(name));
	
	new bool:name_trans = bool:get_param(2);
	
	new message[MESSAGE_MAX_LENGTH];
	get_string(3, message, charsmax(message));
	
	new bool:message_trans = bool:get_param(4);
	
	new sound[SOUND_MAX_LENGTH];
	get_string(5, sound, charsmax(sound));
	
	new RadioMenu:radio_menu = RadioMenu:get_param(6);
	
	new RadioTeam:radio_team = RadioTeam_Nemesis;
	
	new radio_class = 0;
	
	return push_radio_array(name, name_trans, message, message_trans, sound, radio_menu, radio_team, radio_class);
}

public native_radio_reg_survivor(plugin_id, num_params)
{
	new name[NAME_MAX_LENGTH];
	get_string(1, name, charsmax(name));
	
	new bool:name_trans = bool:get_param(2);
	
	new message[MESSAGE_MAX_LENGTH];
	get_string(3, message, charsmax(message));
	
	new bool:message_trans = bool:get_param(4);
	
	new sound[SOUND_MAX_LENGTH];
	get_string(5, sound, charsmax(sound));
	
	new RadioMenu:radio_menu = RadioMenu:get_param(6);
	
	new RadioTeam:radio_team = RadioTeam_Survivor;
	
	new radio_class = 0;
	
	return push_radio_array(name, name_trans, message, message_trans, sound, radio_menu, radio_team, radio_class);
}

public native_radio_replace_zombie(plugin_id, num_params)
{
	new search[SOUND_MAX_LENGTH], replace[SOUND_MAX_LENGTH];
	get_string(1, search, charsmax(search));
	get_string(2, replace, charsmax(replace));
	new RadioTeam:radio_team = RadioTeam_Zombie;
	new classid = get_param(3);
	return push_replace_array(search, replace, radio_team, classid);
}

public native_radio_replace_human(plugin_id, num_params)
{
	new search[SOUND_MAX_LENGTH], replace[SOUND_MAX_LENGTH];
	get_string(1, search, charsmax(search));
	get_string(2, replace, charsmax(replace));
	new RadioTeam:radio_team = RadioTeam_Human;
	new classid = get_param(3);
	return push_replace_array(search, replace, radio_team, classid);
}

public native_radio_replace_ghost(plugin_id, num_params)
{
	new search[SOUND_MAX_LENGTH], replace[SOUND_MAX_LENGTH];
	get_string(1, search, charsmax(search));
	get_string(2, replace, charsmax(replace));
	new RadioTeam:radio_team = RadioTeam_Ghost;
	new classid = get_param(3);
	return push_replace_array(search, replace, radio_team, classid);
}

public native_radio_replace_nemesis(plugin_id, num_params)
{
	new search[SOUND_MAX_LENGTH], replace[SOUND_MAX_LENGTH];
	get_string(1, search, charsmax(search));
	get_string(2, replace, charsmax(replace));
	new RadioTeam:radio_team = RadioTeam_Nemesis;
	new classid = 0;
	return push_replace_array(search, replace, radio_team, classid);
}

public native_radio_replace_survivor(plugin_id, num_params)
{
	new search[SOUND_MAX_LENGTH], replace[SOUND_MAX_LENGTH];
	get_string(1, search, charsmax(search));
	get_string(2, replace, charsmax(replace));
	new RadioTeam:radio_team = RadioTeam_Survivor;
	new classid = 0;
	return push_replace_array(search, replace, radio_team, classid);
}

bool:push_replace_array(const search[], const replace[], RadioTeam:radio_team, radio_class)
{
	if(strlen(search) <= 0 || StrContains(search, "%!MRAD_") != 0)
		return false;
	
	arrays_init();
	
	new replace_info[ReplaceInfo];
	new search_index = ArrayFindString(g_radio_sounds, search);
	if(search_index < 0)
	{
		search_index = ArraySize(g_radio_sounds);
		ArrayPushString(g_radio_sounds, search);
	}
	replace_info[ReplaceInfo_Search] = search_index;
	
	new replace_index = -1;
	if(strlen(replace) > 0)
	{
		replace_index = ArrayFindString(g_radio_sounds, replace);
		if(replace_index < 0)
		{
			precache_radio(replace);
			replace_index = ArraySize(g_radio_sounds);
			ArrayPushString(g_radio_sounds, replace);
		}
	}
	replace_info[ReplaceInfo_Replace] = replace_index;
	
	replace_info[ReplaceInfo_Class] = radio_class;
	replace_info[ReplaceInfo_Team] = radio_team;
	
	ArrayPushArray(g_radio_replaces, replace_info);
	return true;
}

bool:get_replace_info_arrays(const search[], RadioTeam:radio_team, radio_class, &Array:infos)
{
	new infos_count = ArraySize(g_radio_replaces);
	if(infos_count > 0)
	{
		for(new i = 0; i < infos_count; i++)
		{
			new replace_info[ReplaceInfo];
			ArrayGetArray(g_radio_replaces, i, replace_info);
			if(replace_info[ReplaceInfo_Team] == radio_team && replace_info[ReplaceInfo_Class] == radio_class && replace_info[ReplaceInfo_Search] >= 0)
			{
				new temp[SOUND_MAX_LENGTH];
				ArrayGetString(g_radio_sounds, replace_info[ReplaceInfo_Search], temp, charsmax(temp));
				if(equal(temp, search))
					ArrayPushArray(infos, replace_info);
			}
		}
	}
	return ArraySize(infos) > 0;
}

bool:get_replace_sound(const search[], RadioTeam:radio_team, radio_class, replace[])
{
	new Array:infos = ArrayCreate(ReplaceInfo, 1);
	if(get_replace_info_arrays(search, radio_team, radio_class, infos))
	{
		new replace_info[ReplaceInfo];
		ArrayGetArray(infos, random_num(0, ArraySize(infos) - 1), replace_info);
		if(replace_info[ReplaceInfo_Replace] >= 0)
			ArrayGetString(g_radio_sounds, replace_info[ReplaceInfo_Replace], replace, SOUND_MAX_LENGTH);
		else
			format(replace, SOUND_MAX_LENGTH, "%d", replace_info[ReplaceInfo_Replace]);
		return true;
	}
	ArrayDestroy(infos);
	return false;
}

precache_radio(const radio[])
{
	if(equal(radio[strlen(radio)-4], ".mp3"))
	{
		new path[128];
		format(path, charsmax(path), "sound/%s", radio);
		precache_generic(path);
	}
	else
		precache_sound(radio);
}

bool:push_radio_array(const name[], bool:name_trans, const message[], bool:message_trans, const sound[], RadioMenu:radio_menu, RadioTeam:radio_team, radio_class)
{
	arrays_init();
	
	new radio_info[RadioInfo];
	if(strlen(name) > 0)
	{
		new name_index = ArrayFindString(g_radio_names, name);
		if(name_index < 0)
		{
			name_index = ArraySize(g_radio_names);
			ArrayPushString(g_radio_names, name);
		}
		radio_info[RadioInfo_Name] = name_index;
	}
	else
		return false;
	
	if(strlen(sound) > 0)
	{
		new sound_index = ArrayFindString(g_radio_sounds, sound);
		if(sound_index < 0)
		{
			precache_radio(sound);
			sound_index = ArraySize(g_radio_sounds);
			ArrayPushString(g_radio_sounds, sound);
		}
		radio_info[RadioInfo_Sound] = sound_index;
	}
	else
		radio_info[RadioInfo_Sound] = -1;
	
	if(strlen(message) > 0)
	{
		new message_index = ArrayFindString(g_radio_messages, message);
		if(message_index < 0)
		{
			message_index = ArraySize(g_radio_messages);
			ArrayPushString(g_radio_messages, message);
		}
		radio_info[RadioInfo_Message] = message_index;
	}
	else
		radio_info[RadioInfo_Message] = -1;
	
	if(radio_info[RadioInfo_Sound] < 0 && radio_info[RadioInfo_Message] < 0)
		return false;
	
	radio_info[RadioInfo_Name_Trans] = name_trans;
	radio_info[RadioInfo_Msg_Trans] = message_trans;
	radio_info[RadioInfo_Menu] = radio_menu;
	radio_info[RadioInfo_Team] = radio_team;
	radio_info[RadioInfo_Class] = radio_class;
	
	ArrayPushArray(g_radio_infos, radio_info);
	return true;
}

RadioTeam:get_user_radio_team(client)
{
	if(is_user_valid(client))
	{
		if(LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(client))
			return RadioTeam_Nemesis;
		else if(LibraryExists(LIBRARY_GHOST, LibType_Library) && zp_class_ghost_get(client))
			return RadioTeam_Ghost;
		else if(LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(client))
			return RadioTeam_Survivor;
		else if(zp_core_is_zombie(client))
			return RadioTeam_Zombie;
	}
	return RadioTeam_Human;
}

get_user_radio_class(client)
{
	new classid = -1;
	if(is_user_valid(client))
	{
		switch(get_user_radio_team(client))
		{
			case RadioTeam_Human:
			{
				classid = zp_class_human_get_current(client);
				if(classid != ZP_INVALID_HUMAN_CLASS)
					return classid;
			}
			case RadioTeam_Ghost:
			{
				classid = zp_class_ghost_get_current(client);
				if(classid != ZP_INVALID_GHOST_CLASS)
					return classid;
			}
			case RadioTeam_Zombie:
			{
				classid = zp_class_zombie_get_current(client);
				if(classid != ZP_INVALID_ZOMBIE_CLASS)
					return classid;
			}
			case RadioTeam_Nemesis:
			{
				return 0;
			}
			case RadioTeam_Survivor:
			{
				return 0;
			}
		}
	}
	return classid;
}

bool:get_radio_info_arrays(RadioMenu:radio_menu, RadioTeam:radio_team, radio_class, &Array:infos)
{
	new infos_count = ArraySize(g_radio_infos);
	if(infos_count > 0)
	{
		for(new i = 0; i < infos_count; i++)
		{
			new radio_info[RadioInfo];
			ArrayGetArray(g_radio_infos, i, radio_info);
			if(radio_info[RadioInfo_Menu] == radio_menu && radio_info[RadioInfo_Team] == radio_team && radio_info[RadioInfo_Class] == radio_class)
				ArrayPushArray(infos, radio_info);
		}
	}
	return ArraySize(infos) > 0;
}

/**
 * Tests whether a string is found inside another string.
 *
 * @param str			String to search in.
 * @param substr		Substring to find inside the original string.
 * @param caseSensitive	If true (default), search is case sensitive.
 *						If false, search is case insensitive.
 * @return				-1 on failure (no match found). Any other value
 *						indicates a position in the string where the match starts.
 */
StrContains(const str[], const substr[], bool:caseSensitive = true)
{
	new strSize = strlen(str) + 1;
	new substrSize = strlen(substr) + 1;
	if(strSize < 2 || substrSize < 2 || substrSize > strSize)
		return -1;
	
	for(new i = 0; i < strSize; i++)
	{
		if((caseSensitive && str[i] != substr[0]) || (!caseSensitive && tolower(str[i]) != tolower(substr[0])))
			continue;
		new count = 1;
		for(new subi = 1; subi < substrSize; subi++)
		{
			new temp = i + subi;
			if((temp < strSize) && ((caseSensitive && substr[subi] == str[temp]) || (!caseSensitive && tolower(substr[subi]) == tolower(str[temp]))))
			{
				count++;
			}
			else
			{
				break;
			}
			if(count == strlen(substr))
				return i;
		}
	}
	return -1;
}

show_menu_radio(client, RadioMenu:radio_menu)
{
	new Array:infos = ArrayCreate(RadioInfo, 1);
	if(get_radio_info_arrays(radio_menu, get_user_radio_team(client), get_user_radio_class(client), infos))
	{
		new menu[NAME_MAX_LENGTH];
		switch(radio_menu)
		{
			case RadioMenu_1:{formatex(menu, charsmax(menu), "%s\r", "Radio 1");}
			case RadioMenu_2:{formatex(menu, charsmax(menu), "%s\r", "Radio 2");}
			case RadioMenu_3:{formatex(menu, charsmax(menu), "%s\r", "Radio 3");}
			default:{formatex(menu, charsmax(menu), "%s\r", "Radio");}
		}
		new menuid = menu_create(menu, "radio_menu_handle");
		for(new i = 0; i < ArraySize(infos); i++)
		{
			new name[NAME_MAX_LENGTH];
			new radio_info[RadioInfo];
			ArrayGetArray(infos, i, radio_info);
			ArrayGetString(g_radio_names, radio_info[RadioInfo_Name], name, charsmax(name));
			
			if(radio_info[RadioInfo_Name_Trans])
				formatex(menu, charsmax(menu), "%L", client, name);
			else
				formatex(menu, charsmax(menu), "%s", name);
			
			new itemdata[32];
			format(itemdata, charsmax(itemdata), "%d,%d,%d,%d,%d,%d,%d,%d", radio_info[RadioInfo_Sound], radio_info[RadioInfo_Name], radio_info[RadioInfo_Message], radio_info[RadioInfo_Class], radio_info[RadioInfo_Team], radio_info[RadioInfo_Msg_Trans], radio_info[RadioInfo_Name_Trans], radio_info[RadioInfo_Menu]);
			
			menu_additem(menuid, menu, itemdata);
		}
		// Back - Next - Exit
		formatex(menu, charsmax(menu), "%L", client, "MENU_BACK")
		menu_setprop(menuid, MPROP_BACKNAME, menu)
		formatex(menu, charsmax(menu), "%L", client, "MENU_NEXT")
		menu_setprop(menuid, MPROP_NEXTNAME, menu)
		formatex(menu, charsmax(menu), "%L", client, "MENU_EXIT")
		menu_setprop(menuid, MPROP_EXITNAME, menu)
		
		// Fix for AMXX custom menus
		set_pdata_int(client, OFFSET_CSMENUCODE, 0);
		menu_display(client, menuid);
	}
	ArrayDestroy(infos);
}

public radio_menu_handle(client, menuid, item)
{
	// Menu was closed
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid);
		return PLUGIN_HANDLED;
	}
	
	new itemdata[32], dummy, buffers[RadioInfo][32];
	menu_item_getinfo(menuid, item, dummy, itemdata, charsmax(itemdata), _, _, dummy);
	explode_string(itemdata, ",", buffers, RadioInfo, 32);
	
	new radio_info[RadioInfo];
	radio_info[RadioInfo_Sound] = str_to_num(buffers[RadioInfo_Sound]);
	radio_info[RadioInfo_Name] = str_to_num(buffers[RadioInfo_Name]);
	radio_info[RadioInfo_Message] = str_to_num(buffers[RadioInfo_Message]);
	radio_info[RadioInfo_Class] = str_to_num(buffers[RadioInfo_Class]);
	radio_info[RadioInfo_Team] = RadioTeam:str_to_num(buffers[RadioInfo_Team]);
	radio_info[RadioInfo_Msg_Trans] = bool:str_to_num(buffers[RadioInfo_Msg_Trans]);
	radio_info[RadioInfo_Name_Trans] = bool:str_to_num(buffers[RadioInfo_Name_Trans]);
	radio_info[RadioInfo_Menu] = RadioMenu:str_to_num(buffers[RadioInfo_Menu]);
	
	if(radio_info[RadioInfo_Team] == get_user_radio_team(client) && radio_info[RadioInfo_Class] == get_user_radio_class(client))
	{
		new message[MESSAGE_MAX_LENGTH], sound[SOUND_MAX_LENGTH];
		if(radio_info[RadioInfo_Message] >= 0)
			ArrayGetString(g_radio_messages, radio_info[RadioInfo_Message], message, charsmax(message));
		if(radio_info[RadioInfo_Msg_Trans])
			format(message, charsmax(message), "%L", client, message);
		if(radio_info[RadioInfo_Sound] >= 0)
			ArrayGetString(g_radio_sounds, radio_info[RadioInfo_Sound], sound, charsmax(sound));
		
		radio_send_team(radio_info[RadioInfo_Team], message, sound);
	}
	menu_destroy(menuid);
	return PLUGIN_HANDLED;
}

message_send(client, const message[])
{
	new szClient[3], szName[32];
	num_to_str(client, szClient, charsmax(szClient));
	get_user_name(client, szName, charsmax(szName))
	emessage_begin(MSG_ONE_UNRELIABLE, g_msg_text_msg, .player=client);
	ewrite_byte(PRINT_RADIO);
	ewrite_string(szClient);
	ewrite_string("#Game_radio");
	ewrite_string(szName);
	ewrite_string(message);
	emessage_end();
}


sound_send(client, const sound[])
{
	emessage_begin(MSG_ONE_UNRELIABLE, g_msg_send_audio, .player=client);
	ewrite_byte(client);
	ewrite_string(sound);
	ewrite_short(PITCH_RADIO);
	emessage_end();
}

radio_send(client, const message[], const sound[])
{
	if(strlen(message) > 0)
		message_send(client, message);
	if(strlen(sound) > 0)
		sound_send(client, sound);
}

radio_send_team(RadioTeam:radio_team, const message[], const sound[])
{
	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		if(is_user_connected(client) && !is_user_bot(client) && is_user_alive(client) && get_user_radio_team(client) == radio_team)
			radio_send(client, message, sound);
	}
}

public message_sendaudio(msg_id, msg_dest, client)
{
	new sound[SOUND_MAX_LENGTH], replace[SOUND_MAX_LENGTH];
	get_msg_arg_string(2, sound, charsmax(sound))
	
	if(StrContains(sound, "%!MRAD_") == 0 && get_replace_sound(sound, get_user_radio_team(client), get_user_radio_class(client), replace))
	{
		if(!equal(sound, replace))
			set_msg_arg_string(2, replace);
		else if(is_str_num(replace) && str_to_num(replace) < 0)
			return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

bool:is_user_valid(client)
{
	return (1 <= client <= g_MaxPlayers);
}
