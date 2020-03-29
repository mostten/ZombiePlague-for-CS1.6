#if defined _zp50_zombie_sounds_included
  #endinput
#endif
#define _zp50_zombie_sounds_included

#include <zp50_zsounds_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_zombie_sounds
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_zombie_sounds
	#endif
#else
	#pragma library zp50_zombie_sounds
#endif

/**
 * Registers a custom sounds which will be added to the zombie sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param zombie_class		class id.
 * @param sound_pain		pain.
 * @param sound_die			die.
 * @param sound_fall		fall.
 * @param sound_miss_slash	miss slash.
 * @param sound_miss_wall	miss wall.
 * @param sound_hit_normal	hit normal.
 * @param sound_hit_stab	hit stab.
 * @param sound_idle		idle.
 * @param sound_idle_last	idle last.
 * @return					An internal zombie sounds ID, or ZP_INVALID_SOUND_CLASS on failure.
 */
native zp_zombie_sound_register(zombie_class, Array:sound_pain, Array:sound_die, Array:sound_fall, Array:sound_miss_slash, Array:sound_miss_wall, Array:sound_hit_normal, Array:sound_hit_stab, Array:sound_idle, Array:sound_idle_last);

/**
 * Registers a custom sounds which will be added to the ghost sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param ghost_class		class id.
 * @param sound_pain		pain.
 * @param sound_die			die.
 * @param sound_fall		fall.
 * @param sound_miss_slash	miss slash.
 * @param sound_miss_wall	miss wall.
 * @param sound_hit_normal	hit normal.
 * @param sound_hit_stab	hit stab.
 * @param sound_idle		idle.
 * @param sound_idle_last	idle last.
 * @return					An internal ghost sounds ID, or ZP_INVALID_SOUND_CLASS on failure.
 */
native zp_ghost_sound_register(ghost_class, Array:sound_pain, Array:sound_die, Array:sound_fall, Array:sound_miss_slash, Array:sound_miss_wall, Array:sound_hit_normal, Array:sound_hit_stab, Array:sound_idle, Array:sound_idle_last);

/**
 * Registers a custom sounds which will be added to the human sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param human_class		class id.
 * @param sound_pain		pain.
 * @param sound_die			die.
 * @param sound_fall		fall.
 * @param sound_miss_slash	miss slash.
 * @param sound_miss_wall	miss wall.
 * @param sound_hit_normal	hit normal.
 * @param sound_hit_stab	hit stab.
 * @return					An internal human sounds ID, or ZP_INVALID_SOUND_CLASS on failure.
 */
native zp_human_sound_register(human_class, Array:sound_pain, Array:sound_die, Array:sound_fall, Array:sound_miss_slash, Array:sound_miss_wall, Array:sound_hit_normal, Array:sound_hit_stab);

/**
 * Registers a custom sounds which will be added to the survivor sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param survivor_class		class id.
 * @param sound_pain		pain.
 * @param sound_die			die.
 * @param sound_fall		fall.
 * @param sound_miss_slash	miss slash.
 * @param sound_miss_wall	miss wall.
 * @param sound_hit_normal	hit normal.
 * @param sound_hit_stab	hit stab.
 * @return					An internal survivor sounds ID, or ZP_INVALID_SOUND_CLASS on failure.
 */
native zp_survivor_sound_register(survivor_class, Array:sound_pain, Array:sound_die, Array:sound_fall, Array:sound_miss_slash, Array:sound_miss_wall, Array:sound_hit_normal, Array:sound_hit_stab);

/**
 * Registers a custom sounds which will be added to the nemesis sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param nemesis_class		class id.
 * @param sound_pain		pain.
 * @param sound_die			die.
 * @param sound_fall		fall.
 * @param sound_miss_slash	miss slash.
 * @param sound_miss_wall	miss wall.
 * @param sound_hit_normal	hit normal.
 * @param sound_hit_stab	hit stab.
 * @param sound_idle		idle.
 * @param sound_idle_last	idle last.
 * @return					An internal nemesis sounds ID, or ZP_INVALID_SOUND_CLASS on failure.
 */
native zp_nemesis_sound_register(nemesis_class, Array:sound_pain, Array:sound_die, Array:sound_fall, Array:sound_miss_slash, Array:sound_miss_wall, Array:sound_hit_normal, Array:sound_hit_stab, Array:sound_idle, Array:sound_idle_last);




