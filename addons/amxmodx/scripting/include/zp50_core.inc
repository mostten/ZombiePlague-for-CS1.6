#if defined _zp50_core_included
  #endinput
#endif
#define _zp50_core_included

#include <zp50_core_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_core
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_core
	#endif
#else
	#pragma library zp50_core
#endif

/**
 * Returns whether a player is a zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_core_is_zombie(id)

/**
 * Returns whether a player is the first zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_first_zombie(id)

/**
 * Returns whether a player is the last zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_last_zombie(id)

/**
 * Returns whether a player is the last human.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_core_is_last_human(id)

/**
 * Returns number of alive zombies.
 *
 * @return		Zombie count.
 */
native zp_core_get_zombie_count()

/**
 * Returns number of alive humans.
 *
 * @return		Human count.
 */
native zp_core_get_human_count()

/**
 * Turns a player into a zombie.
 *
 * @param id		Player index to be infected.
 * @param attacker	Player who triggered the infection. (optional)
 * @return			True on success, false otherwise.
 */
native zp_core_infect(id, attacker = 0)

/**
 * Turns a player into a human.
 *
 * @param id		Player index to be cured.
 * @param attacker	Player who triggered the cure. (optional)
 * @return			True on success, false otherwise.
 */
native zp_core_cure(id, attacker = 0)

/**
 * Forces a player to become a zombie/human.
 *
 * Note: use this only when previous checks need to be skipped.
 *
 * @param id		Player index to be infected/cured.
 * @return			True on success, false otherwise.
 */
native zp_core_force_infect(id)
native zp_core_force_cure(id)

/**
 * Sets whether the player will be respawned as zombie or human.
 *
 * @param id			Player index.
 * @param zombie		True to respawn as zombie, false otherwise.
 */
native zp_core_respawn_as_zombie(id, zombie = true)

/**
 * Returns whether the player will be respawned as zombie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_core_is_respawn_as_zombie(id);

/**
 * Called when a player gets infected.
 *
 * @param id		Player index who was infected.
 * @param attacker	Player who triggered the infection.
 *					(0 if not available, id = attacker if he infected himself)
 */
forward zp_fw_core_infect(id, attacker)
forward zp_fw_core_infect_post(id, attacker)

/**
 * Called when a player turns back to human.
 *
 * @param id		Player index who was cured.
 * @param attacker	Player who triggered the cure.
 *					(0 if not available, id = attacker if he cured himself)
 */
forward zp_fw_core_cure(id, attacker)
forward zp_fw_core_cure_post(id, attacker)

/**
 * Called on a player infect/cure attempt. You can block it by
 * returning PLUGIN_HANDLED in your plugin.
 *
 * @param id		Player index who is being infected/cured.
 * @param attacker	Player who is triggering the infection/cure.
 *					(0 if not available, id = attacker if he is infecting/curing himself)
 */
forward zp_fw_core_infect_pre(id, attacker)
forward zp_fw_core_cure_pre(id, attacker)

/**
 * Called when a player becomes the last zombie/human.
 *
 * Note: This is called for the first zombie too.
 *
 * @param id		Player index.
 */
forward zp_fw_core_last_zombie(id)
forward zp_fw_core_last_human(id)

/**
 * Called when a player was died.
 *
 * @param victim		Victim index.
 * @param attacker		Attacker index.
 */
forward zp_fw_core_last_human_dead(victim, attacker);

/**
 * Called when a player spawns, before applying human/zombie attributes to him.
 *
 * @param id		Player index.
 */
forward zp_fw_core_spawn_post(id)

/**
 * Called when a zombie spawns, after applying zombie attributes to him.
 *
 * @param id		Player index.
 */
forward zp_fw_core_zombie_spawn_post(id)

/**
 * Called when a human spawns, after applying human attributes to him.
 *
 * @param id		Player index.
 */
forward zp_fw_core_human_spawn_post(id)
/**
 * Called when a player zombie flag was added.
 *
 * @param id		Player index.
 */
forward zp_fw_core_zombie_add_post(id)

/**
 * Called when a player zombie flag was removed.
 *
 * @param id		Player index.
 */
forward zp_fw_core_zombie_remove_post(id)

/**
 * Called on set a player light style. You can block it by
 * returning PLUGIN_HANDLED in your plugin.
 *
 * @param id			Player.
 * @param light_style	Light style.
 */
forward zp_fw_core_set_lightstyle_pre(id, const light_style[ZP_LIGHTSTYLE_LENGTH]);

/**
 * Called on set a player light style.
 *
 * @param id			Player index.
 * @param light_style	Light style.
 */
forward zp_fw_core_set_lightstyle_post(id, const light_style[ZP_LIGHTSTYLE_LENGTH]);

/**
 * Set a player light style.
 *
 * @param id			Player index.
 * @param light_style	Light style.
 * @param call_forward	Active forward?
 */
native zp_core_set_lightstyle(id, const light_style[ZP_LIGHTSTYLE_LENGTH], bool:call_forward = true);

/**
 * Set a player screen fade.
 *
 * @param id			Player index.
 * @param duration		Duration.
 * @param hold_time		Hold time.
 * @param fade_type		Fade type.
 * @param red			Color red.
 * @param green			Color green.
 * @param blue			Color blue.
 * @param alpha			Color alpha.
 * @param call_forward	Active forward?
 * @return				True if it's finish, false otherwise.
 */
native zp_core_set_screenfade(id, duration, hold_time, fade_type, red, green, blue, alpha, bool:call_forward = true);

/**
 * Called on set a player screen fade.
 * returning PLUGIN_HANDLED in your plugin.
 *
 * @param id			Player index.
 * @param duration		Duration.
 * @param hold_time		Hold time.
 * @param fade_type		Fade type.
 * @param red			Color red.
 * @param green			Color green.
 * @param blue			Color blue.
 * @param alpha			Color alpha.
 */
forward zp_fw_core_set_screenfade_pre(id, duration, hold_time, fade_type, red, green, blue, alpha);

/**
 * Called on set a player screen fade.
 *
 * @param id			Player index.
 * @param duration		Duration.
 * @param hold_time		Hold time.
 * @param fade_type		Fade type.
 * @param red			Color red.
 * @param green			Color green.
 * @param blue			Color blue.
 * @param alpha			Color alpha.
 */
forward zp_fw_core_set_screenfade_post(id, duration, hold_time, fade_type, red, green, blue, alpha);

/**
 * Update player life state.
 *
 * @param id			Player index.
 * @param user_state	Player state. 0 - nothing, 1 - dead, 2 - bomb
 */
native zp_core_update_user_state(id, user_state);

/**
 * Update player scoreboard.
 *
 * @param id			Player index.
 */
native zp_core_update_user_scoreboard(id);

/**
 * Send a player death message.
 *
 * @param attacker			Attacker index.
 * @param victim			Victim index.
 * @param headshot			Headshot flag.
 * @param killer_weapon		Killer weapon, use attacker weapon when "" string.
 */
native zp_core_send_death_msg(attacker, victim, bool:headshot = false, const killer_weapon[] = "");

/**
 * Block player's clcorpse only once.
 *
 * @param id				id index.
 * @param block				Block?
 */
native zp_core_set_block_clcorpse_once(id, bool:block = true);
