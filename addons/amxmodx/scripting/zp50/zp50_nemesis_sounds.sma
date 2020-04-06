#include <amxmodx>
#include <zp50_zombie_sounds>

#define SOUND_MAX_LENGTH 64

// nemesis sounds
new const sound_nemesis_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_nemesis_die[][] = { "zombie_plague/zombie_die1.wav" , "zombie_plague/zombie_die2.wav" , "zombie_plague/zombie_die3.wav" , "zombie_plague/zombie_die4.wav" , "zombie_plague/zombie_die5.wav" }
new const sound_nemesis_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_nemesis_miss_slash[][] = { "zombie_plague/ghost/claw/zombie_swing_1.wav" , "zombie_plague/ghost/claw/zombie_swing_2.wav" }
new const sound_nemesis_miss_wall[][] = { "weapons/knife_hitwall1.wav" }
new const sound_nemesis_hit_normal[][] = { "weapons/knife_hit1.wav" , "weapons/knife_hit2.wav" , "weapons/knife_hit3.wav" , "weapons/knife_hit4.wav" }
new const sound_nemesis_hit_stab[][] = { "weapons/knife_stab.wav" }
new const sound_nemesis_idle[][] = { "nihilanth/nil_now_die.wav" , "nihilanth/nil_slaves.wav" , "nihilanth/nil_alone.wav" , "zombie_plague/zombie_brains1.wav" , "zombie_plague/zombie_brains2.wav" }
new const sound_nemesis_idle_last[][] = { "nihilanth/nil_thelast.wav" }
new const sound_nemesis_step[][] = { "player/pl_step1.wav" , "player/pl_step2.wav" , "player/pl_step3.wav" , "player/pl_step4.wav" }

public plugin_precache()
{
	register_plugin("[ZP] Sound: Nemesis", "0.1", "Mostten");
	
	new Array:nemesis_pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_die = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_fall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_miss_slash = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_miss_wall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_hit_normal = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_hit_stab = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_idle = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_idle_last = ArrayCreate(SOUND_MAX_LENGTH, 1);
	new Array:nemesis_step = ArrayCreate(SOUND_MAX_LENGTH, 1);
	
	new index;
	for (index = 0; index < sizeof sound_nemesis_pain; index++)
		ArrayPushString(nemesis_pain, sound_nemesis_pain[index])
	for (index = 0; index < sizeof sound_nemesis_die; index++)
		ArrayPushString(nemesis_die, sound_nemesis_die[index])
	for (index = 0; index < sizeof sound_nemesis_fall; index++)
		ArrayPushString(nemesis_fall, sound_nemesis_fall[index])
	for (index = 0; index < sizeof sound_nemesis_miss_slash; index++)
		ArrayPushString(nemesis_miss_slash, sound_nemesis_miss_slash[index])
	for (index = 0; index < sizeof sound_nemesis_miss_wall; index++)
		ArrayPushString(nemesis_miss_wall, sound_nemesis_miss_wall[index])
	for (index = 0; index < sizeof sound_nemesis_hit_normal; index++)
		ArrayPushString(nemesis_hit_normal, sound_nemesis_hit_normal[index])
	for (index = 0; index < sizeof sound_nemesis_hit_stab; index++)
		ArrayPushString(nemesis_hit_stab, sound_nemesis_hit_stab[index])
	for (index = 0; index < sizeof sound_nemesis_idle; index++)
		ArrayPushString(nemesis_idle, sound_nemesis_idle[index])
	for (index = 0; index < sizeof sound_nemesis_idle_last; index++)
		ArrayPushString(nemesis_idle_last, sound_nemesis_idle_last[index])
	for (index = 0; index < sizeof sound_nemesis_step; index++)
		ArrayPushString(nemesis_step, sound_nemesis_step[index])
	
	zp_nemesis_sound_register(nemesis_pain, nemesis_die, nemesis_fall, nemesis_miss_slash, nemesis_miss_wall, nemesis_hit_normal, nemesis_hit_stab, nemesis_idle, nemesis_idle_last, Invalid_Array, nemesis_step);
	
	ArrayDestroy(nemesis_pain);
	ArrayDestroy(nemesis_die);
	ArrayDestroy(nemesis_fall);
	ArrayDestroy(nemesis_miss_slash);
	ArrayDestroy(nemesis_miss_wall);
	ArrayDestroy(nemesis_hit_normal);
	ArrayDestroy(nemesis_hit_stab);
	ArrayDestroy(nemesis_idle);
	ArrayDestroy(nemesis_idle_last);
	ArrayDestroy(nemesis_step);
}