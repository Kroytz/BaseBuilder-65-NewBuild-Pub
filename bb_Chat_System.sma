#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <nvault>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <eG>
#include <dbi>

#define PLUGIN	"[eG] Chat System"
#define AUTHOR	"EmeraldGhost"
#define VERSION	"1.0"

native zp_donater_get_level(id)

new Sql:sql
new Result:result
new error[33]

new g_msg[201]
new bool:g_bHide[33]

new iSpecialMsg[33]

new const player_type[][] = { "玩家", "贵宾", "管理", "高层", "服主" }
new const special_msg[][] = { "null", "天殇服主", "天殇人员", "毛线老公", "A B老婆", "奔跑哥" } // 1, 2天殇, 3ab, 4毛线, 5跑鸡

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
	register_clcmd("say", "chat_system")
	register_clcmd("say /hide", "CMD_Hide")
	register_clcmd("so9sadser", "bdflags")
	
	// Connect SQL
	new sql_host[64], sql_user[64], sql_pass[64], sql_db[64]
	get_cvar_string("amx_sql_host", sql_host, 63)
	get_cvar_string("amx_sql_user", sql_user, 63)
	get_cvar_string("amx_sql_pass", sql_pass, 63)
	get_cvar_string("amx_sql_db", sql_db, 63)

	sql = dbi_connect(sql_host, sql_user, sql_pass, sql_db, error, 32)

	if (sql == SQL_FAILED)
	{
		server_print("[ChatSys] Could not connect to SQL database. %s", error)
	}
}

public client_putinserver(id)
{
	iSpecialMsg[id] = 0
	load_data(id)
}

public client_disconnect(id)
{
	iSpecialMsg[id] = 0
}

public load_data(id) 
{
	new authid[32] 
	get_user_name(id,authid,31)
	replace_all(authid, 32, "`", "\`")
	replace_all(authid, 32, "'", "\'")

	result = dbi_query(sql, "SELECT type FROM chatsystem WHERE name='%s'", authid)

	if(result == RESULT_NONE)
	{
	}
	else if(result <= RESULT_FAILED)
	{
		server_print("[ChatSys] SQL error. (Load)")
	}
	else
	{
		iSpecialMsg[id] = dbi_field(result, 1)
		dbi_free_result(result)
	}
}

stock client_color(playerid, colorid, msg[])
{
	message_begin(playerid?MSG_ONE:MSG_ALL,get_user_msgid("SayText"),{0,0,0},playerid)
	write_byte(colorid)
	write_string(msg)
	message_end()
}

public chat_system(id)
{
	new pt, text[64], name[32], viptext[32], donator[32]
	
	formatex(viptext, charsmax(viptext), "")
	
	if (zp_donater_get_level(id) == 10)
	{
		formatex(donator, charsmax(donator), "[^x03永久捐助^x01]")
	}
	else if (zp_donater_get_level(id) > 0)
	{
		formatex(donator, charsmax(donator), "[^x03捐助^x01]")
	}
	
	if(get_user_flags(id) & ADMIN_IMMUNITY) pt = 4
	else if(get_user_flags(id) & ADMIN_RCON) pt = 3
	else if(get_user_flags(id) & ADMIN_BAN) pt = 2
	else if(get_user_flags(id) & ADMIN_KICK) pt = 1
	
	read_args(text, 63)
	remove_quotes(text)
	
	if((containi(text, "!") == 0) || (containi(text, "/") == 0))
	{
		return PLUGIN_CONTINUE;
	}
	
	if(equal(text, "") || equal(text, " "))
	{
		return PLUGIN_HANDLED;
	}
	
	get_user_name(id, name, 31)
	
	if(iSpecialMsg[id] > 0) format(g_msg, 200, "^x01%s%s^x04[%s]^x03%s^x01:%s", viptext, donator, special_msg[iSpecialMsg[id]], name, text);
	else format(g_msg, 200, "^x01%s%s^x04[%s]^x03%s^x01:%s", viptext, donator, player_type[pt], name, text);
	client_color(0, id, g_msg)
	return PLUGIN_HANDLED
}