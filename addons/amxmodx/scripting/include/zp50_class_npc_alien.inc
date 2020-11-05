#if defined _zp50_class_npc_alien_included
  #endinput
#endif
#define _zp50_class_npc_alien_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_class_npc_alien
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_class_npc_alien
	#endif
#else
	#pragma library zp50_class_npc_alien
#endif

/**
 * Returns whether a entity is a npc.
 *
 * @param entity	Entity index.
 * @return			True if it is, false otherwise.
 */
native bool:zp_npc_alien_get(entity);

/**
 * Returns number of alive npcs.
 *
 * @return		Npc count.
 */
native zp_npc_alien_get_count();

/**
 * Spawn a npc.
 *
 * @return				Npc index.
 */
native zp_npc_alien_spawn();
