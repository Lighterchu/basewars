BaseWars.Commands = {
	cmds = {},
}

function BaseWars.Commands.ParseArgs(str)

	local ret 		= {}
	local InString 	= false
	local strchar 	= ""
	local chr 		= ""
	local escaped 	= false

	for i=1, #str do
	
		local char = str[i]

		if escaped then
		
			chr = chr..char
			escaped = false

		continue end

		if char:find("[\"|']") and not InString and not escaped then
		
			InString 	= true
			strchar 	= char

		elseif char:find("[\\]") then
		
			escaped 	= true

			continue

		elseif InString and char == strchar then
		
			ret[#ret+1] = chr:Trim()
			chr 		= ""
			InString 	= false

		elseif char:find("[ ]") and not InString and chr ~= "" then
		
			ret[#ret+1] = chr
			chr 		= ""

		else
			chr = chr .. char

		end
		
	end

	if chr:Trim():len() ~= 0 then
	
		ret[#ret+1] = chr
		
	end

	return ret
	
end

function BaseWars.Commands.CallCommand(ply, cmd, line, args)

	local ok, msg = pcall(function()

		local allowed, reason = hook.Run("BaseWarsCommand", cmd, ply, line, unpack(args))
		
		cmd = BaseWars.Commands.cmds[cmd]

		if allowed ~= false then
		
			if easylua then easylua.Start(ply) end
			
				allowed, reason = cmd.CallBack(ply, line, unpack(args))
				
			if easylua then easylua.End() end
			
		end
		
		if ply:IsValid() then
			
			if allowed == false then
			
				ply:EmitSound("buttons/button8.wav")
				
			end
			
		end
	end)

	if not ok then
	
		ErrorNoHalt(msg)
		
		return msg
		
	end
	
end

function BaseWars.Commands.ConCommand(ply, cmd, args, line)

	local Cmd = args[1]
	if not Cmd then return end
	
	local TblCmd = BaseWars.Commands.cmds[Cmd]
	if not TblCmd then return end
	
	if not BaseWars.Ents:Valid(ply) or (TblCmd.IsAdmin and not ply:IsAdmin()) then return end
	
	if ply.IsBanned and ply:IsBanned() and not ply:IsAdmin() then return end
	
	table.remove(args, 1)
	
	BaseWars.Commands.CallCommand(ply, Cmd, table.concat(args, " "), args)
	
end

function BaseWars.Commands.SayCommand(ply, txt, team)

	if not txt:sub(1, 1):find("[!|/|%.]") then return end
	
	local cmd 	= txt:match("[!|/|%.](.-) ") or txt:match("[!|/|%.](.+)") or ""
	local line 	= txt:match("[!|/|%.].- (.+)")
	
	cmd = cmd:lower()
	
	if not cmd then return end
	
	local TblCmd = BaseWars.Commands.cmds[cmd]
	if not TblCmd then return end

	BaseWars.Commands.CallCommand(ply, cmd, line, line and BaseWars.Commands.ParseArgs(line) or {})
	
end

function BaseWars.Commands.AddCommand(cmd, callback, admin)

	if istable(cmd) then
	
		for k, v in next, cmd do
		
			BaseWars.Commands.AddCommand(v, callback, admin)
			
		end

		return
		
	end

	BaseWars.Commands.cmds[cmd] 	= {CallBack = callback, IsAdmin = admin, Cmd = cmd}
	
end

concommand.Add("basewars", BaseWars.Commands.ConCommand)
hook.Add("PlayerSay", "BaseWars.Commands", BaseWars.Commands.SayCommand)

local dist = 100^2
local function Upgradable(ply, ent)

	local Eyes = ply:EyePos()
	local Class = ent:GetClass()
	
	return BaseWars.Ents:Valid(ent) and Eyes:DistToSqr(ent:GetPos()) < dist and ent.Upgrade

end
BaseWars.Commands.AddCommand({"upg", "upgrade", "upgr"}, function(ply)

	local trace = ply:GetEyeTrace()

	local Ent = trace.Entity
	if not Upgradable(ply, Ent) then return false end

	Ent:Upgrade(ply)
	
end, false)