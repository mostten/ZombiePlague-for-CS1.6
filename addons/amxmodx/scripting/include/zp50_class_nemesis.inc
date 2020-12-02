#if defined _zp50_class_nemesis_included
  #endinput
#endif
#define _zp50_class_nemesis_included

#include <zp50_class_zombie>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_nemesis
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_nemesis
	#endif
#else
	#pragma library zp50_class_nemesis
#endif


/**
 * Returns whether a player is a Nemesis.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_class_nemesis_get(id)

/**
 * Forces a player to become a Nemesis.
 *
 * @param id		Player index.
 * @return			True on success, false otherwise.
 */
native zp_class_nemesis_set(id)

/**
 * Returns a nemesis class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal nemesis class ID, or ZP_INVALID_ZOMBIE_CLASS if it's unvalid.
 */
native zp_class_nemesis_get_classid();

/**
 * Returns number of alive nemesis.
 *
 * @return		Nemesis count.
 */
native zp_class_nemesis_get_count()

/**
 * Returns the default maximum health for nemesis.
 *
 * Note: does not take into account any kind of HP multipliers.
 *
 * @param id		Player index.
 * @return			Maximum amount of health points, -1 on error.
 */
native zp_class_nemesis_get_maxhealth(id)

/**
 * Called right when class init.
 *
 * Possible return values are:
 *	- PLUGIN_HANDLED to block
 *
 * @param id			Player index.
 * @param classid		Internal nemesis class ID.
 */
forward zp_fw_nemesis_init_pre(id, classid);

/**
 * Called right when class inited.
 *
 * @param id			Player index.
 * @param classid		Internal nemesis class ID.
 */
forward zp_fw_nemesis_init_post(id, classid);