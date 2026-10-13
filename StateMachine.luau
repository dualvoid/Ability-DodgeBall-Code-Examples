local StateMachine = {}


local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local Runservice = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")
local SoundService = game:GetService("SoundService")
local Sounds = SoundService:WaitForChild("Sounds")

local DefaultWalkSpeed = StarterPlayer.CharacterWalkSpeed
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ProjectileService = require(Modules:WaitForChild("ClientProjectileService"))

local BillBoard = ReplicatedStorage:WaitForChild("BillboardGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteFunctions = Remotes:WaitForChild("RemoteFunctions")


local DashRemote = Remotes:WaitForChild("Dash")
local Block = RemoteFunctions:WaitForChild("Block") 
local CatchRemote = Remotes:WaitForChild("CatchRemote")
local PassRemote = Remotes:WaitForChild("PassRemote")

local DodgeballThrow = Remotes:WaitForChild("DodgeballThrow")

local ExcludeWall =  Workspace:WaitForChild("Gym"):WaitForChild("InvisibleWall")

local PlrGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local PlayerHUD = PlrGui:WaitForChild("PlayerHud")
local PowerText = PlayerHUD:WaitForChild("PowerText")


local NPC_AIMABLE = "PlayerAimable"
local FAKEVISUALBALL = "FakeVisualBall"


local Animations = {
	
	DashAnim = "rbxassetid://89102755486742" ,
	DashAnimTwo = "rbxassetid://114295068768672",
	
	
	THROWANIM = "http://www.roblox.com/asset/?id=81169055427302",
	BALL_IDLEANIM = "http://www.roblox.com/asset/?id=139520048837107",
	POWEREDTHROWANIM = "http://www.roblox.com/asset/?id=125796454906057",
	
	ENHANCERTHROWANIM = "http://www.roblox.com/asset/?id=90136445651158",

	
	
	
	
	
	
}



local States = 
	{
		Idle = 0,
		Running = 1,
		Dashing = 2,
		Blocking  = 3,
		Attacking = 4,
		SpecialAbility = 5,
		Staggered = 6,
		Rebounding = 7,
		Passing = 8

	}


for i ,v in Animations do
	local Animation = Instance.new("Animation")
	Animation.AnimationId = v
	Animations[i] = Animation
end

local ReboundsEnabled = false

local function isRagdolled(humanoid)
	return  humanoid:GetState() == Enum.HumanoidStateType.FallingDown
end

local function getCharacterWhitelist(localChar)
	local whitelist = {}
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Character and otherPlayer.Character ~= localChar then
			table.insert(whitelist, otherPlayer.Character)
		end
	end
	

	local npcFolder = CollectionService:GetTagged(NPC_AIMABLE)
	if npcFolder then
		for _, npc in ipairs(npcFolder) do
			if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
				table.insert(whitelist, npc)
			end
		end
	end

	return whitelist
end
local function getBallsWhitelist(localchar)
	local plr = Players:GetPlayerFromCharacter(localchar)
	local whitelist = {}
	
	for _, otherball in ipairs(CollectionService:GetTagged(FAKEVISUALBALL)) do
		if otherball and otherball.Parent  then
			table.insert(whitelist, otherball)
		end
	end


	return whitelist
end

local function updateFilterList()

	local ignoreList = {}
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc.Name == ExcludeWall.Name or desc.Name == "BarrierVisual"
			or desc.Name == "BarrierHitbox"then
			table.insert(ignoreList, desc)
		end
	end

	return ignoreList
end
local ignoreList = updateFilterList()


local currentbillboard = nil

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

local function debugSpherecast(origin: Vector3, radius: number, direction: Vector3, duration: number?)
	local distance = direction.Magnitude
	if distance < 0.001 then return end

	duration = duration or 2
	local endPosition = origin + direction


	local debugFolder = Instance.new("Folder")
	debugFolder.Name = "DebugSpherecast"

	
	local cylinder = Instance.new("Part")
	cylinder.Anchored = true
	cylinder.CanCollide = false
	cylinder.CanQuery = false
	cylinder.Material = Enum.Material.Neon
	cylinder.Color = Color3.fromRGB(255, 50, 50)
	cylinder.Transparency = 0.95
	cylinder.Shape = Enum.PartType.Cylinder
	
	cylinder.Size = Vector3.new(distance, radius * 2, radius * 2)
	
	cylinder.CFrame = CFrame.lookAt(origin + (direction / 2), endPosition) * CFrame.Angles(0, math.rad(90), 0)
	cylinder.Parent = debugFolder


	local startSphere = Instance.new("Part")
	startSphere.Anchored = true
	startSphere.CanCollide = false
	startSphere.CanQuery = false
	startSphere.Material = Enum.Material.Neon
	startSphere.Color = Color3.fromRGB(255, 100, 100)
	startSphere.Transparency = 0.8
	startSphere.Shape = Enum.PartType.Ball
	startSphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	startSphere.CFrame = CFrame.new(origin)
	startSphere.Parent = debugFolder

	
	local endSphere = startSphere:Clone()
	endSphere.CFrame = CFrame.new(endPosition)
	endSphere.Parent = debugFolder

	debugFolder.Parent = workspace

	task.delay(duration, function()
		debugFolder:Destroy()
	end)
end
local AimAssistRadius = 15

local function getCustomMouseData(camera, raycastParams, hrp,candebug,Vertical,customParams)
	local mousePosition = UIS:GetMouseLocation()


	local cameraRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)


	local cameraHit = Workspace:Raycast(cameraRay.Origin, cameraRay.Direction * 1000, raycastParams)
	local targetWorldPos = cameraHit and cameraHit.Position or (cameraRay.Origin + cameraRay.Direction * 1000)
	
	
	local flatTargetPos =  nil
		if not Vertical then
		flatTargetPos = Vector3.new(targetWorldPos.X, hrp.Position.Y, targetWorldPos.Z)
		else
		flatTargetPos = Vector3.new(targetWorldPos.X, targetWorldPos.Y, targetWorldPos.Z)
		end
	
	local distanceToTarget = flatTargetPos - hrp.Position

	
	if distanceToTarget.Magnitude > 0.5 then
		hrp.CFrame = CFrame.lookAt(
			hrp.Position,  Vector3.new(targetWorldPos.X, hrp.Position.Y, targetWorldPos.Z)
		)
	end


	local rayOrigin = hrp.Position
	local rayDirection = flatTargetPos - rayOrigin
	
	
	
	local spherecstparams = customParams or RaycastParams.new()
	
	if not customParams then
		spherecstparams.FilterType = Enum.RaycastFilterType.Include
		spherecstparams.FilterDescendantsInstances = Vertical and getBallsWhitelist(hrp.Parent)
			or getCharacterWhitelist(hrp.Parent)
	end
	
		
	
	
	local spherecastResult =
		Workspace:Spherecast(rayOrigin,AimAssistRadius, rayDirection,spherecstparams)
	local debugDir = spherecastResult and (spherecastResult.Position - rayOrigin) or rayDirection
	
	if candebug then
		debugSpherecast(rayOrigin,2,debugDir)
	end
	

	
	if spherecastResult and spherecastResult.Instance and spherecastResult.Instance.Parent
		and spherecastResult.Instance.Parent:FindFirstChildOfClass("Humanoid") or spherecastResult and Vertical
	then
		
		return spherecastResult.Instance, spherecastResult.Position
	else
		local maxTarget = rayOrigin + rayDirection
		return nil, maxTarget
	end
	
