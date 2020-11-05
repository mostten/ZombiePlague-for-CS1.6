#if defined _zp50_gamemodes_infection_included
  #endinput
#endif
#define _zp50_gamemodes_infection_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_gamemodes_infection
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_gamemodes_infection
	#endif
#else
	#pragma library zp50_gamemodes_infection
#endif


/**
 * Called when a infection mode starts.
 *
 * @param first_zombie		Internal ID for the first zombie.
 */
forward zp_fw_infection_started(first_zombie);