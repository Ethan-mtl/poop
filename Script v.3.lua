-->> Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-->> Player & Character refs
local player   = Players.LocalPlayer
local char     = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp      = char:WaitForChild("HumanoidRootPart")

-->> State & Defaults
local defaultWalkSpeed = humanoid.WalkSpeed
local defaultJumpPower = humanoid.JumpPower
local states = {
  fly       = false,
  noclip    = false,
  infJump   = false,
  speed     = false,
  jumpBoost = false,
  infHealth = false
}

-- Fly internals
local flyingEnabled = false
local flyConn, flyBG, flyBV
local infJumpConn, noclipConn, infHealthConn

-- Refresh on respawn
player.CharacterAdded:Connect(function(c)
  char     = c
  humanoid = c:WaitForChild("Humanoid")
  hrp      = c:WaitForChild("HumanoidRootPart")
  defaultWalkSpeed = humanoid.WalkSpeed
  defaultJumpPower = humanoid.JumpPower
end)

-->> Features

-- Fly (BodyGyro + BodyVelocity)
local function toggleFly()
  if not hrp then return end
  flyingEnabled = not flyingEnabled

  if flyingEnabled then
    flyBG = Instance.new("BodyGyro")
    flyBG.P = 9e4
    flyBG.MaxTorque = Vector3.new(9e4,9e4,9e4)
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e4,9e4,9e4)
    flyBV.Velocity = Vector3.new(0,0,0)
    flyBV.Parent = hrp

    flyConn = RunService.Heartbeat:Connect(function()
      local camCF = workspace.CurrentCamera.CFrame
      local dir = Vector3.new()

      if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camCF.LookVector end
      if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camCF.LookVector end
      if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camCF.RightVector end
      if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camCF.RightVector end
      if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
      if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

      if dir.Magnitude > 0 then dir = dir.Unit * 50 end

      flyBV.Velocity = dir
      flyBG.CFrame   = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)
  else
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
  end
end

-- No-Clip
local function toggleNoClip()
  states.noclip = not states.noclip
  if noclipConn then noclipConn:Disconnect() noclipConn = nil end

  if states.noclip then
    noclipConn = RunService.Stepped:Connect(function()
      for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
      end
    end)
  else
    for _, p in ipairs(char:GetDescendants()) do
      if p:IsA("BasePart") then p.CanCollide = true end
    end
  end
end

-- Infinite Jump
local function toggleInfJump()
  states.infJump = not states.infJump
  if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end

  if states.infJump then
    infJumpConn = UserInputService.JumpRequest:Connect(function()
      humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
  end
end

-- Speed Boost
local function toggleSpeed()
  states.speed = not states.speed
  humanoid.WalkSpeed = states.speed and 100 or defaultWalkSpeed
end

-- Jump Boost
local function toggleJumpBoost()
  states.jumpBoost = not states.jumpBoost
  humanoid.JumpPower = states.jumpBoost and 200 or defaultJumpPower
end

-- Infinite Health
local function toggleInfHealth()
  states.infHealth = not states.infHealth
  if infHealthConn then infHealthConn:Disconnect() infHealthConn = nil end

  if states.infHealth then
    infHealthConn = RunService.Stepped:Connect(function()
      humanoid.Health = humanoid.MaxHealth
    end)
  end
end

-- Decal Spam Feature 
local function toggleDecalSpam()
  local decalId = "rbxassetid://114172038084163"

  local function applyDecals(part)
    for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
      local decal = Instance.new("Decal")
      decal.Texture = decalId
      decal.Face = face
      decal.Parent = part
    end
  end

  for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj:IsDescendantOf(char) then
      applyDecals(obj)
      obj.Material = Enum.Material.Neon
      obj.Color = Color3.fromRGB(255, 0, 0)
    end
  end

  local sky = Instance.new("Sky")
  sky.SkyboxBk = decalId
  sky.SkyboxDn = decalId
  sky.SkyboxFt = decalId
  sky.SkyboxLf = decalId
  sky.SkyboxRt = decalId
  sky.SkyboxUp = decalId
  sky.Parent = game:GetService("Lighting")

  for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player and plr.Character and plr.Character:FindFirstChild("Torso") then
      local particle = Instance.new("ParticleEmitter")
      particle.Texture = decalId
      particle.Rate = 50
      particle.Parent = plr.Character.Torso
    end
  end
end

-- Teleport Everyone to Me (Client-Sided)
local function teleportEveryoneToMe()
  if not hrp then return end
  for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
      plr.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
    end
  end
end

-->> GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name        = "SuperScriptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent      = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size            = UDim2.new(0,200,0,320)
frame.Position        = UDim2.new(0,20,0,100)
frame.BackgroundColor3= Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent          = screenGui

local function makeButton(label, y, fn)
  local btn = Instance.new("TextButton", frame)
  btn.Size            = UDim2.new(1,-10,0,30)
  btn.Position        = UDim2.new(0,5,0,y)
  btn.BackgroundColor3= Color3.fromRGB(50,50,50)
  btn.BorderSizePixel = 0
  btn.Font            = Enum.Font.SourceSansBold
  btn.TextSize        = 18
  btn.TextColor3      = Color3.new(1,1,1)
  btn.Text            = label
  btn.MouseButton1Click:Connect(fn)
  return btn
end

-- Button layout
makeButton("Toggle Fly",         10,  toggleFly)
makeButton("Toggle No-Clip",     50,  toggleNoClip)
makeButton("Toggle Inf Jump",    90,  toggleInfJump)
makeButton("Toggle Speed Boost", 130, toggleSpeed)
makeButton("Toggle Jump Boost",  170, toggleJumpBoost)
makeButton("Toggle Inf Health",  210, toggleInfHealth)
makeButton("Toggle Decal Spam",  250, toggleDecalSpam)
makeButton("Teleport All to Me", 290, teleportEveryoneToMe)