end

local function getPredictedPosition(targetPart: BasePart, originPos: Vector3, throwSpeed: number)
	local targetPos = targetPart.Position
	local targetVelocity = targetPart.AssemblyLinearVelocity

	local flatVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)


	local distance = (targetPos - originPos).Magnitude
	local travelTime = distance / math.max(throwSpeed, 1)


	return targetPos + (flatVelocity * travelTime)
end


local function ThrowDodgeBall(self,Tool,SpecialParams)
	
local PowerIncrement = 2
	
if not SpecialParams then
		
		if self.currentstate == States.Attacking then
		return
		end
		
		local isoncooldown = self:IsOnCooldown(States.Attacking)
		
		if isoncooldown then
			return
		end
		
		self.cooldownTimestamps[States.Attacking] = Workspace:GetServerTimeNow() + math.huge
		self.currentstate = States.Attacking
		
		
	elseif SpecialParams  then
		if SpecialParams["Type"] == "GodSpeed" then
			local isoncooldown = self:IsOnCooldown(States.Attacking)
			if isoncooldown then
				return
			end
			self.cooldownTimestamps[States.Attacking] = Workspace:GetServerTimeNow() + math.huge
		end
		
end

	

			
	
	
	
	

	local Handle = Tool:WaitForChild("Handle",5)
	local player, char = self.player, self.char
	local humanoid = self.humanoid
	local hrp = self.humanoidRootPart

	local Power = 100
	local isHoldingMouse = true
	local currentanim 
	local calculationEnabled = true
	local Target = nil
	local THROW_MARKER = "ThrowEvent"
	local camera = Workspace.CurrentCamera
	
	local PAUSE_MARKER = SpecialParams and SpecialParams.PauseMarker or nil
	local BALLFLOAT_MARKER = SpecialParams and SpecialParams.BallFloatMarker or nil
	
	local ThrowTrack,BallIdleTrack,PoweredThrowTrack
	
	
	if not self.animations.THROWANIM then
		ThrowTrack = humanoid.Animator:LoadAnimation(Animations.THROWANIM_ID)
		self.animations.THROWANIM = ThrowTrack
	end

	if not self.animations.BALL_IDLEANIM then
		BallIdleTrack = humanoid.Animator:LoadAnimation(Animations.BALL_IDLEANIM_ID)
		self.animations.BALL_IDLEANIM = BallIdleTrack
	end

	if not self.animations.POWEREDTHROWANIM then
		PoweredThrowTrack = humanoid.Animator:LoadAnimation(Animations.POWEREDTHROWANIM_ID)
		self.animations.POWEREDTHROWANIM = PoweredThrowTrack
	end
	
	ThrowTrack,BallIdleTrack,PoweredThrowTrack = 
		self.animations.THROWANIM,self.animations.BALL_IDLEANIM,self.animations.POWEREDTHROWANIM
	
	local isAbility = SpecialParams 
	local inputConnection = nil
	local cancontinue = false
	local cancontinuetweens = false
	
	
	local function executeThrow()
		if inputConnection then inputConnection:Disconnect() end 
		isHoldingMouse = false
		BallIdleTrack:Stop()

		if isAbility then
			if SpecialParams["Type"] == "GodSpeed"  then
				
				

				self.animations.THROWANIM:Play()
				currentanim = ThrowTrack
				
			end
		
		else
			
			if Power < 200 then
				self.animations.THROWANIM:Play()
				currentanim = ThrowTrack
			else
				self.animations.POWEREDTHROWANIM:Play()
				currentanim = PoweredThrowTrack
			end
			
		end

		

		if isAbility then
			if SpecialParams["Type"] == "GodSpeed" then
				

			end
		else
			humanoid.WalkSpeed = 0
		end

		
		
		currentanim:GetMarkerReachedSignal(THROW_MARKER):Wait()
		
		if Power > 200 then
			local BlockSFX = Sounds:FindFirstChild("BasicSounds"):FindFirstChild("BallThrowWeak"):Clone()
			BlockSFX.Parent = char
			for i,v in BlockSFX:GetChildren() do
				v.Parent = nil
				SoundService:PlayLocalSound(v)
				v.Parent = BlockSFX
			end
			Debris:AddItem(BlockSFX,2)
		else
			local BlockSFX = Sounds:FindFirstChild("BasicSounds"):FindFirstChild("BallThrow"):Clone()
			BlockSFX.Parent = char
			for i,v in BlockSFX:GetChildren() do
				v.Parent = nil
				SoundService:PlayLocalSound(v)
				v.Parent = BlockSFX
			end
			Debris:AddItem(BlockSFX,2)
		end
		
		if isAbility then
			if SpecialParams["Type"] == "Enhancer"  then
				
			
			SpecialParams.EffectsTable["EnhancerBallHit"].Parent = Workspace
			SpecialParams.EffectsTable["EnhancerBallHit"].Position = Handle.Position
			local ParticleEmitters = SpecialParams.EffectsTable["EnhancerBallHit"]:GetChildren()
			for _, emitter in ipairs(ParticleEmitters) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = false
					emitter:Emit(1)
				end
			end
				Debris:AddItem(SpecialParams.EffectsTable["EnhancerBallHit"],3)
				local RockImpact = SpecialParams.SoundEffects.RockImpact

				RockImpact.Position = Handle.Position
				RockImpact.Parent = workspace
				Debris:AddItem(RockImpact,5)
				for i,v in RockImpact:GetChildren() do
					if v and v:IsA("Sound") then
						v:Play()
					end
				end
				
			end
			
			
		end
		
		
		if isAbility then
			if SpecialParams["Type"] == "GodSpeed" then
			
			end
		else
			humanoid.WalkSpeed = DefaultWalkSpeed * 0.6
		end
		

		calculationEnabled = false

		
	end

	
	if isAbility then
		if SpecialParams["Type"] == "Enhancer" and SpecialParams["Value"] then
			
			Power = SpecialParams["Value"]
			
			if PowerText.Visible == false then
				PowerText.Visible = true
			end

			PowerText.Text = "Power: "..Power
			
			currentanim = SpecialParams.Animation
			currentanim:Play()
			
			local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
			local rightGrip = char:FindFirstChild("RightHand"):FindFirstChild("RightGrip") or Tool:FindFirstChild("RightGrip", true)

		
		
			local FLY_HEIGHT = 15     -- Studs to float upwards
			local FLY_TIME = 0.5       -- Seconds to go up/down
			local HOVER_TIME = 1.5     -- Seconds to pause at the top


			task.spawn(function()


				if rightGrip and rightHand then
					
					
					humanoid.WalkSpeed = 0
					local startCFrame = Handle.CFrame
					local peakCFrame = startCFrame + Vector3.new(0, FLY_HEIGHT, 0)


					local tweenInfo = TweenInfo.new(FLY_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
					local tweenInfoDown = TweenInfo.new(FLY_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					local tweenUp = TweenService:Create(Handle, tweenInfo, {CFrame = peakCFrame})
					local originalOffset = rightGrip.C0 

					currentanim:GetMarkerReachedSignal(BALLFLOAT_MARKER):Wait()
					
					rightGrip:Destroy()
					Handle.Anchored = true

					
					

					
					
					tweenUp:Play()
					tweenUp.Completed:Wait()
					
					
					local peakY = peakCFrame.Y
					local hoverConnection
					local FORWARD_OFFSET = 5.5 
					local RIGHT_OFFSET = 1 -- Studs to the right (aligns with the right arm)

					hoverConnection = Runservice.Heartbeat:Connect(function()
						if cancontinue then
							hoverConnection:Disconnect()
							return
						end

						
						local forwardPosition = hrp.CFrame.Position 
							+ (hrp.CFrame.LookVector * FORWARD_OFFSET) 
							+ (hrp.CFrame.RightVector * RIGHT_OFFSET)

					
						local _, hrpYRotation, _ = hrp.CFrame:ToOrientation()

					
						Handle.CFrame = CFrame.new(forwardPosition.X, peakY, forwardPosition.Z) 
							* CFrame.Angles(0, hrpYRotation, 0)
					end)
					
					
					repeat
						task.wait()
					until cancontinue
					
			
					local currentHRPPos = hrp.CFrame.Position 
						+ (hrp.CFrame.LookVector * FORWARD_OFFSET) 
						+ (hrp.CFrame.RightVector * RIGHT_OFFSET)

					local _, hrpYRotation, _ = hrp.CFrame:ToOrientation()

				
					local landCFrame = CFrame.new(currentHRPPos.X, startCFrame.Y, currentHRPPos.Z) 
						* CFrame.Angles(0, hrpYRotation, 0)

					local tweenDown = TweenService:Create(Handle, tweenInfoDown, {CFrame = landCFrame})

					tweenDown:Play()
					
					task.wait(FLY_TIME * 0.6)
					cancontinuetweens = true

			
					
			

					

					
				end
			end)

			
			currentanim:GetMarkerReachedSignal(PAUSE_MARKER):Wait()
			
			if isAbility then
				local RightHand = char:FindFirstChild("RightHand")
				SpecialParams.EffectsTable["EnhancerBall"].Parent = RightHand
			end
			
				
			
			
			
			currentanim:AdjustSpeed(0) 
			
		

			
			inputConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					cancontinue = true
				
					if Handle.Anchored then
						local gripCheck = char:FindFirstChild("RightHand"):FindFirstChild("RightGrip")
						if gripCheck then gripCheck:Destroy() end
					end
					
					repeat task.wait() until cancontinuetweens
					currentanim:AdjustSpeed(1)
					
					executeThrow()
				end
			end)
		end
		
		if SpecialParams["Type"] == "GodSpeed" then
			Power = 500
			if PowerText.Visible == false then
				PowerText.Visible = true
			end

			PowerText.Text = "Power: "..Power

			
			inputConnection = UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					executeThrow()
				end
			end)
		end
	else
		inputConnection = UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				executeThrow()
			end
		end)

	end
	



	



	local targetPos = hrp.Position -- Fallback
	humanoid.AutoRotate = false 


	local mouse = player:GetMouse()
	mouse.TargetFilter = ExcludeWall
	local radius = 15
	




	local newIgnoreList = table.clone(ignoreList)
	table.insert(newIgnoreList,char)
	
	local overlapfilter = OverlapParams.new()
	overlapfilter.FilterType = Enum.RaycastFilterType.Exclude
	overlapfilter.FilterDescendantsInstances = newIgnoreList
	
	
	local rayfilter = RaycastParams.new()
	rayfilter.FilterType = Enum.RaycastFilterType.Exclude
	rayfilter.FilterDescendantsInstances = newIgnoreList
	
	local Playerteam =  (player.Team ~= nil) and player.Team
	if Playerteam then
		if Playerteam.Name == "Team1" or Playerteam.Name == Teams["Team1 Out"] then
			Playerteam = 1
		else
			Playerteam = 2
		end
	end
	
	repeat 

		local customTarget, customPosition = getCustomMouseData(camera,rayfilter,hrp)

		if customTarget and customTarget.Parent and customTarget.Parent ~= Target then
			
			local character = customTarget.Parent
			local charteam = character:GetAttribute("Team")
			
			if Playerteam and charteam and Playerteam == charteam then
				character = nil
			end
			
			local humanoid =  character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
		
					if currentbillboard then
						currentbillboard:Destroy()
						currentbillboard = nil 
					end
				if not currentbillboard then
				
					currentbillboard = BillBoard:Clone()
					currentbillboard.Parent = character
					currentbillboard.Enabled = true
				end
				
				Target = character
		
			end
		end

		if not customTarget then 
			Target = nil
			targetPos = mouse.Hit.Position
			if currentbillboard then
				currentbillboard:Destroy()
				currentbillboard = nil 
			end
		end

	
		
	
			targetPos = customPosition
	

		local flatTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
		local distance = (flatTarget - hrp.Position).Magnitude



		
		if isHoldingMouse == true  then
			if not SpecialParams or SpecialParams and SpecialParams.Type ~= "Enhancer" 
				and SpecialParams.Type ~= "GodSpeed" then
				
				Power = math.min(Power + PowerIncrement, 500)
				if PowerText.Visible == false then
					PowerText.Visible = true
				end
				
				PowerText.Text = "Power: "..Power
				
			end
				
				
		end

		Runservice.RenderStepped:Wait()

	until calculationEnabled == false

	task.delay(0.3,function()
		if Target and  Target:FindFirstChildOfClass("BillboardGui") then
			Target:FindFirstChildOfClass("BillboardGui"):Destroy()
		end
	end)

	

	targetPos = Target and Target.HumanoidRootPart and Target.HumanoidRootPart.Position or targetPos

	if Target then
		local targetHrp = nil

		if Target:IsA("Model") then
			targetHrp = Target:FindFirstChild("HumanoidRootPart")
		elseif Target:IsA("BasePart") then
			targetHrp = Target
		end

		if targetHrp then


			targetPos = getPredictedPosition(targetHrp,Handle.CFrame.Position , Power)
			if not targetPos then
				targetPos = Target.HumanoidRootPart.Position
			end
		elseif typeof(Target) == "Vector3" then
			targetPos = Target
		end
	end


	if humanoid then
		task.delay(currentanim.Length - currentanim.TimePosition,function()
			if isAbility and SpecialParams["Type"] == "GodSpeed" then

				humanoid.AutoRotate = true 
				
			else
				humanoid.WalkSpeed = DefaultWalkSpeed
				humanoid.AutoRotate = true 
			end
			
		end)
	end


	local GravityWeight = -Workspace.Gravity * 0.01
	local MassWeight = 1+ (Handle.Mass *-0.4)

	--MassWeight = 0


	local Origin = Handle.CFrame.Position
	local dir = (targetPos - Origin).Unit
	local Velocity -- = (dir * Power)
	local Acceleration = Vector3.new(0, GravityWeight + (MassWeight),0)
	local Lifetime = 10
	local MaxDistance = 1000
	local instance = Handle
	local detectionSize = Handle.Size
	local InitialUpwardImpulse = 100
	local Char = self.char


	local targetPosition = targetPos 

	local flatTargetPosition = Vector3.new(targetPosition.X, Origin.Y, targetPosition.Z)

	local directionToTarget = (flatTargetPosition - Origin).Unit


	local extendedTargetPosition = Origin + (directionToTarget * 600)


	local dir = (extendedTargetPosition - Origin).Unit




	Velocity = (dir * Power)




	local data = {
		Origin = Origin,
		Velocity = Velocity,
		Acceleration = Acceleration,
		Lifetime = Lifetime,
		MaxDistance = MaxDistance,
		instance = instance,
		detectionSize = detectionSize,
		InitialUpwardImpulse = InitialUpwardImpulse,
		Char = Char
	}
	local ClientTime = workspace:GetServerTimeNow()

	local FakeVisualBall = Handle:Clone()
	FakeVisualBall:ClearAllChildren() 
	FakeVisualBall.CanCollide = false
	FakeVisualBall.Anchored = true
	FakeVisualBall.Parent = workspace
	CollectionService:AddTag(FakeVisualBall,FAKEVISUALBALL)

	Handle.CanCollide = false

	if isAbility then
		if SpecialParams["Type"] == "Enhancer" then
			SpecialParams.EffectsTable["EnhancerBall"]:Destroy()
			SpecialParams.EffectsTable["EnhancerBallFlight"].Parent = FakeVisualBall
		end
		

	end
	
	
	
	
	

	local NewProjectile = 
		ProjectileService.new(
			Origin,Velocity,Acceleration,Lifetime,MaxDistance,FakeVisualBall,detectionSize,InitialUpwardImpulse,Char)

	
	NewProjectile:init()
	
	
	
	if isAbility then
		if SpecialParams["Type"] == "Enhancer" then
			local Cooldown = SpecialParams.cooldown
			self.cooldownDurations[self.currentstate] = Cooldown
			self.cooldownTimestamps[self.currentstate] = workspace:GetServerTimeNow() 
			task.delay(1,function()
				self.currentstate = States.Idle
			end)
			
			elseif SpecialParams["Type"] == "GodSpeed" then
			self.cooldownTimestamps[States.Attacking] = Workspace:GetServerTimeNow() 
			
		end
		
	else
		self.currentstate = States.Idle
		self.cooldownTimestamps[States.Attacking] = Workspace:GetServerTimeNow() 
		
	end
	
	if PowerText.Visible == true then
		PowerText.Visible = false
	end



	
