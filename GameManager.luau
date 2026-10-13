local GameManager = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DodgeBall = ReplicatedStorage:WaitForChild("DodgeBalls"):WaitForChild("DodgeBall")
local Teams = game:GetService("Teams")
local CollectionService = game:GetService("CollectionService")
local StarerPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local Sounds = SoundService:FindFirstChild("Sounds")


local Modules = ReplicatedStorage:FindFirstChild("Modules")
local UiFunctions = require(Modules:FindFirstChild("UiFunctions"))
local StatsManager = require(Modules:FindFirstChild("StatsManager"))

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local GameEnded = Remotes:FindFirstChild("GameEnded")
local OutEvent = Remotes:FindFirstChild("OutEvent")
local TriggerSound = Remotes:FindFirstChild("TriggerSound")

local Team1Players,Team2Players = {},{}
local Teampoints = {0,0}
local Balls = {}

local ToolCollection = workspace:FindFirstChild("ToolCollection")

local MatchSounds = Sounds:FindFirstChild("BasicSounds"):FindFirstChild("MatchSounds")

local Gym = workspace:WaitForChild("Gym")
local Team1Hitbox,Team2Hitbox = Gym:FindFirstChild("Team1Area"),Gym:FindFirstChild("Team2Area")

local ChudPlayers =workspace:WaitForChild("ChudPlayers")

local ls = StatsManager.RetrieveLS()

GameManager.MinPlayers = 8

function GameManager.VerifyLobbySize()
	local playerCount = #Players:GetPlayers()
	return playerCount >= GameManager.MinPlayers
end

function GameManager.VerifyLobbySizeFake()
	local ChudPlayers = workspace:WaitForChild("ChudPlayers")
	local playerCount = #Players:GetPlayers()
	local playerCount = #ChudPlayers:GetChildren() + playerCount
	
	return playerCount >= GameManager.MinPlayers
end

local function UpdScoreBoard()
	local boards = CollectionService:GetTagged("ScoreGui")
	
	for i,v in boards do
		local teamone = v:FindFirstChild("TeamScore1")
		local teamtwo = v:FindFirstChild("TeamScore2")
		if teamone and teamtwo then
			teamone.Text = tostring(Teampoints[1])
			teamtwo.Text = tostring(Teampoints[2])
		end
	end
end

local function debugRay(origin: Vector3, direction: Vector3, duration: number?)
	local distance = direction.Magnitude
	if distance < 0.001 then return end

	local debugPart = Instance.new("Part")
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.CanQuery = false
	debugPart.Material = Enum.Material.Neon
	debugPart.Color = Color3.fromRGB(255, 50, 50) 
	debugPart.Transparency = 0.3
	debugPart.Size = Vector3.new(0.1, 0.1, distance)


	debugPart.CFrame = CFrame.lookAt(origin + (direction / 2), origin + direction)
	debugPart.Parent = workspace


	task.delay(duration or 2, function()
		debugPart:Destroy()
	end)
end

local function ClearTeams()
	Team1Players,Team2Players = {},{}
	Teampoints = {0,0}
end

local OUT_OF_BOUNDS_TAG = "OutOfBounds"

local spawnballsconnection = nil
local BarrierConnections = {}

