local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Explode = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Explode")
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local JumpVal,SpeedVal, currentMech, rootPart, velocity:LinearVelocity, gyro, playerHumanoid, mechHumanoid, currentSeat = nil, nil, nil, nil, nil, nil, nil, nil,nil
local RightHandJet, LeftHandJet, LeftLegJet,RightLegJet = nil, nil,nil,nil
local PLayerGui = Player:WaitForChild("PlayerGui")
local MechGui = PLayerGui:WaitForChild("MechGui")
local Jets = {}

-- Settings
local SPRINT_MIN = 17
local SPEED = 10
local JUMP_IMPULSE = 100 
local JUMP_COOLDOWN = 2
local ORIGINAL_HIP_HEIGHT = 23.532

local GROUND_TURN_SPEED = 15    
local AIR_TURN_SPEED = 5      
local MAX_AIR_TORQUE = 10^7   
local GROUND_TORQUE = 10^8

local LEAN_SIDE = 8  -- Degrees to tilt left/right when strafing
local LEAN_FRONT = 4 -- Degrees to tilt forward when walking



local MechSounds = SoundService:WaitForChild("MechSounds")
local JetEngine = MechSounds:WaitForChild("Jet Engine Hold")
local Click = MechSounds:WaitForChild("menu_click")




-- Animation
local WalkTrack = nil
local WALK_ANIM_ID = "rbxassetid://79068176850344" 

local IdleTrack = nil
local IDLE_ANIM_ID = "rbxassetid://139248867090437" 


local JumpTrack = nil
local JUMP_ANIM_ID = "rbxassetid://133164469523616" 

local RunTrack = nil
local RUN_ANIM_ID = "rbxassetid://94492453797237" 

local LeftTrack = nil
local LEFT_ANIM_ID = "rbxassetid://94683352171756" 


local RightTrack = nil
local RIGHT_ANIM_ID = "rbxassetid://112967288395021" 

local UpTrack = nil
local UP_ANIM_ID = "rbxassetid://123762260933915" 

local DownTrack = nil
local DOWN_ANIM_ID = "rbxassetid://117914828568108" 

local FlightIdleTrack = nil
local FLIGHTIDLE_ANIM_ID = "rbxassetid://90044103423152" 


local FowardTrack = nil
local FOWARD_ANIM_ID = "rbxassetid://82442415701106" 


local BackWardTrack = nil
local BACKWARD_ANIM_ID = "rbxassetid://136670541474660" 




local flightState = FlightIdleTrack


local FlightMode = false





local CurrentJumpVal = nil
local JumpStartTime = nil
local JumpState = "Ready"


--[[
"Ready"
"Charging"
"Launched"
"CoolDown"
]]




local function SetJetRotation(angleVector)
	for _, jet in pairs(Jets) do
		if jet then
			local emitter = jet:FindFirstChildOfClass("ParticleEmitter")
			if emitter then
				emitter.Orientation = angleVector
			end
		end
	end
end


local function ChargeJump(JumpVal,dt)
	if FlightMode then return end
	local adjustval = math.clamp(JumpVal.Value * 1.005+dt, 100, 500)

	JumpVal.Value = adjustval
	
end










