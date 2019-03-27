#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fun>
#include <basebuilder>
#include <fakemeta>
#include <eG>
#include <hamsandwich>
#include <xs>
#include <dhudmessage>

#define BOSS_ALARM	"basebuilder/FAITH/Boss_Alarm.wav" // Alarm Sound

native zp_override_user_model(id, const newmodel[], modelindex = 0)

new const boss_skill_name[][] = { "", "【无敌】", "【暴走】", "【长跳】", "【高跳】", "【隐身】", "【祈愿】" }
new const boss_skill_inf[][] = { "", "免疫所有伤害 5 秒", "短时间内速度暴增", "往准心方向飞扑", "向上飞超高距离", "隐身 5 秒", "所有僵尸恢复 2500 血量" }
new const boss_skill_cost[] = { 0, 555, 333, 333, 444, 555, 666 }
new const boss_skill_sound[][] = { "", "basebuilder/FAITH/nemesis/nemesisgodmode.wav", "basebuilder/FAITH/nemesis/nemesisgodmode.wav", "basebuilder/FAITH/Hunter_LJump1.wav", "basebuilder/FAITH/Hunter_LJump1.wav", "", "basebuilder/FAITH/Zombie_Regain.wav" }

#define	TASK_BOSS_SKILL_COUNTDOWN 100
#define TASK_OFF_SKILL 150

new bool:g_bIsBoss[33]
new g_iBossCountdown[33]
new g_msg[256]

public client_connected(id)
{
	g_bIsBoss[id] = false
	g_iBossCountdown[id] = 0
}

public plugin_precache()
{
	// -- Combiner
	precache_model("models/player/bb_combiner_f/bb_combiner_f.mdl")
	precache_model("models/v_depredador_claws.mdl")
	precache_sound("basebuilder/FAITH/nemesis/nemesisgodmode.wav")
	precache_sound("basebuilder/FAITH/Hunter_LJump1.wav")
	precache_sound("basebuilder/FAITH/Zombie_Regain.wav")

	register_plugin("[BB] Boss: Combiner", "1.0", "EmeraldGhost")
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_Spawn, "player", "fwHam_spawn", 1)

	//register_clcmd("eg_testboss", "Become_Boss")
}

public plugin_natives()
{
	register_native("bb_combiner_me", "Native_Become_Nemesis", 1)
}

public Native_Become_Nemesis(id) Become_Boss(id)

public Become_Boss(id)
{
	new players_ct[32], ict
	get_players(players_ct,ict,"ae","CT")

	g_bIsBoss[id] = true
	set_task(0.5, "boss_skill_reload", id + TASK_BOSS_SKILL_COUNTDOWN, _, _, "b")
	
	set_pev(id, pev_viewmodel2, "models/v_depredador_claws.mdl")
	set_pev(id, pev_weaponmodel2, "")
	zp_override_user_model(id, "bb_combiner_f")
	
	give_item(id, "item_assaultsuit");
	cs_set_user_armor(id, 500, CS_ARMOR_VESTHELM);
	
	set_user_health(id, ict * 10125 + 2500)
	set_user_maxspeed(id, 270 * 1.0)
	set_user_gravity(id, 0.8)
}

public fwHam_spawn(id)
{
	remove_task(id + TASK_BOSS_SKILL_COUNTDOWN)
	g_iBossCountdown[id] = 0
	
	if(g_bIsBoss[id])
	{
		g_bIsBoss[id] = false
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
		set_pev(id, pev_weaponmodel2, "")
	}
}

public boss_skill_reload(taskid)
{
	new id = taskid - TASK_BOSS_SKILL_COUNTDOWN
	if(is_user_alive(id) && is_user_connected(id))
	{
		if(g_iBossCountdown[id] >= 888)
        {
			g_iBossCountdown[id] = 888
			client_print(id, print_center, "【 Reload 完成丨按 'R' 选择技能】")
        }
		else
		{
			g_iBossCountdown[id] += 18
			client_print(id, print_center, "【 Reload: %d / 888丨按 'R' 选择技能】", g_iBossCountdown[id])
		}
	}
}

