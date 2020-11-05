#if defined _zp50_radio_included
  #endinput
#endif
#define _zp50_radio_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_radio
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_radio
	#endif
#else
	#pragma library zp50_radio
#endif

// radio sounds for zp_radio_replace_* first arg
#define RADIO_GETINPOS "%!MRAD_GETINPOS"
#define RADIO_GO "%!MRAD_GO"
#define RADIO_REPORTIN "%!MRAD_REPORTIN"
#define RADIO_FOLLOWCOM "%!MRAD_FOLLOWCOM"
#define RADIO_AFFIRM "%!MRAD_AFFIRM"
#define RADIO_BACKUP "%!MRAD_BACKUP"
#define RADIO_COVERME "%!MRAD_COVERME"
#define RADIO_ENEMYSPOT "%!MRAD_ENEMYSPOT"
#define RADIO_FIREINHOLE "%!MRAD_FIREINHOLE"
#define RADIO_IMHIT "%!MRAD_IMHIT"
#define RADIO_INPOS "%!MRAD_INPOS"
#define RADIO_POINT "%!MRAD_POINT"
#define RADIO_REPRTINGIN "%!MRAD_REPRTINGIN"

#define RADIO_CTWIN "%!MRAD_CTWIN"
#define RADIO_HOSDOWN "%!MRAD_HOSDOWN"
#define RADIO_LETSGO "%!MRAD_LETSGO"
#define RADIO_LOCKNLOAD "%!MRAD_LOCKNLOAD"
#define RADIO_MATEDOWN "%!MRAD_MATEDOWN"
#define RADIO_MOVEOUT "%!MRAD_MOVEOUT"
#define RADIO_RESCUED "%!MRAD_RESCUED"
#define RADIO_ROGER "%!MRAD_ROGER"
#define RADIO_TERWIN "%!MRAD_TERWIN"
#define RADIO_ENEMYDOWN "%!MRAD_ENEMYDOWN"
#define RADIO_ROUNDDRAW "%!MRAD_ROUNDDRAW"
#define RADIO_ELIM "%!MRAD_ELIM"
#define RADIO_GETOUT "%!MRAD_GETOUT"
#define RADIO_VIP "%!MRAD_VIP"

#define RADIO_BLOW "%!MRAD_BLOW"
#define RADIO_BOMBDEF "%!MRAD_BOMBDEF"
#define RADIO_BOMBPL "%!MRAD_BOMBPL"
#define RADIO_CLEAR "%!MRAD_CLEAR"
#define RADIO_FALLBACK "%!MRAD_FALLBACK"
#define RADIO_GOGOGO "%!MRAD_GOGOGO"
#define RADIO_HITASSIST "%!MRAD_HITASSIST"
#define RADIO_REGROUP "%!MRAD_REGROUP"
#define RADIO_STICKTOG "%!MRAD_STICKTOG"

#define RADIO_TAKEPOINT "%!MRAD_TAKEPOINT"
#define RADIO_POSITION "%!MRAD_POSITION"
#define RADIO_CIRCLEBACK "%!MRAD_CIRCLEBACK"
#define RADIO_FOLLOWME "%!MRAD_FOLLOWME"
#define RADIO_MEETME "%!MRAD_MEETME"
#define RADIO_STORMFRONT "%!MRAD_STORMFRONTv"
#define RADIO_NEGATIVE "%!MRAD_NEGATIVE"

// Radio buttons(z, x, c)
enum RadioMenu{
	RadioMenu_1 = 0,
	RadioMenu_2,
	RadioMenu_3
};

native bool:zp_radio_reg_zombie(const name[], bool:name_trans, const message[], bool:message_trans, const sound[], RadioMenu:radio_menu, classid);
native bool:zp_radio_reg_human(const name[], bool:name_trans, const message[], bool:message_trans, const sound[], RadioMenu:radio_menu, classid);
native bool:zp_radio_reg_nemesis(const name[], bool:name_trans, const message[], bool:message_trans, const sound[], RadioMenu:radio_menu);
native bool:zp_radio_reg_survivor(const name[], bool:name_trans, const message[], bool:message_trans, const sound[], RadioMenu:radio_menu);

native bool:zp_radio_replace_zombie(const search[] = RADIO_FIREINHOLE, const replace[], classid);
native bool:zp_radio_replace_human(const search[] = RADIO_FIREINHOLE, const replace[], classid);
native bool:zp_radio_replace_nemesis(const search[] = RADIO_FIREINHOLE, const replace[]);
native bool:zp_radio_replace_survivor(const search[] = RADIO_FIREINHOLE, const replace[]);