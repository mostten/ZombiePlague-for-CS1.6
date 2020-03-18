/*================================================================================
	
	---------------------------------
	-*- [ZP] Game Mode: Ghost -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_teams_api>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zp50_class_ghost>
#include <zp50_deathmatch>

// 配置文件
new const ZP_SETTINGS_FILE[] = "zombieplague_mod_ghost.ini"

// HUD文字位置与颜色
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 0
#define HUD_EVENT_B 0

new g_GhostModeId
new g_MaxPlayers
new g_HudSync
new g_TargetPlayer

new cvar_ghost_chance, cvar_ghost_min_players
new cvar_ghost_show_hud, cvar_ghost_sounds
new cvar_ghost_allow_respawn, cvar_ghost_respawn_last_human
new cvar_ghost_first_hp_multiplier

// 声音文件
new const sound_ghost[][] = {
	"zombie_plague/ghost/ghost_change01.wav",
	"zombie_plague/ghost/ghost_change02.wav",
	"zombie_plague/ghost/ghost_change03.wav"
}

#define SOUND_MAX_LENGTH 64

new Array:g_sound_ghost

public plugin_precache()
{
	// 缓存时注册游戏模式 (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Ghost", ZP_VERSION_STRING, "Mostten")
	g_GhostModeId = zp_gamemodes_register("Ghost Mode")
	// 设置为默认模式
	//zp_gamemodes_set_default(g_GhostModeId)
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_ghost_chance = register_cvar("zp_ghost_chance", "1")
	cvar_ghost_min_players = register_cvar("zp_ghost_min_players", "0")
	cvar_ghost_show_hud = register_cvar("zp_ghost_show_hud", "1")
	cvar_ghost_allow_respawn = register_cvar("zp_ghost_allow_respawn", "1")
	cvar_ghost_respawn_last_human = register_cvar("zp_ghost_respawn_after_last_human", "1")
	cvar_ghost_first_hp_multiplier = register_cvar("zp_ghost_first_hp_multiplier", "2.0")
	cvar_ghost_sounds = register_cvar("zp_ghost_sounds", "1")
	
	// 初始化数组
	g_sound_ghost = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// 载入外部文件
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND GHOST", g_sound_ghost)
	
	// 如果不能载入自定义声音文件, 使用默认文件
	new index
	if (ArraySize(g_sound_ghost) == 0)
	{
		for (index = 0; index < sizeof sound_ghost; index++)
			ArrayPushString(g_sound_ghost, sound_ghost[index])
		
		// 存储至外部文件
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND GHOST", g_sound_ghost)
	}
	
	// 缓存声音文件
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_ghost); index++)
	{
		ArrayGetString(g_sound_ghost, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// 是否允许重生?
	if (!get_pcvar_num(cvar_ghost_allow_respawn))
		return PLUGIN_HANDLED;
	
	// 剩余最后1人激活重生?
	if (!get_pcvar_num(cvar_ghost_respawn_last_human) && zp_core_get_human_count() == 1)
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	// 在幽灵局允许复活玩家
	zp_core_respawn_as_zombie(id, false)
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// 不满足几率禁用模式
		if (random_num(1, get_pcvar_num(cvar_ghost_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// 不满足最少人数禁用模式
		if (GetAliveCount() < get_pcvar_num(cvar_ghost_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// 是否随机玩家?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
}

public zp_fw_gamemodes_start(game_mode_id)
{
	if (g_GhostModeId == ZP_INVALID_GAME_MODE || game_mode_id != g_GhostModeId)
		return;
	// 此模式中激活感染功能
	zp_gamemodes_set_allow_infect(true)
	
	// 转换玩家成为第一个幽灵
	zp_class_ghost_set(g_TargetPlayer, g_TargetPlayer)
	set_user_health(g_TargetPlayer, floatround(get_user_health(g_TargetPlayer) * get_pcvar_float(cvar_ghost_first_hp_multiplier)))
	
	// 剩余玩家成为人类 (CTs)
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// 没有存活
		if (!is_user_alive(id))
			continue;
		
		// 这是我们第一个幽灵
		if (zp_class_ghost_get(id))
			continue;
		
		// 切换至人类阵营 CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	
	// 播放幽灵声音
	if (get_pcvar_num(cvar_ghost_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_ghost, random_num(0, ArraySize(g_sound_ghost) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_ghost_show_hud))
	{
		// 展示第一个幽灵信息 HUD 通知
		new name[32]
		get_user_name(g_TargetPlayer, name, charsmax(name))
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "GHOST_NOTICE_FIRST", name)
	}
}

// 播放声音给所有玩家
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}

// 获取存活玩家数量
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// 获取随机存活玩家 -返回存活玩家ID -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}