#if defined _zp50_class_zaphie_included
  #endinput
#endif
#define _zp50_class_zaphie_included

#include <zp50_core>
#include <zp50_class_zombie>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_zaphie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_zaphie
	#endif
#else
	#pragma library zp50_class_zaphie
#endif


/**
 * Returns whether a player is a Zaphie.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_class_zaphie_get(id);

/**
 * Forces a player to become a Zaphie.
 *
 * @param id		Player index.
 * @return			True on success, false otherwise.
 */
native zp_class_zaphie_set(id);

/**
 * Returns a zaphie class' ID.
 *
 * @param name		Class name to look for.
 * @return			Internal zaphie class ID, or ZP_INVALID_ZOMBIE_CLASS if it's unvalid.
 */
native zp_class_zaphie_get_classid();

/**
 * Returns number of alive zaphie.
 *
 * @return		Zaphie count.
 */
native zp_class_zaphie_get_count();