end


local ParticleEmittersFolder = ReplicatedStorage:WaitForChild("ParticleEmitters")



local AbilityFunctions = {
	["AbilityEnhancer"] = function(self)
		
		local findtool = self.char:FindFirstChildOfClass("Tool")
		if not findtool or not findtool:HasTag("DodgeBall") then return end
		
		if self.currentstate == States.Dashing then return end
		if self.currentstate == States.Attacking then return end
		if self.currentstate == States.Blocking then return end
		
		local IsCooldown = self:IsOnCooldown(States.SpecialAbility)
		
		if IsCooldown then return end
		
		local CoolDown = math.huge
	
		self.currentstate = States.SpecialAbility
		self.cooldownDurations[self.currentstate] = CoolDown
		self.cooldownTimestamps[self.currentstate] = workspace:GetServerTimeNow() + CoolDown
	
		
	
		local Tool = findtool
		local ParticleEmitters = {}
		local SoundEffects = {}
		local Enhancer = Sounds:WaitForChild("Enhancer"):GetChildren()
		
		for name,particle in ParticleEmittersFolder:GetChildren() do
			local clone = particle:Clone()
			ParticleEmitters[particle.Name] = clone
		end
		
		for name,attachment in Enhancer do
			local clone = attachment:Clone()
			SoundEffects[attachment.Name] = clone
		end
		
		
		
		local CustomParams = {
			["Type"] = "Enhancer",
			["Value"] = 1000,
			["PauseMarker"] = "PauseEvent",
			["BallFloatMarker"] = "BallFloatEvent",
			["Animation"] = self.humanoid.Animator:LoadAnimation(Animations.ENHANCERTHROWANIM),
			["cooldown"] = 5,
			["EffectsTable"] = ParticleEmitters,
			["SoundEffects"] = SoundEffects
		}
		ThrowDodgeBall(self,Tool,CustomParams)
	end,

	["AbilityGodSpeed"] = function(self)
		
		if self.currentstate == States.Dashing then return end
		if self.currentstate == States.Attacking then return end
		if self.currentstate == States.Blocking then return end

		local CoolDown = 90
		local AbilityTimer = 600
		
		local IsCooldown = self:IsOnCooldown(States.SpecialAbility)
		if IsCooldown then return end
		
		local humanoid = self.humanoid
		local DefaultWalkSpeed = StarterPlayer.CharacterWalkSpeed
		
		local ParticleEmitters = {}

		for name,particle in ParticleEmittersFolder:GetChildren() do
			local clone = particle:Clone()
			ParticleEmitters[particle.Name] = clone
		end
		
		
		
		ParticleEmitters["GodSpeedAura"].Parent = self.char
		
		local SoundEffects = {}
		local GodSpeed = Sounds:WaitForChild("GodSpeed"):GetChildren()

		
		for name,attachment in GodSpeed do
			local clone = attachment:Clone()
			SoundEffects[attachment.Name] = clone
		end
		
		

		local GodSpeedActivate = SoundEffects.GodSpeedActivate
		GodSpeedActivate.Parent = self.char
		Debris:AddItem(GodSpeedActivate,5)
		
		for i,v in GodSpeedActivate:GetChildren() do
			if v and v:IsA("Sound") then
				v:Play()
			end
		end
	
		
		
		self.currentstate = States.SpecialAbility
		humanoid.WalkSpeed = DefaultWalkSpeed * 1.75
		
		local dashdefaultduration = self.cooldownDurations[States.Dashing]
		local attackdefaultduration = self.cooldownDurations[States.Attacking]
		
		self.cooldownDurations[States.Dashing] = 0.45
		self.cooldownDurations[States.Attacking] = 0.5
		self.cooldownTimestamps[self.currentstate] = workspace:GetServerTimeNow() + AbilityTimer
		
		self.cooldownDurations[self.currentstate] = CoolDown
		task.delay(AbilityTimer,function()
			humanoid.WalkSpeed = DefaultWalkSpeed * 0.6
			ParticleEmitters["GodSpeedAura"]:Destroy()
			self.currentstate = States.Idle
			self.cooldownDurations[States.Dashing] = dashdefaultduration
			self.cooldownDurations[States.Attacking] = attackdefaultduration
			task.wait(8)
			humanoid.WalkSpeed = DefaultWalkSpeed
		end)

	end,	


}






