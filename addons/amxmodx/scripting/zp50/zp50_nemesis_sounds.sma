#include <amxmodx>
#include <zp50_zombie_sounds>

#define SOUND_MAX_LENGTH 64

// nemesis sounds
new const sound_nemesis_pain[][] = { "zombie_plague/nemesis_pain1.wav" , "zombie_plague/nemesis_pain2.wav" , "zombie_plague/nemesis_pain3.wav" }
new const sound_nemesis_die[][] = { "zombie_plague/zombie_die1.wav" , "zombie_plague/zombie_die2.wav" , "zombie_plague/zombie_die3.wav" , "zombie_plague/zombie_die4.wav" , "zombie_plague/zombie_die5.wav" }
new const sound_nemesis_fall[][] = { "zombie_plague/zombie_fall1.wav" }
new const sound_nemesis_miss_slash[][] = { "zombie_plague/zaphie/claw/zombie_swing_1.wav" , "zombie_plague/zaphie/claw/zombie_swing_2.wav" }
new const sound_nemesis_miss_wall[][] = { "weapons/knife_hitwall1.wav" }
new const sound_nemesis_hit_normal[][] = { "weapons/knife_hit1.wav" , "weapons/knife_hit2.wav" , "weapons/knife_hit3.wav" , "weapons/knife_hit4.wav" }
new const sound_nemesis_hit_stab[][] = { "weapons/knife_stab.wav" }
new const sound_nemesis_idle[][] = { "nihilanth/nil_now_die.wav" , "nihilanth/nil_slaves.wav" , "nihilanth/nil_alone.wav" , "zombie_plague/zombie_brains1.wav" , "zombie_plague/zombie_brains2.wav" }
new const sound_nemesis_idle_last[][] = { "nihilanth/nil_thelast.wav" }
new const sound_nemesis_step[][] = { "player/pl_step1.wav" , "player/pl_step2.wav" , "player/pl_step3.wav" , "player/pl_step4.wav" }

public plugin_precache()
{
	register_plugin("[ZP] Sound: Nemesis", "0.1", "Mostten");
	
	new index;
	for (index = 0; index < sizeof sound_nemesis_pain; index++)
		zp_nemesis_register_sound(sound_nemesis_pain[index]);
	for (index = 0; index < sizeof sound_nemesis_die; index++)
		zp_nemesis_register_sound(_, sound_nemesis_die[index]);
	for (index = 0; index < sizeof sound_nemesis_fall; index++)
		zp_nemesis_register_sound(_, _, sound_nemesis_fall[index]);
	for (index = 0; index < sizeof sound_nemesis_miss_slash; index++)
		zp_nemesis_register_sound(_, _, _, sound_nemesis_miss_slash[index]);
	for (index = 0; index < sizeof sound_nemesis_miss_wall; index++)
		zp_nemesis_register_sound(_, _, _, _, sound_nemesis_miss_wall[index]);
	for (index = 0; index < sizeof sound_nemesis_hit_normal; index++)
		zp_nemesis_register_sound(_, _, _, _, _, sound_nemesis_hit_normal[index]);
	for (index = 0; index < sizeof sound_nemesis_hit_stab; index++)
		zp_nemesis_register_sound(_, _, _, _, _, _, sound_nemesis_hit_stab[index]);
	for (index = 0; index < sizeof sound_nemesis_idle; index++)
		zp_nemesis_register_sound(_, _, _, _, _, _, _, sound_nemesis_idle[index]);
	for (index = 0; index < sizeof sound_nemesis_idle_last; index++)
		zp_nemesis_register_sound(_, _, _, _, _, _, _, _, sound_nemesis_idle_last[index]);
	for (index = 0; index < sizeof sound_nemesis_step; index++)
		zp_nemesis_register_sound(_, _, _, _, _, _, _, _, _, _, sound_nemesis_step[index]);
}