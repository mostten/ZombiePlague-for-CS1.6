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
 * @param zombie_class			class id.
 * @param sound_pain			pain.
 * @param sound_die				die.
 * @param sound_fall			fall.
 * @param sound_miss_slash		miss slash.
 * @param sound_miss_wall		miss wall.
 * @param sound_hit_normal		hit normal.
 * @param sound_hit_stab		hit stab.
 * @param sound_idle			idle.
 * @param sound_idle_last		idle last.
 * @param sound_head_shot		head shot
 * @param sound_step			step
 */
native zp_zombie_sound_register(zombie_class, Array:sound_pain = Invalid_Array, Array:sound_die = Invalid_Array, Array:sound_fall = Invalid_Array, Array:sound_miss_slash = Invalid_Array, Array:sound_miss_wall = Invalid_Array, Array:sound_hit_normal = Invalid_Array, Array:sound_hit_stab = Invalid_Array, Array:sound_idle = Invalid_Array, Array:sound_idle_last = Invalid_Array, Array:sound_head_shot = Invalid_Array, Array:sound_step = Invalid_Array);

/**
 * Registers a custom sounds which will be added to the ghost sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param ghost_class			class id.
 * @param sound_pain			pain.
 * @param sound_die				die.
 * @param sound_fall			fall.
 * @param sound_miss_slash		miss slash.
 * @param sound_miss_wall		miss wall.
 * @param sound_hit_normal		hit normal.
 * @param sound_hit_stab		hit stab.
 * @param sound_idle			idle.
 * @param sound_idle_last		idle last.
 * @param sound_head_shot		head shot
 * @param sound_step			step
 */
native zp_ghost_sound_register(ghost_class, Array:sound_pain = Invalid_Array, Array:sound_die = Invalid_Array, Array:sound_fall = Invalid_Array, Array:sound_miss_slash = Invalid_Array, Array:sound_miss_wall = Invalid_Array, Array:sound_hit_normal = Invalid_Array, Array:sound_hit_stab = Invalid_Array, Array:sound_idle = Invalid_Array, Array:sound_idle_last = Invalid_Array, Array:sound_head_shot = Invalid_Array, Array:sound_step = Invalid_Array);

/**
 * Registers a custom sounds which will be added to the human sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param human_class			class id.
 * @param sound_pain			pain.
 * @param sound_die				die.
 * @param sound_fall			fall.
 * @param sound_miss_slash		miss slash.
 * @param sound_miss_wall		miss wall.
 * @param sound_hit_normal		hit normal.
 * @param sound_hit_stab		hit stab.
 * @param sound_head_shot		head shot
 * @param sound_step			step
 */
native zp_human_sound_register(human_class, Array:sound_pain = Invalid_Array, Array:sound_die = Invalid_Array, Array:sound_fall = Invalid_Array, Array:sound_miss_slash = Invalid_Array, Array:sound_miss_wall = Invalid_Array, Array:sound_hit_normal = Invalid_Array, Array:sound_hit_stab = Invalid_Array, Array:sound_head_shot = Invalid_Array, Array:sound_step = Invalid_Array);

/**
 * Registers a custom sounds which will be added to the survivor sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param sound_pain			pain.
 * @param sound_die				die.
 * @param sound_fall			fall.
 * @param sound_miss_slash		miss slash.
 * @param sound_miss_wall		miss wall.
 * @param sound_hit_normal		hit normal.
 * @param sound_hit_stab		hit stab.
 * @param sound_head_shot		head shot
 * @param sound_step			step
 */
native zp_survivor_sound_register(Array:sound_pain = Invalid_Array, Array:sound_die = Invalid_Array, Array:sound_fall = Invalid_Array, Array:sound_miss_slash = Invalid_Array, Array:sound_miss_wall = Invalid_Array, Array:sound_hit_normal = Invalid_Array, Array:sound_hit_stab = Invalid_Array, Array:sound_head_shot = Invalid_Array, Array:sound_step = Invalid_Array);

/**
 * Registers a custom sounds which will be added to the nemesis sounds of ZP.
 *
 * Note: The returned sounds ID can be later used to identify
 *
 * @param sound_pain			pain.
 * @param sound_die				die.
 * @param sound_fall			fall.
 * @param sound_miss_slash		miss slash.
 * @param sound_miss_wall		miss wall.
 * @param sound_hit_normal		hit normal.
 * @param sound_hit_stab		hit stab.
 * @param sound_idle			idle.
 * @param sound_idle_last		idle last.
 * @param sound_head_shot		head shot
 * @param sound_step			step
 */
native zp_nemesis_sound_register(Array:sound_pain = Invalid_Array, Array:sound_die = Invalid_Array, Array:sound_fall = Invalid_Array, Array:sound_miss_slash = Invalid_Array, Array:sound_miss_wall = Invalid_Array, Array:sound_hit_normal = Invalid_Array, Array:sound_hit_stab = Invalid_Array, Array:sound_idle = Invalid_Array, Array:sound_idle_last = Invalid_Array, Array:sound_head_shot = Invalid_Array, Array:sound_step = Invalid_Array);