function StateMachine.GetStates()
	return States
end

function StateMachine.New(player,char)
	local self = setmetatable({}, {__index = StateMachine})
	
	self.player = player
	self.char = char
	self.humanoid = char:WaitForChild("Humanoid")
	self.humanoidRootPart = char:WaitForChild("HumanoidRootPart")
	self.currentstate = States.Idle

	
	self.cooldownTimestamps = {}
	self.animations = {}
	
	for i, v in Animations do
		self.animations[i] = self.humanoid.Animator:LoadAnimation(v)
	end

	self.cooldownDurations = {
		[States.Dashing] = 0.35,
		[States.Blocking] = 0.5,
		[States.Attacking] = 1.3,
		[States.Rebounding] = 0.5,
		[States.Passing] = 0.75
		
	}
	
	return self
end




function StateMachine:IsOnCooldown(state)
	local lastEnded = self.cooldownTimestamps[state]
	local duration = self.cooldownDurations[state]
	

	
	if not lastEnded or not duration then 
		return false 
	end


	local timePassed = workspace:GetServerTimeNow() - lastEnded
	return timePassed < duration
end



function StateMachine:StopAnimation(name)
	for i, v in self.animations do
		if i == name then
			if v.IsPlaying then
				v:Stop()
			end
			return
		end
	end
	return
