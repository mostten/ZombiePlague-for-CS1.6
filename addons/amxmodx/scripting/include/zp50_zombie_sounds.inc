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
 * @param zombie_class	class id.
 * @param pain			sound pain.
 * @param die			sound die.
 * @param fall			sound fall.
 * @param miss_slash	sound miss slash.
 * @param miss_wall		sound miss wall.
 * @param hit_normal	sound hit normal.
 * @param hit_stab		sound hit stab.
 * @param idle			sound idle.
 * @param idle_last		sound idle last.
 * @param head_shot		sound head shot
 * @param step			sound step
 */
native zp_zombie_register_sound(zombie_class, const pain[] = "", const die[] = "", const fall[] = "", const miss_slash[] = "", const miss_wall[] = "", const hit_normal[] = "", const hit_stab[] = "", const idle[] = "", const idle_last[] = "", const head_shot[] = "", const step[] = "");

/**
 * Registers a custom sounds which will be added to the human sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param human_class	class id.
 * @param pain			sound pain.
 * @param die			sound die.
 * @param fall			sound fall.
 * @param miss_slash	sound miss slash.
 * @param miss_wall		sound miss wall.
 * @param hit_normal	sound hit normal.
 * @param hit_stab		sound hit stab.
 * @param head_shot		sound head shot
 * @param step			sound step
 */
native zp_human_register_sound(human_class, const pain[] = "", const die[] = "", const fall[] = "", const miss_slash[] = "", const miss_wall[] = "", const hit_normal[] = "", const hit_stab[] = "", const head_shot[] = "", const step[] = "");

/**
 * Registers a custom sounds which will be added to the survivor sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param pain			sound pain.
 * @param die			sound die.
 * @param fall			sound fall.
 * @param miss_slash	sound miss slash.
 * @param miss_wall		sound miss wall.
 * @param hit_normal	sound hit normal.
 * @param hit_stab		sound hit stab.
 * @param head_shot		sound head shot
 * @param step			sound step
 */
native zp_survivor_register_sound(const pain[] = "", const die[] = "", const fall[] = "", const miss_slash[] = "", const miss_wall[] = "", const hit_normal[] = "", const hit_stab[] = "", const head_shot[] = "", const step[] = "");

/**
 * Registers a custom sounds which will be added to the nemesis sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param pain			sound pain.
 * @param die			sound die.
 * @param fall			sound fall.
 * @param miss_slash	sound miss slash.
 * @param miss_wall		sound miss wall.
 * @param hit_normal	sound hit normal.
 * @param hit_stab		sound hit stab.
 * @param idle			sound idle.
 * @param idle_last		sound idle last.
 * @param head_shot		sound head shot
 * @param step			sound step
 */
native zp_nemesis_register_sound(const pain[] = "", const die[] = "", const fall[] = "", const miss_slash[] = "", const miss_wall[] = "", const hit_normal[] = "", const hit_stab[] = "", const idle[] = "", const idle_last[] = "", const head_shot[] = "", const step[] = "");
