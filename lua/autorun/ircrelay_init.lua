if SERVER then
	include( "ircrelay/sv_relay.lua" )
	AddCSLuaFile("ircrelay/cl_relay.lua")
end

if CLIENT then
	include("ircrelay/cl_relay.lua")
end