end

function StateMachine:PlayAnimation(name)
	for i, v in self.animations do
		if i == name then
			if not v.IsPlaying then
				v:Play()
			end
			return
		end
	end
	return
end

function StateMachine:AbilityDash()
	local IsCooldown = self:IsOnCooldown(States.Dashing)
	local player, char = self.player, self.char
	if not player or not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local ability = player:GetAttribute("Ability")
	if ability ~= "GodSpeed" then return end

	
	if self.currentstate == States.Blocking or self.currentstate == States.Dashing then return end
	if self:IsOnCooldown(States.Dashing) then return end
	if char:GetAttribute("Blocking") == true then return end

	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid or isRagdolled(humanoid) then return end

	
	local Camera = workspace.CurrentCamera
	local camLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
	local camRight = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z).Unit

	local moveDirection = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then moveDirection += camLook end
	if UIS:IsKeyDown(Enum.KeyCode.S) then moveDirection -= camLook end
	if UIS:IsKeyDown(Enum.KeyCode.A) then moveDirection -= camRight end
	if UIS:IsKeyDown(Enum.KeyCode.D) then moveDirection += camRight end

	local rawLook = char.HumanoidRootPart.CFrame.LookVector
	local flatLook = Vector3.new(rawLook.X, 0, rawLook.Z).Unit
	local dashvector = moveDirection.Magnitude > 0 and moveDirection.Unit or flatLook

	
	local dashDistance = 10
	local newIgnoreList = table.clone(ignoreList or {})
	table.insert(newIgnoreList, char)

	local rayfilter = RaycastParams.new()
	rayfilter.FilterType = Enum.RaycastFilterType.Exclude
	rayfilter.FilterDescendantsInstances = newIgnoreList

	local rayCast = workspace:Raycast(char.HumanoidRootPart.Position, dashvector * dashDistance, rayfilter)
	if rayCast and rayCast.Instance then
		return
	end

	
	local godSpeedDashSfx = char:FindFirstChild("GodSpeedDash") 
		or (Sounds:FindFirstChild("GodSpeed") and Sounds.GodSpeed:FindFirstChild("GodSpeedDash"):Clone())

	if godSpeedDashSfx then
		if godSpeedDashSfx.Parent ~= char then
			godSpeedDashSfx.Parent = char
			Debris:AddItem(godSpeedDashSfx, 160)
		end

		for i,v in godSpeedDashSfx:GetChildren() do
			v.Parent = nil
			SoundService:PlayLocalSound(v)
			v.Parent = godSpeedDashSfx
		end
		
	end

	
	local dashPower = 10
	char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + (dashvector * dashPower)

	
	self.cooldownTimestamps[States.Dashing] = workspace:GetServerTimeNow()
