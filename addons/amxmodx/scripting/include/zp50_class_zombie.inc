#if defined _zp50_class_zombie_included
  #endinput
#endif
#define _zp50_class_zombie_included

#include <zp50_core>
#include <zp50_class_zombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_zombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_zombie
	#endif
#else
	#pragma library zp50_class_zombie
#endif

/**
 * Returns a player's current zombie class ID.
 *
 * @param id		Player index.
 * @return			Internal zombie class ID, or ZP_INVALID_ZOMBIE_CLASS if not yet chosen.
 */
native zp_class_zombie_get_current(id)

/**
 * Sets a player's current zombie class ID.
 *
 * @param id		Player index.
 * @param classid	A valid zombie class ID.
 * @return			True on success, false otherwise.
 */
native bool:zp_class_zombie_set_current(id, classid)

/**
 * Returns a player's next zombie class ID (for the next infection).
 *
 * @param id		Player index.
 * @return			Internal zombie class ID, or ZP_INVALID_ZOMBIE_CLASS if not yet chosen.
 */
native zp_class_zombie_get_next(id)

/**
 * Sets a player's next zombie class ID (for the next infection).
 *
 * @param id		Player index.
 * @param classid	A valid zombie class ID.
 * @return			True on success, false otherwise.
 */
native bool:zp_class_zombie_set_next(id, classid)

/**
 * Sets a player's next zombie class ID (for the next infection) only once.
 *
 * @param id		Player index.
 * @param classid	A valid zombie class ID.
 * @return			True on success, false otherwise.
 */
native bool:zp_class_zombie_set_next_once(id, classid)

/**
 * Returns the default maximum health for a specific zombie class.
 *
 * Note: does not take into account any kind of HP multipliers.
 *
 * @param id		Player index.
 * @return			Maximum amount of health points, -1 on error.
 */
native zp_class_zombie_get_max_health(id)

/**
 * Registers a custom class which will be added to the zombie classes menu of ZP.
 *
 * Note: The returned zombie class ID can be later used to identify
 * the class when calling the zp_get_user_zombie_class() natives.
 *
 * @param name			Caption to display on the menu.
 * @param description	Brief description of the class.
 * @param health		Class health.
 * @param speed			Class maxspeed (can be a multiplier).
 * @param gravity		Class gravity multiplier.
 * @param infection		Class allow infection.
 * @param blood			Class allow blood.
 * @return				An internal zombie class ID, or ZP_INVALID_ZOMBIE_CLASS on failure.
 */
native zp_class_zombie_register(const name[], const description[], health, Float:speed, Float:gravity, bool:infection = true, Float:speedPrimaryAttack = -1.0, Float:speedSecondaryAttack = -1.0, Float:damagePrimaryAttack = -1.0, Float:damageSecondaryAttack = -1.0, bool:blood = true, base_health = 1800)

/**
 * Registers a custom player model for a given zombie class.
 *
 * @param classid		A valid zombie class ID.
 * @param model			Player model's short name.
 * @return				True on success, false otherwise.
 */
native zp_class_zombie_register_model(classid, const model[])

/**
 * Registers a custom claw model for a given zombie class.
 *
 * @param classid		A valid zombie class ID.
 * @param clawmodel		Claw model filename.
 * @return				True on success, false otherwise.
 */
native zp_class_zombie_register_claw(classid, const clawmodel[])

/**
 * Registers a zombie class' knockback multiplier.
 *
 * @param classid		A valid zombie class ID.
 * @param knockback		Knockback multiplier.
 * @return				True on success, false otherwise.
 */
native zp_class_zombie_register_kb(classid, Float:knockback)

/**
 * Registers a zombie class' damage multiplier.
 *
 * @param classid			A valid zombie class ID.
 * @param damage_multiplier	Damage multiplier.
 * @return					True on success, false otherwise.
 */
native zp_class_zombie_register_dm(classid, Float:damage_multiplier)

/**
 * Returns a zombie class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal zombie class ID, or ZP_INVALID_ZOMBIE_CLASS if not found.
 */
native zp_class_zombie_get_id(const real_name[])

