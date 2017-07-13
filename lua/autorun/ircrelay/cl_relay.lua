net.Receive( "IRCMessage", function()
	local nick = net.ReadString()
	local message = net.ReadString()
	chat.AddText(Color(114,137,218), "IRC ", Color(255,255,255), "| ",nick,": ",message);
end )