end

function StateMachine:Block(userInputState)
	local player, char = self.player, self.char
	if not player or not char then return end
	if self:IsOnCooldown(States.Blocking) then return end

	if userInputState == Enum.UserInputState.Begin then

		if self.currentstate == States.Blocking then return end
		if self.currentstate == States.Dashing then return end
		if self.currentstate == States.SpecialAbility then return end
		
		if char:GetAttribute("IFrames") == true then return end


		self.currentstate = States.Blocking

		
		
		local blocked = Block:InvokeServer(char)



	elseif userInputState == Enum.UserInputState.End or userInputState == Enum.UserInputState.Cancel then
		
		if self.currentstate ~= States.Blocking then return end
		
		local stopblock = Block:InvokeServer(char, "Stop")
		
		self.cooldownTimestamps[States.Blocking] = Workspace:GetServerTimeNow()
		self.currentstate = States.Idle
	end
end

function StateMachine:Dash(userinputstate)
	if userinputstate ~= Enum.UserInputState.Begin then return end
	local player, char = self.player, self.char
	
	
	if self.currentstate == States.Blocking then return end
	if self.currentstate == States.Dashing then return end
	if self.currentstate == States.SpecialAbility then 
		self:AbilityDash()
		return end
	if not player or not char then return end
	
	local IsCooldown = self:IsOnCooldown(States.Dashing)
	
	if IsCooldown then return end
	self.currentstate = States.Dashing
	
	
	-- DASH MECHANIC
	
	 
		if char:GetAttribute("Blocking") == true then return end
		local humanoid = char:FindFirstChild("Humanoid")

		if humanoid and isRagdolled(humanoid)then
			return
		end
		
	local DashSfx = char:FindFirstChild("Dash") and char.Dash
		or Sounds:FindFirstChild("BasicSounds"):FindFirstChild("Dash"):Clone()
	
	if DashSfx.Parent ~= char then
		DashSfx.Parent = char
	end
		
		
	
		local Camera = workspace.CurrentCamera
		local camLook = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
		local camRight = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z).Unit

		local moveDirection = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then moveDirection += camLook end
		if UIS:IsKeyDown(Enum.KeyCode.S) then moveDirection -= camLook end
		if UIS:IsKeyDown(Enum.KeyCode.A) then moveDirection -= camRight end
		if UIS:IsKeyDown(Enum.KeyCode.D) then moveDirection += camRight end

		if not char.HumanoidRootPart then
			
			return 
		end
		local rawLook =  char.HumanoidRootPart.CFrame.LookVector
		local flatLook = Vector3.new(rawLook.X, 0, rawLook.Z).Unit
		local dashvector = moveDirection.Magnitude > 0 and moveDirection.Unit or flatLook

		local anim

		

		--anim:Play()
	--	anim:AdjustSpeed(3)

	
		local originalWalkSpeed = char.Humanoid.WalkSpeed
		char.Humanoid.WalkSpeed = 0

		local Dash = Instance.new("BodyVelocity")

		
		Dash.MaxForce = Vector3.new(math.huge, 0, math.huge)

		local initialSpeed = 125
		local currentVelocity = dashvector * initialSpeed
		Dash.Velocity = currentVelocity
		Dash.Parent = char.HumanoidRootPart

		char.HumanoidRootPart.CFrame = CFrame.lookAt(char.HumanoidRootPart.Position, char.HumanoidRootPart.Position + dashvector)
	
	


	
	for i,v in DashSfx:GetChildren() do
		v.Parent = nil
		SoundService:PlayLocalSound(v)
		v.Parent = DashSfx
	end
		DashRemote:FireServer()

	
		local dragCoefficient = 5.5 
		local dashDuration = 0.3
		
		local timePassed = 0

		while timePassed < dashDuration do
			local deltaTime = Runservice.Heartbeat:Wait()
			timePassed += deltaTime

			currentVelocity = currentVelocity * (1 - math.min(dragCoefficient * deltaTime, 1))
			Dash.Velocity = currentVelocity
		end

		
		Dash:Destroy()

		

	char.Humanoid.WalkSpeed = originalWalkSpeed
	
	
	self.cooldownTimestamps[States.Dashing] = Workspace:GetServerTimeNow()

	self.currentstate = States.Idle 