UIS.InputBegan:Connect(function(input, processed)
	if processed or not currentMech  then return end
	
	
	
	
	if input.KeyCode == Enum.KeyCode.Space and JumpState == "Ready" then
		JumpState = "Charging"
		CurrentJumpVal = JumpVal.Value
		JumpStartTime = tick()
		
		for _, track in pairs(mechHumanoid.Animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end
		JumpTrack:Play()
		task.wait(0.4)
		
		if JumpState == "Charging" then
			JumpTrack:AdjustSpeed(0)
		end
	
	end


	
	
	if input.KeyCode == Enum.KeyCode.F and currentMech then
		FlightMode = not FlightMode
		
		
		mechHumanoid.PlatformStand = not mechHumanoid.PlatformStand
		Click:Play()
		if not FlightMode then
			
			for _, jet in pairs(Jets) do
				if jet then
					local emitter = jet:FindFirstChildOfClass("ParticleEmitter")
					if emitter then
						emitter.Enabled = false
					end
				end
			end
			
			JetEngine:Stop()
			mechHumanoid.HipHeight = ORIGINAL_HIP_HEIGHT
			velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
			for _, track in pairs(mechHumanoid.Animator:GetPlayingAnimationTracks()) do
				track:Stop(0.5)
			end
			IdleTrack:Play(0.5)
			JumpState = "Ready"
		else
			
			for _, jet in pairs(Jets) do
				if jet then
					local emitter = jet:FindFirstChildOfClass("ParticleEmitter")
					if emitter then
						emitter.Enabled = true
					end
				end
			end
			
			JetEngine:Play()
			mechHumanoid.HipHeight = 0
			
		end
			
			
	end
	
	
end)


UIS.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.K  then
		
		MechGui.Enabled = false
		task.wait(0.1)
		
		Explode:FireServer(currentSeat,rootPart)
		local sound = rootPart:FindFirstChild("explosion")
		sound:Play()
		task.wait(0.5)

	end
	
	if processed or not currentMech or FlightMode then return end

	
	if currentSeat and input.KeyCode == Enum.KeyCode.H and JumpState == "Ready" and not FlightMode then
	
			currentSeat:Sit(nil)
		MechGui.Enabled = false
	end

	
	if input.KeyCode == Enum.KeyCode.Space and JumpState == "Charging"  and rootPart then
		
	   JumpState = "Launched"
		
		local ticknow = tick()
		local chargeduration = ticknow - JumpStartTime
		
		
	
		
		
		local timeelapsed = JumpTrack.Length - JumpTrack.TimePosition
		local timetowait = 0.4
		
		
		RunTrack:Stop()
		WalkTrack:Stop()
		
		local targetTime
		local HipHeightSpeedOffSet = 20
		
		
		task.spawn(function()
			if JumpVal.Value < 120  then

				 targetTime = 1
				task.wait(targetTime)
				JumpTrack:AdjustSpeed(0.6)




			elseif JumpVal.Value >= 120  then
		
				 targetTime = 1.2
				JumpTrack:AdjustSpeed(1)
				repeat task.wait() until JumpTrack.TimePosition >= targetTime
				JumpTrack:AdjustSpeed(0.1)
				
				
			end

		end)
		
		
		if JumpVal.Value < 120  then
			task.wait(targetTime)
		elseif JumpVal.Value >= 120  then
			task.wait(targetTime*0.70)
			
		end
		
	
		mechHumanoid.PlatformStand = true
		mechHumanoid.HipHeight = 0

		
		rootPart.AssemblyLinearVelocity = Vector3.new(
			rootPart.AssemblyLinearVelocity.X, 
			JumpVal.Value, 
			rootPart.AssemblyLinearVelocity.Z
		)
	
		task.wait(0.2)
			
		
		
		
	
		
			
			while true  do
				task.wait()
				
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {currentMech, Player.Character}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local floorCheck = workspace:Raycast(rootPart.Position, Vector3.new(0, -(ORIGINAL_HIP_HEIGHT + HipHeightSpeedOffSet), 0), rayParams)
				
			if  not floorCheck and not FlightMode or rootPart.AssemblyLinearVelocity.Y < 0 then
					continue
					
				else
					if FlightMode then
					

						break
				end
				
				local impactAttachment = rootPart:FindFirstChild("ImpactAttachment")

				if impactAttachment then
					local dust = impactAttachment:FindFirstChild("DustEmitter")
					local shock = impactAttachment:FindFirstChild("ShockwaveEmitter")
					local sound = impactAttachment:FindFirstChild("ImpactSound")
					
					
					
					
					if dust then
						local alpha = math.clamp((JumpVal.Value - 100) / (500 - 100), 0, 1)
						local emitCount = 20 + (60 * alpha)
						
						dust:Emit(emitCount)
						
					end

					if shock then
						shock:Emit(1)
					end

					if sound then
						sound:Play()
					end
				end
				
				
				
				
				
				
				
					JumpTrack:Stop(0.5)
					JumpVal.Value = CurrentJumpVal
					
					
					
						
						IdleTrack:Play(0.5)
						
						JumpState = "CoolDown" 
						task.wait(JUMP_COOLDOWN)
					
					
					JumpState  =  "Ready"


						
					
					
					break
				end
				
			end
		
		end
	
	
	
		
		
end)