function GameManager.StartGame(allPlayers,Map)
	
	if spawnballsconnection then
		spawnballsconnection:Disconnect()
		spawnballsconnection = nil
	end
	
	if BarrierConnections then
		for i,v in pairs(BarrierConnections) do
			v:Disconnect()
		end
		table.clear(BarrierConnections)
	end
	
	
	local NonPlayerTeam = nil

	local TeamBoxes = { Map:FindFirstChild("Team1Area"),Map:FindFirstChild("Team2Area")}
	
	
	UpdScoreBoard()
	
	
	for i = #allPlayers, 2, -1 do
		local j = math.random(i)
		allPlayers[i], allPlayers[j] = allPlayers[j], allPlayers[i]
	end

	
	
	local totalPlayers = #allPlayers
	local half = math.ceil(totalPlayers / 2)

	local function TpToTeamBox(teamNum,character)
		local size = TeamBoxes[teamNum].Size
		local cframe = TeamBoxes[teamNum].CFrame

		local randomX = math.random(-size.X/2, size.X/2)
		local randomY = cframe.Y -- Fixed: used 'cframe.Y' instead of 'CFrame.Y'
		local randomZ = math.random(-size.Z/2, size.Z/2)

		local targetCFrame = cframe * CFrame.new(randomX, 0, randomZ) -- Adjusted calculation

		if character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo( targetCFrame + Vector3.new(0, 3, 0) )
		end
	end


	for i, player in ipairs(allPlayers) do


		local teamNum = (i <= half) and 1 or 2
		local isplayer = player:IsA("Player")

	
		


		
		if teamNum == 1 then
			table.insert(Team1Players, player)
		else
			table.insert(Team2Players, player)
		end


		local character = (player:IsA("Player") and player.Character) or (player:IsA("Model") and player)

		if character and character:FindFirstChild("Humanoid") then
			
			if player:IsA("Player") then
				player.Team = Teams:FindFirstChild("Team" .. teamNum)

				character.Humanoid.Died:Once(function()
					if player.Team == Teams:FindFirstChild("Team1 Out") or player.Team == Teams:FindFirstChild("Team2 Out") then
						return
					end


					local reset = true
					GameManager.AwardPoint(character,nil,reset)

					local plrteam = GameManager.GetTeam(character)
					if plrteam == 1 then
						player.Team = nil
					else
						player.Team = nil
					end

				end)

			else
				character:SetAttribute("Team",teamNum)
			end





			task.delay(1,function()
				TpToTeamBox(teamNum,character)
			end)


		end



	end
	
	
	
	--[[

	

	local TotalBalls = #allPlayers/2  
	
	local teamAssignments = {}
	
	for i = 1, TotalBalls do
		local teamNumber = (i % 2 == 1) and 1 or 2
		table.insert(teamAssignments, teamNumber)
	end

	for i = #teamAssignments, 2, -1 do
		local j = math.random(i)
		teamAssignments[i], teamAssignments[j] = teamAssignments[j], teamAssignments[i]
	end
	
	for i = 1,TotalBalls do
		local ball = DodgeBall:Clone()
		ball.Parent = ToolCollection
		ball.Name = "Ball"..i
		table.insert(Balls,ball)
		local team = teamAssignments[i]
		
		local size = TeamBoxes[team].Size
		local cframe = TeamBoxes[team].CFrame


		local randomX = math.random(-size.X/2, size.X/2)
		local randomY = CFrame.Y
		local randomZ = math.random(-size.Z/2, size.Z/2)


		local targetCFrame = cframe * CFrame.new(randomX, randomY, randomZ)

		ball:PivotTo( targetCFrame + Vector3.new(0, 3, 0) )
		ball:SetAttribute("GameBall",true)
		ball.Destroying:Connect(function()
			table.remove(Balls,table.find(Balls,ball))
		end)
		
	end
	
	spawnballsconnection = RunService.Heartbeat:Connect(function()
		task.wait(5)
		local gameballs = #Balls
		local maxBalls = math.floor(#allPlayers / 2)
		local ballsToSpawn = maxBalls - gameballs

		if ballsToSpawn > 0 then
			-- Randomize starting team so 1-ball respawns aren't biased
			local startTeam = math.random(1, 2)

			for i = 1, ballsToSpawn do
				local ball = DodgeBall:Clone()
				ball.Parent = ToolCollection
				ball.Name = "BallRandom"
				table.insert(Balls, ball)

				-- Alternate teams starting from the randomized team
				local team = (i % 2 == 1) and startTeam or (3 - startTeam)

				local size = TeamBoxes[team].Size
				local cframe = TeamBoxes[team].CFrame

				local randomX = math.random(-size.X/2, size.X/2)
				local randomZ = math.random(-size.Z/2, size.Z/2)
				local targetCFrame = cframe * CFrame.new(randomX, 0, randomZ)

				ball:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
				ball:SetAttribute("GameBall", true)

				ball.Destroying:Connect(function()
					table.remove(Balls, table.find(Balls, ball))
				end)
			end 
		end
	end)	
		
	]]
	
	
	local TotalBalls = #allPlayers / 2  
	local teamAssignments = {}
	
	

	local spawningOnlySideOne = false

	
	task.delay(40, function()
		spawningOnlySideOne = false
	end)

	
	for i = 1, TotalBalls do
	
		local teamNumber = spawningOnlySideOne and 2 or 1
		print(teamNumber)
		table.insert(teamAssignments, teamNumber)
	end


	if not spawningOnlySideOne then
		for i = #teamAssignments, 2, -1 do
			local j = math.random(i)
			teamAssignments[i], teamAssignments[j] = teamAssignments[j], teamAssignments[i]
		end
	end

	for i = 1, TotalBalls do
		local ball = DodgeBall:Clone()
		ball.Parent = ToolCollection
		ball.Name = "Ball" .. i
		table.insert(Balls, ball)

		local team = teamAssignments[i]
		local size = TeamBoxes[team].Size
		local cframe = TeamBoxes[team].CFrame

	
		local randomX = math.random(-size.X / 2, size.X / 2)
		local randomZ = math.random(-size.Z / 2, size.Z / 2)

		local targetCFrame = cframe * CFrame.new(randomX, 0, randomZ)

		ball:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
		ball:SetAttribute("GameBall", true)

		ball.Destroying:Connect(function()
			local index = table.find(Balls, ball)
			if index then
				table.remove(Balls, index)
			end
		end)
	end

	
	spawnballsconnection = RunService.Heartbeat:Connect(function()
		task.wait(5)
		local gameballs = #Balls
		local maxBalls = math.floor(#allPlayers / 2)
		local ballsToSpawn = maxBalls - gameballs

		if ballsToSpawn > 0 then
			local startTeam = math.random(1, 2)

			for i = 1, ballsToSpawn do
				local ball = DodgeBall:Clone()
				ball.Parent = ToolCollection
				ball.Name = "BallRandom"
				table.insert(Balls, ball)

			
				local team
				if spawningOnlySideOne then
					team = 2
				else
					team = 1
				end

				local size = TeamBoxes[team].Size
				local cframe = TeamBoxes[team].CFrame

				local randomX = math.random(-size.X / 2, size.X / 2)
				local randomZ = math.random(-size.Z / 2, size.Z / 2)
				local targetCFrame = cframe * CFrame.new(randomX, 0, randomZ)

				ball:PivotTo(targetCFrame + Vector3.new(0, 3, 0))
				ball:SetAttribute("GameBall", true)

				ball.Destroying:Connect(function()
					local index = table.find(Balls, ball)
					if index then
						table.remove(Balls, index)
					end
				end)
			end 
		end
	end)
	
	
	local cooldowns = {}
	local walls = CollectionService:GetTagged(OUT_OF_BOUNDS_TAG)
	
	for _, wall in pairs( walls ) do
		local connection = wall.Touched:Connect(function(hit)
			local HitParent = hit.Parent
			
			if HitParent == nil then return end
			local Player = Players:GetPlayerFromCharacter(HitParent)
			if HitParent:IsA("Model") and Player then
				
				
				
				if cooldowns[Player] then return end
				local plrteam = Player.Team
				
				if plrteam == Teams.Team1 or plrteam == Teams.Team2 then
					if wall.Name == "BarrierHitbox" then
						return
					end	
				end
				
				local function TpOut(default)
					
					cooldowns[Player] = true
					if default  then
						local Studs = 10
						local raycastparams = RaycastParams.new()
						raycastparams.FilterType = Enum.RaycastFilterType.Exclude
						raycastparams.FilterDescendantsInstances = {HitParent}
						
						local origin = wall.CFrame.Position
						
						local sizeY = wall.Size.Y/12
						local floor = wall.CFrame.Position.Y - wall.Size.Y/2
						local targetY = floor + sizeY
						
						origin = Vector3.new(origin.X,targetY,origin.Z)
					
						local charpos = HitParent.PrimaryPart.Position
						charpos = Vector3.new(charpos.X,origin.Y,charpos.Z)
						local dir = charpos - origin 
						
						dir = dir.Unit * 150
						
						local result = workspace:Raycast(origin,dir,raycastparams)
						--debugRay(origin,dir,60)
						if result  then
							local rayhit = result.Instance

							local lookoffset = -rayhit.CFrame.LookVector * Studs

							local destination = CFrame.new(result.Position + lookoffset)
							HitParent:PivotTo(destination)
							
						end
						
						
					else
						local Studs = 10
						local dir = -wall.CFrame.LookVector * Studs
						local destination = CFrame.new(HitParent.PrimaryPart.Position + dir)

						HitParent:PivotTo(destination)
						
					end
				
					task.wait(0.2) 
					cooldowns[Player] = nil 
				end
				
				if plrteam ~= Teams.Team1 and plrteam ~= Teams.Team2 then
				
					if wall.Name == "BarrierHitbox" then
						TpOut(true)
					
					end
					return end
				local Team = GameManager.GetTeam(Player)
				
				
				
				
				if Team == 1 then
					Player.Team = Teams["Team1 Out"]
					GameManager.AwardPoint(nil,Player,true)
			
					OutEvent:FireClient(Player,walls)
					if wall.Name == "BarrierHitbox" then
						TpOut(true)
					end
					TpOut()
				else
					Player.Team = Teams["Team2 Out"]
					
					GameManager.AwardPoint(nil,Player,true)
				
					OutEvent:FireClient(Player,walls)
					if wall.Name == "BarrierHitbox" then
						TpOut(true)
					end
					TpOut()
				end
				
				
			end
		end)
		table.insert(BarrierConnections,connection)
	end

end

function GameManager.RegisterHit(targethit,thrower,direction,Velocity)
	
	local targetteam, throwerteam = GameManager.GetTeam(targethit), GameManager.GetTeam(thrower)
	local isplayerteam = GameManager.GetTeam(thrower)
	
	local isplayer = Players:GetPlayerFromCharacter(targethit)
	local isFriendly = (targetteam == throwerteam)
	
	if targetteam == nil then
		isFriendly = nil
	end
	
	local IsDummy = (thrower:HasTag("HostileDummy") or targethit:HasTag("Dummy"))
	local isInvalidPlayer = isplayerteam 
	
	local isOut = isplayer and isplayer.Team and 
		(isplayer.Team.Name == "Team1 Out" or isplayer.Team.Name == "Team2 Out")
	
	
	if isFriendly or (not isInvalidPlayer and not IsDummy) or isOut then
		return
	end

	--[[
	
	
		if targethit:GetAttribute("Blocking") or targethit:GetAttribute("IFrames") then
			
			local BlockSFX = Sounds:FindFirstChild("BasicSounds"):FindFirstChild("Block"):Clone()


			
				BlockSFX.Parent = targethit
		

			for i,v in BlockSFX:GetChildren() do
				v.Parent = targethit
				v:Play()
				v.Parent = BlockSFX
			end
			Debris:AddItem(BlockSFX,2)
			return end
		targethit.Humanoid.Health -= 100
		
	local throwerIsPlayer = Players:GetPlayerFromCharacter(thrower) or false
		
	if throwerIsPlayer then
			local LS = throwerIsPlayer:WaitForChild("leaderstats")
			local Points = LS:FindFirstChild("Points")
			Points.Value += 1
			
		if targethit.Humanoid.Health <= 0 then
				local LS = throwerIsPlayer:WaitForChild("leaderstats")
				local Knockouts = LS:FindFirstChild("K.O's")
				Knockouts.Value += 1
		end
	end	
		
	
		
	GameManager.AwardPoint(targethit,thrower)
		
	else
	]]
---	
		if not targethit:GetAttribute("IFrames") then 
			
			
			local IsBlocking = targethit:GetAttribute("Blocking")
			local BlockStart = targethit:GetAttribute("BlockStartTime")
			
			if IsBlocking then

				local BlockSFX = Sounds:FindFirstChild("BasicSounds"):FindFirstChild("Block"):Clone()
				BlockSFX.Parent = targethit
				for i,v in BlockSFX:GetChildren() do
					v:Play()
				end
				Debris:AddItem(BlockSFX,2)
			else

				local BlockSFX = Sounds:FindFirstChild("BasicSounds"):FindFirstChild("BallHit"):Clone()
				BlockSFX.Parent = targethit
				for i,v in BlockSFX:GetChildren() do
					v:Play()
				end
				Debris:AddItem(BlockSFX,2)
			end
			
			
			if BlockStart then
				local Timenow = workspace:GetServerTimeNow()
				local Elapsed = Timenow - BlockStart

				if Elapsed < 1 then
					DodgeBall:Clone().Parent = targethit
					
					
					return end
			end
		
			local LinearVelocity = Instance.new("LinearVelocity")
			LinearVelocity.Parent = targethit.PrimaryPart
			local RootAttachment = targethit.PrimaryPart:FindFirstChild("RootAttachment")
				or targethit.PrimaryPart:FindFirstChild("RootRigAttachment") 
			
			
			
			
			
			local PushBackForce = IsBlocking and direction * Velocity.Magnitude/10 or
				direction * (Velocity.Magnitude/10) * 2 
			local DamageTaken = IsBlocking and 5 or 100
			local Caught = IsBlocking and true or false
			
			LinearVelocity.Attachment0 = RootAttachment
			LinearVelocity.MaxForce = 100000

			LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
			LinearVelocity.VectorVelocity = PushBackForce
			targethit.Humanoid.WalkSpeed = 0
			
			
			task.delay(0.4,function()
			LinearVelocity:Destroy()
			if targethit and targethit.Parent and targethit.Humanoid then
				targethit.Humanoid.WalkSpeed = StarerPlayer.CharacterWalkSpeed
				if Caught then
					DodgeBall:Clone().Parent = targethit
				else
			end
				end
			end)
		
	
			
		targethit.Humanoid.Health -= DamageTaken
		
		
		
		if targethit.Humanoid.Health <= 0 and targetteam and not isplayer then
			GameManager.AwardPoint(targethit,thrower)
		end
			
			
			
			targethit:SetAttribute("Hit",true)
			task.delay(0.2,function()
				targethit:SetAttribute("Hit",false)
			end)
		end
	end
	


function GameManager.AwardPoint(targethit,thrower,reset)
	
	
	



	TriggerSound:FireAllClients(MatchSounds["Minecraft Sound Successful Bow Hit Ding"])


	
	
	local Team = GameManager.GetTeam(thrower)
	local targetteam 
	
	
	if reset then
		targetteam = GameManager.GetTeam(thrower)
		if Team == 1 then
			Team = 2
		else
			Team = 1
		end
	else
		targetteam = GameManager.GetTeam(targethit)
	end
	
	if Team then
		Teampoints[Team] += 1
		
	
		
		local isplayer = game.Players:GetPlayerFromCharacter(thrower)
		if isplayer then
			local leaderstats = isplayer:FindFirstChild("leaderstats")
			if not leaderstats then return end
			local playerKnockouts = leaderstats:FindFirstChild("K.O's")
			if not playerKnockouts then return end
			playerKnockouts.Value += 1
			
			local points = leaderstats:FindFirstChild("Points")
			if not points then return end
			points.Value += 1
			
		end
		
		
		UpdScoreBoard()
		
		local playercount 
		if targetteam == 1 then 
			playercount = #Team1Players
		else
			playercount = #Team2Players
		end
	
		
		if Teampoints[Team] >= playercount then
			GameManager.EndGame(Team)
		end

	
	end
	
end

function GameManager.GetTeam(target)
	
	for _, player in ipairs(Team1Players) do
		if not target or not player then continue end
		if player == target or player.Name == target.Name 
			and Players:GetPlayerFromCharacter(target)  then return 1,Team2Hitbox,Team1Hitbox end
	end

	for _, player in ipairs(Team2Players) do
		if not target or not player then continue end
		if player == target or player.Name == target.Name 
			and Players:GetPlayerFromCharacter(target)  then return 2,Team1Hitbox,Team2Hitbox end
	end

	return nil 
end
function GameManager.GetTeamList(team)
	
	if team == 1 then
		return Team1Players
	elseif team == 2 then
		return Team2Players
	end
	return nil 
end

function GameManager.EndGame(WinningTeam)
	
	
	for i,v in Team1Players do

		local respawn =  ChudPlayers:FindFirstChild(v.Name) 
		local checkplayer = game.Players:FindFirstChild(v.Name)
	
		if checkplayer then
			local LS = checkplayer:WaitForChild("leaderstats")
			local Points = LS:FindFirstChild("Points")
			Points.Value = 0
			checkplayer.Neutral = true
			checkplayer:LoadCharacter()
			local team = GameManager.GetTeam(v)
			if team == WinningTeam then
				TriggerSound:FireClient(checkplayer,MatchSounds["tf2 victory sfx"])
				
				local leaderstats = checkplayer:FindFirstChild("leaderstats")
				if not leaderstats then return end
				local playerWins = leaderstats:FindFirstChild("Wins")
				if not playerWins then return end
				playerWins.Value += 1
				
			else
				TriggerSound:FireClient(checkplayer,MatchSounds["Womp Womp"])
			end
		elseif respawn then
			local human = respawn:FindFirstChild("Humanoid")
			human.Health = 0
			respawn:Destroy()
		end



	end
	
	for i,v in Team2Players do

		local respawn =  ChudPlayers:FindFirstChild(v.Name) 
		local checkplayer = game.Players:FindFirstChild(v.Name)

		if checkplayer then
			local LS = checkplayer:WaitForChild("leaderstats")
			local Points = LS:FindFirstChild("Points")
			Points.Value = 0
			checkplayer.Neutral = true
			checkplayer:LoadCharacter()
			local team = GameManager.GetTeam(v)
			if team == WinningTeam then
				TriggerSound:FireClient(checkplayer,MatchSounds["tf2 victory sfx"])

				local leaderstats = checkplayer:FindFirstChild("leaderstats")
				if not leaderstats then return end
				local playerWins = leaderstats:FindFirstChild("Wins")
				if not playerWins then return end
				playerWins.Value += 1

			else
				TriggerSound:FireClient(checkplayer,MatchSounds["Womp Womp"])
			end
		elseif respawn then
			local human = respawn:FindFirstChild("Humanoid")
			human.Health = 0
			respawn:Destroy()
		end



	end
	
	
	
	
	
	
	GameEnded:Fire(WinningTeam)
	ClearTeams()
	
	for i,v  in Balls do
		v:Destroy()
		Balls[i] = nil
		
	end
end






return GameManager
