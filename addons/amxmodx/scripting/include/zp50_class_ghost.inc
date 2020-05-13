#if defined _zp50_class_ghost_included
  #endinput
#endif
#define _zp50_class_ghost_included

#include <zp50_core>
#include <zp50_class_ghost_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_ghost
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_ghost
	#endif
#else
	#pragma library zp50_class_ghost
#endif

/**
 * Returns a player's current ghost class ID.
 *
 * @param id		Player index.
 * @return			Internal ghost class ID, or ZP_INVALID_GHOST_CLASS if not yet chosen.
 */
native zp_class_ghost_get_current(id)

/**
 * Returns a player's next ghost class ID (for the next infection).
 *
 * @param id		Player index.
 * @return			Internal ghost class ID, or ZP_INVALID_GHOST_CLASS if not yet chosen.
 */
native zp_class_ghost_get_next(id)

/**
 * Sets a player's next ghost class ID (for the next infection).
 *
 * @param id		Player index.
 * @param classid	A valid ghost class ID.
 * @return			True on success, false otherwise.
 */
native zp_class_ghost_set_next(id, classid)

/**
 * Returns the default maximum health for a specific ghost class.
 *
 * Note: does not take into account any kind of HP multipliers.
 *
 * @param id		Player index.
 * @param classid	A valid ghost class ID.
 * @return			Maximum amount of health points, -1 on error.
 */
native zp_class_ghost_get_max_health(id, classid)

/**
 * Registers a custom class which will be added to the ghost classes menu of ZP.
 *
 * Note: The returned ghost class ID can be later used to identify
 * the class when calling the zp_get_user_ghost_class() natives.
 *
 * @param name					Caption to display on the menu.
 * @param description			Brief description of the class.
 * @param health				Class health.
 * @param speed					Class maxspeed (can be a multiplier).
 * @param gravity				Class gravity multiplier.
 * @param infection				Class allow infection.
 * @param speedPrimaryAttack	Primary attack speed.
 * @param speedSecondaryAttack	Secondary attack speed.
 * @param damagePrimaryAttack	Primary attack damage.
 * @param damageSecondaryAttack	Secondary attack damage.
 * @param blood					Class allow blood.
 * @return						An internal ghost class ID, or ZP_INVALID_GHOST_CLASS on failure.
 */
native zp_class_ghost_register(const name[], const description[], health, Float:speed, Float:gravity, bool:infection, Float:speedPrimaryAttack, Float:speedSecondaryAttack, Float:damagePrimaryAttack, Float:damageSecondaryAttack, bool:blood = true)

/**
 * Registers a custom player model for a given ghost class.
 *
 * @param classid		A valid ghost class ID.
 * @param model			Player model's short name.
 * @return				True on success, false otherwise.
 */
native zp_class_ghost_register_model(classid, const model[])

/**
 * Registers a custom claw model for a given ghost class.
 *
 * @param classid		A valid ghost class ID.
 * @param clawmodel		Claw model filename.
 * @return				True on success, false otherwise.
 */
native zp_class_ghost_register_claw(classid, const clawmodel[])

/**
 * Registers a ghost class' knockback multiplier.
 *
 * @param classid		A valid ghost class ID.
 * @param knockback		Knockback multiplier.
 * @return				True on success, false otherwise.
 */
native zp_class_ghost_register_kb(classid, Float:knockback)

/**
 * Registers a ghost class' damage multiplier.
 *
 * @param classid			A valid ghost class ID.
 * @param damage_multiplier	Damage multiplier.
 * @return					True on success, false otherwise.
 */
native zp_class_ghost_register_dm(classid, Float:damage_multiplier)

/**
 * Returns a ghost class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal ghost class ID, or ZP_INVALID_GHOST_CLASS if not found.
 */
native zp_class_ghost_get_id(const real_name[])

/**
 * Returns a ghost class' name.
 *
 * @param classid	A valid ghost class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_class_ghost_get_name(classid, name[], len)

/**
 * Returns a ghost class' real name (used when registering the class).
 *
 * @param classid	A valid ghost class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_class_ghost_get_real_name(classid, real_name[], len)

/**
 * Returns a ghost class' description.
 *
 * @param classid		A valid ghost class ID.
 * @param description	The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native zp_class_ghost_get_desc(classid, description[], len)

/**
 * Returns a ghost class' knockback multiplier.
 *
 * @param classid		A valid ghost class ID.
 * @return				Knockback multiplier (float value).
 */
native Float:zp_class_ghost_get_kb(classid)

/**
 * Returns a ghost class' damage multiplier.
 *
 * @param classid		A valid ghost class ID.
 * @return				Damage multiplier (float value).
 */
native Float:zp_class_ghost_get_dm(classid)

/**
 * Returns number of registered ghost classes.
 *
 * @return			Zombie class count.
 */
native zp_class_ghost_get_count()

/**
 * Shows menu with available ghost classes to a player.
 *
 * @param id		Player index.
 */
native zp_class_ghost_show_menu(id)

/**
 * Appends text to a class being displayed on the ghost classes menu.
 * Use this on the class select pre forward.
 *
 * @param text		Additional text to display.
 */
native zp_class_ghost_menu_text_add(const text[])

/**
 * Called when determining whether a class should be available to a player.
 *
 * Possible return values are:
 *	- ZP_CLASS_AVAILABLE (show in menu, allow selection)
 *	- ZP_CLASS_NOT_AVAILABLE (show in menu, don't allow selection)
 *	- ZP_CLASS_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param id			Player index.
 * @param classid		Internal ghost class ID.
 */
forward zp_fw_class_ghost_select_pre(id, classid)

/**
 * Called right after a player selects a class from the menu.
 *
 * @param id			Player index.
 * @param classid		Internal ghost class ID.
 */
forward zp_fw_class_ghost_select_post(id, classid)

/**
 * Returns whether a player is a Ghost.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_class_ghost_get(id)

/**
 * Forces a player to become a Ghost.
 *
 * @param id		Player index.
 * @param attacker	Player who triggered the infection. (optional)
 * @return			True on success, false otherwise.
 */
native zp_class_ghost_set(id, attacker = 0)

/**
 * Returns number of alive ghost.
 *
 * @return		Ghost count.
 */
native zp_class_ghost_get_alive_count()

/**
 * Returns a ghost class' infection.
 *
 * @param classid		A valid ghost class ID.
 * @return				True if it is allow infection, false otherwise.
 */
native zp_class_ghost_get_infection(classid)

/**
 * Returns a ghost class' primary attack interval.
 *
 * @param classid		A valid ghost class ID.
 * @return				Interval of primary attack.
 */
native Float:zp_get_primary_interval(classid)

/**
 * Returns a ghost class' secondary attack interval.
 *
 * @param classid		A valid ghost class ID.
 * @return				Interval of secondary attack.
 */
native Float:zp_get_secondary_interval(classid)

/**
 * Returns a ghost class' primary attack damage.
 *
 * @param classid		A valid ghost class ID.
 * @return				Damage of primary attack.
 */
native Float:zp_get_primary_damage(classid)

/**
 * Returns a ghost class' secondary attack damage.
 *
 * @param classid		A valid ghost class ID.
 * @return				Damage of secondary attack.
 */
native Float:zp_get_secondary_damage(classid)

/**
 * Returns a ghost class' blood.
 *
 * @param classid		A valid ghost class ID.
 * @return				True if it is allow blood, false otherwise.
 */
native zp_class_ghost_get_blood(classid)