end








function StateMachine:Pass(UserInputState)
	if UserInputState ~= Enum.UserInputState.Begin then return end
	local player, char = self.player, self.char

	if self.currentstate == States.Passing then return end
	if self.currentstate == States.Blocking then return end
	if self.currentstate == States.Dashing then return end
	if self.currentstate == States.SpecialAbility then return end
	if not player or not char then return end
	
	local characterFiredTool = char:FindFirstChildOfClass("Tool")
	if not characterFiredTool then return end
	
	local IsCooldown = self:IsOnCooldown(States.Passing)

	if IsCooldown then return end
	
	self.currentstate = States.Passing
	local hrp = self.humanoidRootPart

	


	
	

	


	local Camera = workspace.CurrentCamera
	
	local newIgnoreList = table.clone(ignoreList)
	table.insert(newIgnoreList,char)
	
	local rayfilter = RaycastParams.new()
	rayfilter.FilterType = Enum.RaycastFilterType.Exclude
	rayfilter.FilterDescendantsInstances = newIgnoreList
	
	local spherecstparams = RaycastParams.new()
	spherecstparams.FilterType = Enum.RaycastFilterType.Exclude
	
	
	
	
	
	local customTarget, customPosition = getCustomMouseData(Camera,rayfilter,hrp,false,false,spherecstparams)
	
	
	
	
	if not char.HumanoidRootPart then
		return 
	end
	
	if customTarget then
		customTarget = customTarget.Parent 
			and customTarget.Parent:FindFirstChild("Humanoid") and customTarget or nil
		
	end
	
	PassRemote:FireServer(customTarget,customPosition)
	--anim:Play()
	--	anim:AdjustSpeed(3)


	self.currentstate = States.Idle 


end