public boss_skill(id)
{
	if(!is_user_alive(id) || get_user_team(id) != 1 || !g_bIsBoss[id])
	return PLUGIN_CONTINUE
	
	new szTempid[32]
	new menu = menu_create("\rCombiner - 技能系统", "boss_skill2")
	
	for(new i = 1; i < sizeof boss_skill_name; i++)
	{
		new szItems[101]
		formatex(szItems, 100, "\r%s \y%s \d%d", boss_skill_name[i], boss_skill_inf[i], boss_skill_cost[i])
		num_to_str(i, szTempid, 31)
		menu_additem(menu, szItems, szTempid, 0)
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED
}

public boss_skill2(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id))
	return PLUGIN_HANDLED
	
	new data[6], iName[64]
	new access, callback
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback)
	
	new i = str_to_num(data)
	
		if(g_iBossCountdown[id] >= boss_skill_cost[i])
		{
			new name[33]
			get_user_name(id, name, 32)
			
			if(i == 1) skill_godmode(id)
			else if(i == 2) skill_speed(id)
			else if(i == 3) skill_ljump(id)
			else if(i == 4) skill_hjump(id)
			else if(i == 5) skill_invisible(id)
			else if(i == 6) skill_pray(id)
			
			format(g_msg, charsmax(g_msg), "Combiner「%s」发动技能 %s^n%s", name, boss_skill_name[i], boss_skill_inf[i])
			event_hud(0, 0, 255, 255, g_msg)
			g_iBossCountdown[id] -= boss_skill_cost[i]
			
			if(i != 5) client_cmd(0, "spk %s", boss_skill_sound[i])
		}
		else client_printc(id, "\y[\g技能系统\y] \gReload \y不足, 无法使用技能!")
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public skill_godmode(id)
{
	new name[33]
	get_user_name(id, name, 32)
	
	set_user_godmode(id, 1)
	set_user_rendering(id, kRenderFxGlowShell, 0, 255, 255, kRenderNormal, 3)
	set_task(5.0, "off_skill", id + TASK_OFF_SKILL)
}

public skill_speed(id)
{
	new name[33]
	get_user_name(id, name, 32)

	set_user_maxspeed(id, 270 * 1.5)
	set_user_rendering(id, kRenderFxGlowShell, 128, 128, 0, kRenderNormal, 3)
	set_task(5.0, "off_skill", id + TASK_OFF_SKILL)
}

public skill_hjump(id)
{
	static Float:velocity[3]
	velocity_by_aim(id, 100, velocity)
	velocity[2] = 3000.0
	set_pev(id, pev_velocity, velocity)
	set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 3)
	set_task(2.0, "off_skill", id + TASK_OFF_SKILL)
}

public skill_ljump(id)
{
	new Float:velocity[3]
	velocity_by_aim(id, 800, velocity)
	velocity[2] = 300.0
	set_pev(id, pev_velocity, velocity)
	set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 3)
	set_task(2.0, "off_skill", id + TASK_OFF_SKILL)
}

public skill_invisible(id)
{
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha,0)
	set_task(5.0, "off_skill", id + TASK_OFF_SKILL)
}

public skill_pray(id)
{
	for (new i = 1; i <= 33; i++)
	{
		if(is_user_connected(i) && is_user_alive(i) && (i != id) && get_user_team(i) == 1)
		{
			set_user_health(i, get_user_health(i) + 2500)
		}
	}
}

public off_skill(taskid)
{
	new id = taskid - TASK_OFF_SKILL
	
	if(is_user_alive(id) && is_user_connected(id))
	{
		set_user_godmode(id)
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
		set_user_maxspeed(id, 270 * 1.0)
		set_user_gravity(id, 0.8)
	}
}

public fw_CmdStart(id, uc_handle, seed) 
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;

	static button, oldbutton
	button = get_uc(uc_handle, UC_Buttons)
	oldbutton = pev(id, pev_oldbuttons)
	
	if ((button & IN_RELOAD) && !(oldbutton & IN_RELOAD))
	{
		if(zp_get_user_zombie(id) && is_user_alive(id) && g_bIsBoss[id])
		{
			boss_skill(id)
		}
	}
	return PLUGIN_HANDLED 
}

stock event_hud(index, red, green, blue, msg[])
{
	set_dhudmessage(red, green, blue, -1.0, 0.2, 0, 0.0, 2.0, 0.1, 0.1)
	show_dhudmessage(index, msg)
}
