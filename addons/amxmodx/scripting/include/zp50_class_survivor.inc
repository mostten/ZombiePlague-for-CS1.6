#if defined _zp50_class_survivor_included
  #endinput
#endif
#define _zp50_class_survivor_included

#include <zp50_class_human>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_survivor
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_survivor
	#endif
#else
	#pragma library zp50_class_survivor
#endif


/**
 * Returns whether a player is a Survivor.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_class_survivor_get(id)

/**
 * Forces a player to become a Survivor.
 *
 * @param id		Player index.
 * @return			True on success, false otherwise.
 */
native zp_class_survivor_set(id)

/**
 * Returns a survivor class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal survivor class ID, or ZP_INVALID_HUMAN_CLASS if it's unvalid.
 */
native zp_class_survivor_get_classid();

/**
 * Returns number of alive survivors.
 *
 * @return		Survivor count.
 */
native zp_class_survivor_get_count()

/**
 * Returns the default maximum health for survivor.
 *
 * Note: does not take into account any kind of HP multipliers.
 *
 * @param id		Player index.
 * @return			Maximum amount of health points, -1 on error.
 */
native zp_class_survivor_get_maxhealth(id)
