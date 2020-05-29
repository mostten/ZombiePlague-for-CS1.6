#if defined _zp50_ambience_effects_included
  #endinput
#endif
#define _zp50_ambience_effects_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_ambience_effects
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_ambience_effects
	#endif
#else
	#pragma library zp50_ambience_effects
#endif

enum Ambience_Weather{
	Weather_Sunny = 0,
	Weather_Rain,
	Weather_Snow
};

/**
 * Returns Weather.
 */
native Ambience_Weather:zp_ambience_get_weather();