function StateMachine:Rebound(userInputState)
	local player, char = self.player, self.char
	if not player or not char or not ReboundsEnabled then return end

	if userInputState ~= Enum.UserInputState.Begin then return end
	
	
	
		if self.currentstate == States.Blocking then return end
		if self.currentstate == States.Rebounding then return end
		if self.currentstate == States.Dashing then return end
		if self.currentstate == States.SpecialAbility then return end
		if self:IsOnCooldown(States.Rebounding) then return end
		if char:GetAttribute("IFrames") == true then return end

		
	self.currentstate = States.Rebounding
	
	local camera = workspace.CurrentCamera
	local hrp = self.humanoidRootPart
	
	local newIgnoreList = table.clone(ignoreList)
	table.insert(newIgnoreList,char)

	local rayfilter = RaycastParams.new()
	rayfilter.FilterType = Enum.RaycastFilterType.Exclude
	rayfilter.FilterDescendantsInstances = newIgnoreList
	
	
	local customTarget, customPosition = getCustomMouseData(camera,rayfilter,hrp,true,true)
	
	
	local pos = typeof(customPosition) == "Vector3" and customPosition or customPosition.Position
	
	instancepos.Position = pos
	if customTarget  then
	end
	if customTarget  then
		CatchRemote:FireServer(customTarget)
	end
	

		self.cooldownTimestamps[States.Rebounding] = Workspace:GetServerTimeNow()
		self.currentstate = States.Idle
	
end

function StateMachine:ThrowBall(Tool)
	

	if self.currentstate ~= States.Idle and self.currentstate ~= States.SpecialAbility then return end

	if self.currentstate == States.SpecialAbility then 
		local player, char = self.player, self.char
		local ability = player:GetAttribute("Ability")
		if ability == "GodSpeed" then
			
			local CustomParams = {
				["Type"] = "GodSpeed",
				["cooldown"] = 2,
				--["EffectsTable"] = ParticleEmitters
			}
			
			ThrowDodgeBall(self,Tool,CustomParams)
		end
	
		
		
		return end
	
	ThrowDodgeBall(self,Tool)
end


function StateMachine:UseAbility(UIS)
	if UIS ~= Enum.UserInputState.Begin then return end
	local player = self.player
	local Char = player.Character
	
	local Ability = player:GetAttribute("Ability")
	if not Ability then return end
	AbilityFunctions[`Ability{Ability}`](self)


end




function StateMachine:BindAbilityCooldownUI(cooldownTextLabel: TextLabel)
	if not cooldownTextLabel then return end

	
	self:UnbindAbilityCooldownUI()


	self.cooldownUIConnection = Runservice.RenderStepped:Connect(function()
		
		if not cooldownTextLabel or not cooldownTextLabel.Parent or not self.char or not self.char.Parent then
			self:UnbindAbilityCooldownUI()
			return
		end

		local ability = self.player:GetAttribute("Ability")

		if not ability then
			cooldownTextLabel.Text = ""
			return
		end

		local targetState = States.SpecialAbility
		if ability == "GodSpeed" and self.currentstate == States.Attacking then
			targetState = States.Attacking
		end

		local lastEnded = self.cooldownTimestamps[targetState]
		local duration = self.cooldownDurations[targetState]

		if not lastEnded or not duration then
			cooldownTextLabel.Text = ability .. ": Ready"
			return
		end

		local timePassed = workspace:GetServerTimeNow() - lastEnded
		local timeRemaining = duration - timePassed

		if timeRemaining > 0 then
			cooldownTextLabel.Text = string.format("%s: %.1fs", ability, timeRemaining)
		else
			cooldownTextLabel.Text = ability .. ": Ready"
		end
	end)
end

function StateMachine:UnbindAbilityCooldownUI()
	if self.cooldownUIConnection then
		self.cooldownUIConnection:Disconnect()
		self.cooldownUIConnection = nil
	end
end








function StateMachine:ReplicateThrow(func, data)
	local player = self.player
	if data.Char == player.Character then 
		return 
	end

	if func == "Throw" then
		local Origin = data.Origin
		local Velocity = data.Velocity
		local Acceleration = data.Acceleration
		local Lifetime = data.Lifetime
		local MaxDistance = data.MaxDistance
		local instance = data.instance
		local detectionSize = data.detectionSize
		local InitialUpwardImpulse = data.InitialUpwardImpulse
		local Char = data.Char

		

		if not instance  then return end


		local FakeVisualBall = instance:Clone()
		FakeVisualBall:ClearAllChildren() 
		FakeVisualBall.CFrame = CFrame.new(Origin) 
		FakeVisualBall.CanCollide = false
		FakeVisualBall.Anchored = true
		FakeVisualBall.Parent = workspace

		
		local projectileitem = ProjectileService.new(
			Origin,
			Velocity,
			Acceleration,
			Lifetime,
			MaxDistance,
			FakeVisualBall,
			detectionSize,
			InitialUpwardImpulse,
			Char,
			data.ServerTime 
		)

		projectileitem:init()
	end
end

function StateMachine:ReplicatePass(data)
	local targetchar = data.Target
	
	local player = self.player
	
	local tweeninfo = TweenInfo.new(0.25,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0)
	
	local goal = {
		Position = data.Target.HumanoidRootPart.Position
	}
	
	local FakeVisualBall = data.instance:Clone()
	FakeVisualBall:ClearAllChildren() 
	FakeVisualBall.CanCollide = false
	FakeVisualBall.Anchored = true
	FakeVisualBall.Parent = workspace
	
	
	local Tween = TweenService:Create(FakeVisualBall,tweeninfo,goal)
	Tween:Play()
	Tween.Completed:Connect(function()
		FakeVisualBall:Destroy()
	end)
	
end












return StateMachine
