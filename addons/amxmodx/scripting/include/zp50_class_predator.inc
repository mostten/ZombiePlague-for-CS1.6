#if defined _zp50_class_predator_included
  #endinput
#endif
#define _zp50_class_predator_included

#include <zp50_core>
#include <zp50_class_zombie>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_predator
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_predator
	#endif
#else
	#pragma library zp50_class_predator
#endif


/**
 * Returns whether a player is a Predator.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_class_predator_get(id);

/**
 * Forces a player to become a Predator.
 *
 * @param id		Player index.
 * @return			True on success, false otherwise.
 */
native zp_class_predator_set(id);

/**
 * Returns number of alive predator.
 *
 * @return		Predator count.
 */
native zp_class_predator_get_count();

/**
 * Called right when class init.
 *
 * Possible return values are:
 *	- PLUGIN_HANDLED to block
 *
 * @param id			Player index.
 * @param classid		Internal predator class ID.
 */
forward zp_fw_predator_init_pre(id, classid);

/**
 * Called right when class inited.
 *
 * @param id			Player index.
 * @param classid		Internal predator class ID.
 */
forward zp_fw_predator_init_post(id, classid);