RunService.Heartbeat:Connect(function(deltatimne)
	if not (currentMech and rootPart and velocity and mechHumanoid and gyro) then return end
	
	local function MovementPhysics()
		
		
		
		if JumpState == "Charging" or JumpState == "CoolDown" then
			velocity.PlaneVelocity = Vector2.zero
			return
		end
		
		local isMidAir = false
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {currentMech, Player.Character}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local floorCheck = workspace:Raycast(rootPart.Position, Vector3.new(0, -(ORIGINAL_HIP_HEIGHT + 10), 0), rayParams)

		if not floorCheck then isMidAir = true end

		if isMidAir then

			gyro.Responsiveness = AIR_TURN_SPEED
			gyro.MaxTorque = MAX_AIR_TORQUE 
		else
			gyro.Responsiveness = GROUND_TURN_SPEED
			gyro.MaxTorque = GROUND_TORQUE 
			if rootPart.AssemblyLinearVelocity.Y < -5 then
				rootPart.AssemblyLinearVelocity *= Vector3.new(1, 0.8, 1)
				mechHumanoid.HipHeight = ORIGINAL_HIP_HEIGHT
				mechHumanoid.PlatformStand = false
			end
		end

	
		local moveDir = Vector3.new(0, 0, 0)
		local camF = Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local camR = Camera.CFrame.RightVector * Vector3.new(1, 0, 1)

		local sideLean = 0
		local frontLean = 0

		
		if UIS:IsKeyDown(Enum.KeyCode.W) then 
			moveDir += camF 
			frontLean -= math.rad(LEAN_FRONT) -- Lean forward
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then 
			moveDir -= camF 
			frontLean += math.rad(LEAN_FRONT) -- Lean back
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then 
			moveDir -= camR 
			sideLean -= math.rad(LEAN_SIDE) -- Lean left
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then 
			moveDir += camR 
			sideLean += math.rad(LEAN_SIDE) -- Lean right
		end
		
		
		
	
		local baseCF = CFrame.lookAt(Vector3.zero, camF.Unit)

		
		local tiltCF = CFrame.Angles(frontLean, 0, -sideLean)

		
		gyro.CFrame = baseCF * tiltCF

	
		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
			velocity.PlaneVelocity = Vector2.new(moveDir.X * SpeedVal.Value, moveDir.Z * SpeedVal.Value)

		
			if WalkTrack  and not WalkTrack.IsPlaying and not JumpTrack.IsPlaying and SpeedVal.Value < 17 then
				RunTrack:Stop(0.5)
				IdleTrack:Stop(0.5)
				WalkTrack:Play(0.5)
			end




			if RunTrack and not RunTrack.IsPlaying and not JumpTrack.IsPlaying and SpeedVal.Value >= 17 then 

				IdleTrack:Stop(0.5)
				WalkTrack:Stop(0.5)
				RunTrack:Play(0.5)


			end

		else

			velocity.PlaneVelocity = Vector2.zero

			

			if WalkTrack and WalkTrack.IsPlaying or RunTrack and RunTrack.IsPlaying then
			
				RunTrack:Stop(0.5)
				WalkTrack:Stop(0.5)
				IdleTrack:Play(0.5)



			end
		end
	end
	if not FlightMode then
		MovementPhysics()
	end
	local function FlightPhsyics()
	
		
		if WalkTrack.IsPlaying or RunTrack.IsPlaying then
			WalkTrack:Stop(0.5)
			RunTrack:Stop(0.5)
			IdleTrack:Play()
		end
		
		

		

			gyro.Responsiveness = AIR_TURN_SPEED
			gyro.MaxTorque = MAX_AIR_TORQUE 
		

		local moveDir = Vector3.new(0, 0, 0)
		local camF = Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local camR = Camera.CFrame.RightVector * Vector3.new(1, 0, 1)
		local WorldUp = Vector3.new(0, 1, 0)
		
		
		local sideLean = 0
		local frontLean = 0
		
		
		
		
		
		if UIS:IsKeyDown(Enum.KeyCode.W) then 
			moveDir += camF 
			frontLean -= math.rad(LEAN_FRONT) -- Lean forward
			flightState = FowardTrack

		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then 
			moveDir -= camF 
			frontLean += math.rad(LEAN_FRONT) -- Lean back
			flightState = BackWardTrack
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then 
			moveDir -= camR 
			sideLean -= math.rad(LEAN_SIDE) -- Lean left
			flightState = LeftTrack
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then 
			moveDir += camR 
			sideLean += math.rad(LEAN_SIDE) -- Lean right
			flightState = RightTrack
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then 
			moveDir += WorldUp
			flightState = UpTrack
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then 
			moveDir -= WorldUp
			flightState = DownTrack
		end
		
		
		
		
		local baseCF = CFrame.lookAt(Vector3.zero, camF.Unit)
	
	
		local tiltCF = CFrame.Angles(frontLean, 0, -sideLean)

		
		gyro.CFrame = baseCF * tiltCF
		
	
		
		if moveDir.Magnitude > 0 then
			
			
			moveDir = moveDir.Unit
			
			velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			velocity.VectorVelocity = Vector3.new(moveDir.X * SpeedVal.Value,moveDir.Y * SpeedVal.Value, moveDir.Z * SpeedVal.Value)

		
			

			
			if not  flightState.IsPlaying then
				for _, track in pairs(mechHumanoid.Animator:GetPlayingAnimationTracks()) do
					track:Stop(0.3)
				end
				flightState:Play()
				end
				
		


			

		else
			
			if not FlightIdleTrack.IsPlaying then
				for _, track in pairs(mechHumanoid.Animator:GetPlayingAnimationTracks()) do
					track:Stop(0.3)
				end
				flightState = FlightIdleTrack
				flightState:Play()
			end
			
			velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			
			velocity.VectorVelocity = Vector3.new(0,0.1, 0)
			RunTrack:Stop(0.5)
			WalkTrack:Stop(0.5)
			IdleTrack:Play(0.5)
		

			
		end
	end
	if FlightMode then
		FlightPhsyics()
	end
	
	if JumpState == "Charging" then
		
		ChargeJump(JumpVal,deltatimne)
	end
	
	
	
end)

