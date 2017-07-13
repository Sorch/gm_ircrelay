--[[
	A an in development irc tool for connecting GrrysMod to irc.
	File: sv_relay.lua
	Title: GarrysMod IRC Relay
	Author: Sorch <sorch@protonmail.ch>
	Version: 0.1alpha
	Description:
 		A small utility for connecting a GarrysMod Server to irc and messaging
		events to irc and back again.
	This program is distributed under the terms of the GNU GPL version 2.
]]

ircrelay = ircrelay or {} 
util.AddNetworkString("IRCMessage")
game.ConsoleCommand( "sv_hibernate_think 1\n" ) -- Keep relay running when server is empty.

include('config.lua')
require("bromsock");

local socket = BromSock();

local function writeline(line)
	local packet = BromPacket();
	packet:WriteLine(line);
	socket:Send(packet, true);
end

function parse(line)
	local s, e, prefix = line:find('^:(%S+)')
	local s, e, command = line:find('(%S+)', e and e+1 or 1)
	local s, e, rest = line:find('%s+(.*)', e and e+1 or 1)
	return prefix, command, rest
end

--lets hate ourselves for this
replies = {}
function send(s)
	local args = s .. "\r\n"
	writeline(args)
end

function replies.ping(prefix, rest)
	send("PONG " .. rest)
end

replies["376"] = function(prefix, rest)
	send("JOIN " .. ircrelay.config.relayChannel)
end


function replies.privmsg(prefix, rest)
	local chan = rest:match('(%S+)')
	local msg = rest:match(':(.*)')
	local nick = prefix:match('(%S+)!')
	local host = prefix:match('@(%S+)')
	local cmd, args = msg:match('^-(%S+)(.*)')
	
	if cmd then
		cmd = cmd:lower()
	end

	if not chan:find('^#') then
		chan = nick
	end
	
	if ircrelay.config.debug then
		print(nick, chan, msg, "from irc")
	end
	
	if(nick ~= ircrelay.nick) then
		if(chan == ircrelay.config.relayChannel) then
				net.Start( "IRCMessage" )
				net.WriteString(nick)
				net.WriteString(msg)
				net.Broadcast()
		end
	end
end
commands = {}

local function socketConnect(sock, connected, ip, port)
	if (not connected) then
		print("Unable to connect to IRC server");
		return;
	end
	print("Connected to IRC Server");
	writeline("NICK " ..ircrelay.config.nick.."\r\nUSER GMOD GMOD * :GMOD");
	socket:ReceiveUntil("\r\n");
end

socket:SetCallbackConnect(socketConnect);

local function sockDisconnect(sock)
	print("IRC socket disconnected");
end
socket:SetCallbackDisconnect(sockDisconnect);

local function socketReceive(sock, packet)
	local message = packet:ReadLine():Trim();
	if message ~= nil then
		local prefix, command, rest = parse(message)
		command = command:lower()
		if replies[command] then
			replies[command](prefix, rest)
		end
	end	
	socket:ReceiveUntil("\r\n");
end

socket:SetCallbackReceive(socketReceive);

ircrelay.init = function(addr, port)
	print("Hello I'm connected to the server " ..addr.. " :)")
	ircrelay.socket = socket
	ircrelay.socket:Connect(addr, port);
end

ircrelay.sendMsg = function(msg, chan)
	send("PRIVMSG " .. chan .. " :" .. msg)
end

hook.Add("OnGamemodeLoaded", "IRCRelayInit", function()
	ircrelay.init(ircrelay.config.server, ircrelay.config.port)
end)


hook.Add("PlayerConnect", "IRCRelayPlayerConnect", function(ply)
	ircrelay.sendMsg(ply.." is connecting to the server!", ircrelay.config.relayChannel)
end)

hook.Add("PlayerDisconnected", "IRCRelayPlayerConnect", function(ply)
	ircrelay.sendMsg(ply:Nick().. " has disconnected from the server!", ircrleay.config.relayChannel)
end)


hook.Add("PlayerSay", "IRCRelayChat", function(ply, text, teamChat)
    if ircrelay then
        ircrelay.sendMsg(ply:Nick()..": "..text, ircrelay.config.relayChannel)
    end
end)