/**
 * Returns a zombie class' name.
 *
 * @param classid	A valid zombie class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_class_zombie_get_name(classid, name[], len)

/**
 * Returns a zombie class' real name (used when registering the class).
 *
 * @param classid	A valid zombie class ID.
 * @param name		The buffer to store the string in.
 * @param len		Character size of the output buffer.
 * @return			True on success, false otherwise.
 */
native zp_class_zombie_get_real_name(classid, real_name[], len)

/**
 * Returns a zombie class' description.
 *
 * @param classid		A valid zombie class ID.
 * @param description	The buffer to store the string in.
 * @param len			Character size of the output buffer.
 * @return				True on success, false otherwise.
 */
native zp_class_zombie_get_desc(classid, description[], len)

/**
 * Returns a zombie class' knockback multiplier.
 *
 * @param classid		A valid zombie class ID.
 * @return				Knockback multiplier (float value).
 */
native Float:zp_class_zombie_get_kb(classid)

/**
 * Returns a zombie class' damage multiplier.
 *
 * @param classid		A valid zombie class ID.
 * @return				Damage multiplier (float value).
 */
native Float:zp_class_zombie_get_dm(classid)

/**
 * Returns a zombie class' infection.
 *
 * @param classid		A valid zombie class ID.
 * @return				True if it is allow infection, false otherwise.
 */
native bool:zp_class_zombie_get_infection(classid)

/**
 * Returns a zombie class' primary attack interval.
 *
 * @param classid		A valid zombie class ID.
 * @return				Interval of primary attack.
 */
native Float:zp_class_zombie_get_pi(classid)

/**
 * Returns a zombie class' secondary attack interval.
 *
 * @param classid		A valid zombie class ID.
 * @return				Interval of secondary attack.
 */
native Float:zp_class_zombie_get_si(classid)

/**
 * Returns a zombie class' primary attack damage.
 *
 * @param classid		A valid zombie class ID.
 * @return				Damage of primary attack.
 */
native Float:zp_class_zombie_get_pd(classid)

/**
 * Returns a zombie class' secondary attack damage.
 *
 * @param classid		A valid zombie class ID.
 * @return				Damage of secondary attack.
 */
native Float:zp_class_zombie_get_sd(classid)

/**
 * Returns a zombie class' blood.
 *
 * @param classid		A valid zombie class ID.
 * @return				True if it is allow blood, false otherwise.
 */
native bool:zp_class_zombie_get_blood(classid)

/**
 * Returns number of registered zombie classes.
 *
 * @return			Zombie class count.
 */
native zp_class_zombie_get_count()

/**
 * Shows menu with available zombie classes to a player.
 *
 * @param id		Player index.
 */
native zp_class_zombie_show_menu(id)

/**
 * Appends text to a class being displayed on the zombie classes menu.
 * Use this on the class select pre forward.
 *
 * @param text		Additional text to display.
 */
native zp_class_zombie_menu_text_add(const text[])

/**
 * Called when determining whether a class should be available to a player.
 *
 * Possible return values are:
 *	- ZP_CLASS_AVAILABLE (show in menu, allow selection)
 *	- ZP_CLASS_NOT_AVAILABLE (show in menu, don't allow selection)
 *	- ZP_CLASS_DONT_SHOW (don't show in menu, don't allow selection)
 *
 * @param id			Player index.
 * @param classid		Internal zombie class ID.
 */
forward zp_fw_class_zombie_select_pre(id, classid)

/**
 * Called right after a player selects a class from the menu.
 *
 * @param id			Player index.
 * @param classid		Internal zombie class ID.
 */
forward zp_fw_class_zombie_select_post(id, classid)

/**
 * Called right when class menu show pre.
 *
 * Return PLUGIN_HANDLED to block
 *
 * @param id			Player index.
 */
forward zp_fw_class_zombie_menu_show_pre(id)

/**
 * Called right when class init.
 *
 * Possible return values are:
 *	- PLUGIN_HANDLED to block
 *
 * @param id			Player index.
 * @param classid		Internal zombie class ID.
 */
forward zp_fw_class_zombie_init_pre(id, classid)

/**
 * Called right when class inited.
 *
 * @param id			Player index.
 * @param classid		Internal zombie class ID.
 */
forward zp_fw_class_zombie_init_post(id, classid)