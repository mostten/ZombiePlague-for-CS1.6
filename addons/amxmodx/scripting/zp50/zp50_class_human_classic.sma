/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Human: Classic -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_human>
#include <zp50_radio>

// Classic Human Attributes
new const humanclass1_name[] = "Classic Human"
new const humanclass1_info[] = "=Balanced="
new const humanclass1_models[][] = { "arctic" , "guerilla" , "leet" , "terror" , "gign" , "gsg9" , "sas" , "urban" }
const humanclass1_health = 100
const Float:humanclass1_speed = 1.0
const Float:humanclass1_gravity = 1.0

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Classic", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_HumanClassID = zp_class_human_register(humanclass1_name, humanclass1_info, humanclass1_health, humanclass1_speed, humanclass1_gravity)
	new index
	for (index = 0; index < sizeof humanclass1_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass1_models[index])
	
	// 注册无线电音频
	//zp_radio_reg_human("test name", false, "hello test", false, "zombie_plague/zombie_pain1.wav", RadioMenu_1, g_HumanClassID);
	
	// 替换原版手雷无线电
	//zp_radio_replace_human(RADIO_FIREINHOLE, "zombie_plague/zombie_pain1.wav", g_HumanClassID);
}