local function setupCharacter(char)
	playerHumanoid = char:WaitForChild("Humanoid")
	playerHumanoid.Seated:Connect(function(active, seat)
		if active and seat:IsA("Seat") and seat.Parent:FindFirstChild("Humanoid") then
			
			
			
			currentSeat, currentMech = seat, seat.Parent
			mechHumanoid = currentMech:FindFirstChildOfClass("Humanoid")
			
			
			
			
			local animator = mechHumanoid:FindFirstChildOfClass("Animator")
			
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = mechHumanoid
			end

			local anim = Instance.new("Animation")
			anim.AnimationId = WALK_ANIM_ID

			WalkTrack = animator:LoadAnimation(anim)
			WalkTrack.Priority = Enum.AnimationPriority.Movement
			WalkTrack.Looped = true
			
			local anim = Instance.new("Animation")
			anim.AnimationId = IDLE_ANIM_ID
			
			IdleTrack = animator:LoadAnimation(anim)
			IdleTrack.Priority = Enum.AnimationPriority.Movement
			IdleTrack.Looped = true
			
			local anim = Instance.new("Animation")
			anim.AnimationId = JUMP_ANIM_ID

			JumpTrack = animator:LoadAnimation(anim)
			JumpTrack.Priority = Enum.AnimationPriority.Movement
			JumpTrack.Looped = false
			
			local anim = Instance.new("Animation")
			anim.AnimationId = RUN_ANIM_ID

			RunTrack = animator:LoadAnimation(anim)
			RunTrack.Priority = Enum.AnimationPriority.Movement
			RunTrack.Looped = true
			
			


			

			
			

			
			
			
			local anim = Instance.new("Animation")
			anim.AnimationId = LEFT_ANIM_ID

			LeftTrack = animator:LoadAnimation(anim)
			LeftTrack.Priority = Enum.AnimationPriority.Movement
			LeftTrack.Looped = true
			
			local anim = Instance.new("Animation")
			anim.AnimationId = RIGHT_ANIM_ID

			RightTrack = animator:LoadAnimation(anim)
			RightTrack.Priority = Enum.AnimationPriority.Movement
			RightTrack.Looped = true
			
			local anim = Instance.new("Animation")
			anim.AnimationId = UP_ANIM_ID

			UpTrack = animator:LoadAnimation(anim)
			UpTrack.Priority = Enum.AnimationPriority.Movement
			UpTrack.Looped = true
			
			
			local anim = Instance.new("Animation")
			anim.AnimationId = DOWN_ANIM_ID

			DownTrack = animator:LoadAnimation(anim)
			DownTrack.Priority = Enum.AnimationPriority.Movement
			DownTrack.Looped = true
			
			local anim = Instance.new("Animation")
			anim.AnimationId = FLIGHTIDLE_ANIM_ID

			FlightIdleTrack = animator:LoadAnimation(anim)
			FlightIdleTrack.Priority = Enum.AnimationPriority.Movement
			FlightIdleTrack.Looped = true


			local anim = Instance.new("Animation")
			anim.AnimationId = FOWARD_ANIM_ID

			FowardTrack = animator:LoadAnimation(anim)
			FowardTrack.Priority = Enum.AnimationPriority.Movement
			FowardTrack.Looped = true

			

			local anim = Instance.new("Animation")
			anim.AnimationId = BACKWARD_ANIM_ID

			BackWardTrack = animator:LoadAnimation(anim)
			BackWardTrack.Priority = Enum.AnimationPriority.Movement
			BackWardTrack.Looped = true

			
			
			
			
			SpeedVal = Instance.new("IntValue")
			SpeedVal.Parent = currentMech
			SpeedVal.Name = "Speed"
			SpeedVal.Value = 10
			
			JumpVal = Instance.new("NumberValue")
			JumpVal.Parent = currentMech
			JumpVal.Name = "Jump"
			JumpVal.Value = JUMP_IMPULSE
			
			
			rootPart = currentMech.HumanoidRootPart
			velocity = rootPart:FindFirstChildWhichIsA("LinearVelocity")
			gyro = rootPart:FindFirstChildWhichIsA("AlignOrientation")
			playerHumanoid.JumpHeight = 0
			
			MechGui.Enabled = true
			IdleTrack:Play(1)
			
			RightHandJet = currentMech:FindFirstChild("RightHand"):FindFirstChild("RightJet")
			LeftHandJet = currentMech:FindFirstChild("LeftHand"):FindFirstChild("LeftJet")
			LeftLegJet = currentMech:FindFirstChild("LeftLowerLeg"):FindFirstChild("LeftLegJet")
			RightLegJet = currentMech:FindFirstChild("RightLowerLeg"):FindFirstChild("RightLegJet")
			Jets = {RightHandJet, LeftHandJet, LeftLegJet,RightLegJet}
			
			
		else
			
			if WalkTrack then
				WalkTrack:Stop()
				WalkTrack = nil
			end
			
			if IdleTrack then
				IdleTrack:Stop()
				IdleTrack = nil
			end
			
			
			if playerHumanoid then playerHumanoid.JumpHeight = 7.2 end
			if mechHumanoid then
				mechHumanoid.HipHeight = ORIGINAL_HIP_HEIGHT
				mechHumanoid.PlatformStand = false
			end
		
			SpeedVal, currentMech, rootPart, velocity, gyro, currentSeat, mechHumanoid = nil, nil, nil, nil, nil, nil, nil
			RightHandJet, LeftHandJet, LeftLegJet,RightLegJet = nil, nil, nil, nil
			Jets = nil
		end
	end)
end
if Player.Character then setupCharacter(Player.Character) end
Player.CharacterAdded:Connect(setupCharacter)
