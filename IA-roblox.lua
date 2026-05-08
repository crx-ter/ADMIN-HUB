local Players=game:GetService("Players")
local TS=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local HS=game:GetService("HttpService")
local WS=game:GetService("Workspace")
local LP=Players.LocalPlayer
local Mouse=LP:GetMouse()
local Cam=WS.CurrentCamera
local GUI=LP:WaitForChild("PlayerGui")
local req=(request or http_request or (syn and syn.request))
local CONFIG={Version="2.3",OpenRouterBase="https://openrouter.ai/api/v1/chat/completions",Models={Coder="qwen/qwen3-coder:free",Reason="meta-llama/llama-3.3-70b-instruct:free",Fast="google/gemma-3-27b-it:free"},CurrentModel="qwen/qwen3-coder:free",Colors={Bg=Color3.fromRGB(24,24,26),Sidebar=Color3.fromRGB(30,30,32),Accent=Color3.fromRGB(10,132,255),Text=Color3.fromRGB(242,242,247),Element=Color3.fromRGB(44,44,46)},Key=""}
local State={Flying=false,InfJump=false,ClickTP=false,Points={},ChatHistory={},KeyVerified=false,CurrentTab="Chat",FlyConn=nil}
local function Create(cls,props) local o=Instance.new(cls);for k,v in pairs(props) do if type(k)=="number" then v.Parent=o else o[k]=v end end;return o;end
local function Rnd(p,r) return Create("UICorner",{Parent=p,CornerRadius=UDim.new(0,r or 12)}) end
local function Tw(o,p,t) TS:Create(o,TweenInfo.new(t or 0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p):Play() end
local CoreUI=Create("ScreenGui",{Name="KaelenV2",Parent=GUI,ResetOnSpawn=false,IgnoreGuiInset=true})
local FloatBtn=Create("TextButton",{Parent=CoreUI,Size=UDim2.new(0,50,0,50),Position=UDim2.new(0.9,-60,0.5,0),BackgroundColor3=CONFIG.Colors.Accent,Text="K",TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=24})
Rnd(FloatBtn,25)
local MainFrame=Create("Frame",{Parent=CoreUI,Size=UDim2.new(0,550,0,380),Position=UDim2.new(0.5,-275,0.5,-190),BackgroundColor3=CONFIG.Colors.Bg,Visible=false,ClipsDescendants=true})
Rnd(MainFrame)
local TopBar=Create("Frame",{Parent=MainFrame,Size=UDim2.new(1,0,0,40),BackgroundColor3=CONFIG.Colors.Sidebar})
local Title=Create("TextLabel",{Parent=TopBar,Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text="Kaelen v"..CONFIG.Version.." | AI Systems",TextColor3=CONFIG.Colors.Text,Font=Enum.Font.GothamMedium,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left})
local CloseBtn=Create("TextButton",{Parent=TopBar,Size=UDim2.new(0,40,0,40),Position=UDim2.new(1,-40,0,0),BackgroundTransparency=1,Text="X",TextColor3=CONFIG.Colors.Text,Font=Enum.Font.GothamBold,TextSize=16})
local Sidebar=Create("Frame",{Parent=MainFrame,Size=UDim2.new(0,120,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=CONFIG.Colors.Sidebar})
local Content=Create("Frame",{Parent=MainFrame,Size=UDim2.new(1,-120,1,-40),Position=UDim2.new(0,120,0,40),BackgroundTransparency=1})
local KeyPanel=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,1,0),BackgroundColor3=CONFIG.Colors.Bg,ZIndex=10})
local KeyInput=Create("TextBox",{Parent=KeyPanel,Size=UDim2.new(0.8,0,0,40),Position=UDim2.new(0.1,0,0.3,0),BackgroundColor3=CONFIG.Colors.Element,TextColor3=CONFIG.Colors.Text,PlaceholderText="Ingresa tu API Key de OpenRouter...",Font=Enum.Font.Gotham,TextSize=14})
Rnd(KeyInput,8)
local KeySave=Create("TextButton",{Parent=KeyPanel,Size=UDim2.new(0.8,0,0,40),Position=UDim2.new(0.1,0,0.5,0),BackgroundColor3=CONFIG.Colors.Accent,TextColor3=Color3.new(1,1,1),Text="Verificar y Guardar",Font=Enum.Font.GothamBold,TextSize=14})
Rnd(KeySave,8)
local ChatPnl=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false})
local ChatScroll=Create("ScrollingFrame",{Parent=ChatPnl,Size=UDim2.new(1,-20,1,-60),Position=UDim2.new(0,10,0,10),BackgroundTransparency=1,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y})
Create("UIListLayout",{Parent=ChatScroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)})
local ChatBox=Create("TextBox",{Parent=ChatPnl,Size=UDim2.new(1,-80,0,36),Position=UDim2.new(0,10,1,-46),BackgroundColor3=CONFIG.Colors.Element,TextColor3=CONFIG.Colors.Text,PlaceholderText="Escribe un comando a Kaelen...",Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
Rnd(ChatBox,8)
Create("UIPadding",{Parent=ChatBox,PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
local ChatSend=Create("TextButton",{Parent=ChatPnl,Size=UDim2.new(0,50,0,36),Position=UDim2.new(1,-60,1,-46),BackgroundColor3=CONFIG.Colors.Accent,TextColor3=Color3.new(1,1,1),Text=">",Font=Enum.Font.GothamBold,TextSize=18})
Rnd(ChatSend,8)
local ModesPnl=Create("ScrollingFrame",{Parent=Content,Size=UDim2.new(1,-20,1,-20),Position=UDim2.new(0,10,0,10),BackgroundTransparency=1,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false})
Create("UIListLayout",{Parent=ModesPnl,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,10)})
local ToolsPnl=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false})
local AddPointBtn=Create("TextButton",{Parent=ToolsPnl,Size=UDim2.new(0.9,0,0,36),Position=UDim2.new(0.05,0,0,10),BackgroundColor3=CONFIG.Colors.Accent,TextColor3=Color3.new(1,1,1),Text="Guardar Checkpoint",Font=Enum.Font.GothamBold,TextSize=14})
Rnd(AddPointBtn,8)
local PointsScroll=Create("ScrollingFrame",{Parent=ToolsPnl,Size=UDim2.new(0.9,0,1,-66),Position=UDim2.new(0.05,0,0,56),BackgroundTransparency=1,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y})
Create("UIListLayout",{Parent=PointsScroll,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)})
local StatsPnl=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false})
local FPSLbl=Create("TextLabel",{Parent=StatsPnl,Size=UDim2.new(0.8,0,0,40),Position=UDim2.new(0.1,0,0.1,0),BackgroundColor3=CONFIG.Colors.Element,TextColor3=CONFIG.Colors.Text,Text=" FPS: Cargando...",Font=Enum.Font.Gotham,TextSize=16})
Rnd(FPSLbl,8)
local PingLbl=Create("TextLabel",{Parent=StatsPnl,Size=UDim2.new(0.8,0,0,40),Position=UDim2.new(0.1,0,0.3,0),BackgroundColor3=CONFIG.Colors.Element,TextColor3=CONFIG.Colors.Text,Text=" Ping: Cargando...",Font=Enum.Font.Gotham,TextSize=16})
Rnd(PingLbl,8)
local RAMLbl=Create("TextLabel",{Parent=StatsPnl,Size=UDim2.new(0.8,0,0,40),Position=UDim2.new(0.1,0,0.5,0),BackgroundColor3=CONFIG.Colors.Element,TextColor3=CONFIG.Colors.Text,Text=" RAM: Cargando...",Font=Enum.Font.Gotham,TextSize=16})
Rnd(RAMLbl,8)
local CfgPnl=Create("Frame",{Parent=Content,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false})
local ModelLbl=Create("TextLabel",{Parent=CfgPnl,Size=UDim2.new(0.9,0,0,30),Position=UDim2.new(0.05,0,0,10),BackgroundTransparency=1,TextColor3=CONFIG.Colors.Text,Text="Modelo de IA:",Font=Enum.Font.Gotham,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
local ModelBtn=Create("TextButton",{Parent=CfgPnl,Size=UDim2.new(0.9,0,0,40),Position=UDim2.new(0.05,0,0,40),BackgroundColor3=CONFIG.Colors.Element,TextColor3=CONFIG.Colors.Accent,Text=CONFIG.CurrentModel,Font=Enum.Font.GothamBold,TextSize=12})
Rnd(ModelBtn,8)
local ResetKeyBtn=Create("TextButton",{Parent=CfgPnl,Size=UDim2.new(0.9,0,0,40),Position=UDim2.new(0.05,0,0,90),BackgroundColor3=Color3.fromRGB(220,50,50),TextColor3=Color3.new(1,1,1),Text="Cambiar API Key",Font=Enum.Font.GothamBold,TextSize=14})
Rnd(ResetKeyBtn,8)
local UI_TABS={Chat=ChatPnl,Modos=ModesPnl,Tools=ToolsPnl,Stats=StatsPnl,Config=CfgPnl}
local UI_BTNS={}
local function SetTab(n)
  for k,p in pairs(UI_TABS) do p.Visible=(k==n) end
  for k,b in pairs(UI_BTNS) do Tw(b,{BackgroundColor3=(k==n and CONFIG.Colors.Accent or CONFIG.Colors.Sidebar)},0.2) end
end
local yTab=10
for n,_ in pairs(UI_TABS) do
  local b=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-20,0,36),Position=UDim2.new(0,10,0,yTab),BackgroundColor3=CONFIG.Colors.Sidebar,TextColor3=Color3.new(1,1,1),Text=n,Font=Enum.Font.Gotham,TextSize=14})
  Rnd(b,8);UI_BTNS[n]=b;yTab=yTab+46
  b.MouseButton1Click:Connect(function() SetTab(n) end)
end
local function MakeDrag(dragger,target)
  local d,s,p
  dragger.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=true;s=i.Position;p=target.Position end end)
  dragger.InputChanged:Connect(function(i) if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local del=i.Position-s;target.Position=UDim2.new(p.X.Scale,p.X.Offset+del.X,p.Y.Scale,p.Y.Offset+del.Y) end end)
  UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then d=false end end)
end
MakeDrag(FloatBtn,FloatBtn)
MakeDrag(TopBar,MainFrame)
FloatBtn.MouseButton1Click:Connect(function() MainFrame.Visible=not MainFrame.Visible end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible=false end)
local TogglesUI={}
local function AddToggle(n,cb)
  local f=Create("Frame",{Parent=ModesPnl,Size=UDim2.new(1,0,0,44),BackgroundColor3=CONFIG.Colors.Element})
  Rnd(f,8)
  Create("TextLabel",{Parent=f,Size=UDim2.new(0.7,0,1,0),Position=UDim2.new(0,15,0,0),BackgroundTransparency=1,TextColor3=CONFIG.Colors.Text,Text=n,Font=Enum.Font.Gotham,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
  local tb=Create("TextButton",{Parent=f,Size=UDim2.new(0,50,0,26),Position=UDim2.new(1,-65,0.5,-13),BackgroundColor3=Color3.fromRGB(80,80,80),Text="",AutoButtonColor=false})
  Rnd(tb,13)
  local ind=Create("Frame",{Parent=tb,Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,2,0.5,-11),BackgroundColor3=Color3.new(1,1,1)})
  Rnd(ind,11)
  local st=false
  TogglesUI[n]=function(v) st=v;Tw(tb,{BackgroundColor3=st and CONFIG.Colors.Accent or Color3.fromRGB(80,80,80)},0.2);Tw(ind,{Position=st and UDim2.new(1,-24,0.5,-11) or UDim2.new(0,2,0.5,-11)},0.2);cb(st) end
  tb.MouseButton1Click:Connect(function() TogglesUI[n](not st) end)
end
local function SetFly(v)
  State.Flying=v
  local c=LP.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
  if not r then return end
  if v then
    local bv=Create("BodyVelocity",{Parent=r,Velocity=Vector3.zero,MaxForce=Vector3.new(9e9,9e9,9e9)})
    local bg=Create("BodyGyro",{Parent=r,P=9e4,MaxTorque=Vector3.new(9e9,9e9,9e9),CFrame=r.CFrame})
    State.FlyConn=RS.RenderStepped:Connect(function()
      local cf=Cam.CFrame;local m=Vector3.zero
      if UIS:IsKeyDown(Enum.KeyCode.W) then m=m+Vector3.new(0,0,-1) end
      if UIS:IsKeyDown(Enum.KeyCode.S) then m=m+Vector3.new(0,0,1) end
      if UIS:IsKeyDown(Enum.KeyCode.A) then m=m+Vector3.new(-1,0,0) end
      if UIS:IsKeyDown(Enum.KeyCode.D) then m=m+Vector3.new(1,0,0) end
      local y=UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
      bv.Velocity=(cf.RightVector*m.X + cf.LookVector*m.Z + Vector3.new(0,y,0))*50
      bg.CFrame=cf
    end)
  else
    if r:FindFirstChild("BodyVelocity") then r.BodyVelocity:Destroy() end
    if r:FindFirstChild("BodyGyro") then r.BodyGyro:Destroy() end
    if State.FlyConn then State.FlyConn:Disconnect();State.FlyConn=nil end
  end
end
AddToggle("Fly Mode",SetFly)
AddToggle("Infinite Jump",function(v) State.InfJump=v end)
AddToggle("Click TP (Ctrl+Click)",function(v) State.ClickTP=v end)
UIS.JumpRequest:Connect(function() if State.InfJump and LP.Character then local h=LP.Character:FindFirstChildOfClass("Humanoid");if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
Mouse.Button1Down:Connect(function() if State.ClickTP and UIS:IsKeyDown(Enum.KeyCode.LeftControl) and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then LP.Character.HumanoidRootPart.CFrame=CFrame.new(Mouse.Hit.Position+Vector3.new(0,3,0)) end end)
local function RefreshPts()
  for _,c in pairs(PointsScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
  for i,cf in ipairs(State.Points) do
    local f=Create("Frame",{Parent=PointsScroll,Size=UDim2.new(1,0,0,40),BackgroundColor3=CONFIG.Colors.Element})
    Rnd(f,8)
    Create("TextLabel",{Parent=f,Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,TextColor3=CONFIG.Colors.Text,Text="Checkpoint "..i,Font=Enum.Font.Gotham,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left})
    local t=Create("TextButton",{Parent=f,Size=UDim2.new(0,50,0,30),Position=UDim2.new(1,-115,0.5,-15),BackgroundColor3=CONFIG.Colors.Accent,TextColor3=Color3.new(1,1,1),Text="TP",Font=Enum.Font.GothamBold,TextSize=12});Rnd(t,6)
    local d=Create("TextButton",{Parent=f,Size=UDim2.new(0,50,0,30),Position=UDim2.new(1,-60,0.5,-15),BackgroundColor3=Color3.fromRGB(220,50,50),TextColor3=Color3.new(1,1,1),Text="DEL",Font=Enum.Font.GothamBold,TextSize=12});Rnd(d,6)
    t.MouseButton1Click:Connect(function() if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then LP.Character.HumanoidRootPart.CFrame=cf end end)
    d.MouseButton1Click:Connect(function() table.remove(State.Points,i);RefreshPts() end)
  end
end
AddPointBtn.MouseButton1Click:Connect(function() if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then table.insert(State.Points,LP.Character.HumanoidRootPart.CFrame);RefreshPts() end end)
local lf=tick()
RS.Heartbeat:Connect(function()
  local n=tick();local fps=math.floor(1/(n-lf));lf=n
  if StatsPnl.Visible then
    FPSLbl.Text=" FPS: "..fps
    local s,p=pcall(function() return LP:GetNetworkPing()*1000 end)
    PingLbl.Text=" Ping: "..(s and math.floor(p).."ms" or "N/A")
    local mem=math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
    RAMLbl.Text=" RAM: "..mem.." MB"
  end
end)
table.insert(State.ChatHistory,{role="system",content="Eres Kaelen, asistente IA en Roblox. Controlas al jugador si te lo pide. Usa estos formatos en tu respuesta para actuar: [SPEED:num], [JUMP:num], [FLY:on], [FLY:off], [HEAL]. Responde de manera concisa."})
local function ParseCmd(t)
  local c=LP.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
  if not h then return end
  local s=t:match("%[SPEED:(%d+)%]");if s then h.WalkSpeed=tonumber(s) end
  local j=t:match("%[JUMP:(%d+)%]");if j then h.JumpPower=tonumber(j);h.UseJumpPower=true end
  if t:match("%[FLY:on%]") then TogglesUI["Fly Mode"](true) end
  if t:match("%[FLY:off%]") then TogglesUI["Fly Mode"](false) end
  if t:match("%[HEAL%]") then h.Health=h.MaxHealth end
end
local function AddMsg(m,ia)
  local f=Create("Frame",{Parent=ChatScroll,Size=UDim2.new(1,0,0,0),BackgroundColor3=ia and Color3.fromRGB(40,40,45) or CONFIG.Colors.Accent,AutomaticSize=Enum.AutomaticSize.Y})
  Rnd(f,8);Create("UIPadding",{Parent=f,PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})
  Create("TextLabel",{Parent=f,Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Text=m,Font=Enum.Font.Gotham,TextSize=13,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,AutomaticSize=Enum.AutomaticSize.Y})
  task.delay(0.05,function() ChatScroll.CanvasPosition=Vector2.new(0,99999) end)
end
local function SendChat()
  local msg=ChatBox.Text;if msg=="" then return end;ChatBox.Text=""
  AddMsg(msg,false);table.insert(State.ChatHistory,{role="user",content=msg})
  if not req then AddMsg("Error: Executor no soporta HTTP",true);return end
  task.spawn(function()
    local s,r=pcall(function() return req({Url=CONFIG.OpenRouterBase,Method="POST",Headers={["Content-Type"]="application/json",["Authorization"]="Bearer "..CONFIG.Key},Body=HS:JSONEncode({model=CONFIG.CurrentModel,messages=State.ChatHistory,temperature=0.7})}) end)
    if s and r.StatusCode==200 then
      local d=HS:JSONDecode(r.Body);local rep=d.choices[1].message.content
      table.insert(State.ChatHistory,{role="assistant",content=rep})
      AddMsg(rep,true);ParseCmd(rep)
    else AddMsg("Error API: "..(r and tostring(r.StatusCode or r) or "Timeout"),true) end
  end)
end
ChatBox.FocusLost:Connect(function(e) if e then SendChat() end end)
ChatSend.MouseButton1Click:Connect(SendChat)
KeySave.MouseButton1Click:Connect(function() if KeyInput.Text~="" then CONFIG.Key=KeyInput.Text;KeyPanel.Visible=false;State.KeyVerified=true;SetTab("Chat") end end)
ResetKeyBtn.MouseButton1Click:Connect(function() KeyPanel.Visible=true;State.KeyVerified=false;CONFIG.Key="" end)
local mdls={"qwen/qwen3-coder:free","meta-llama/llama-3.3-70b-instruct:free","google/gemma-3-27b-it:free"};local mIdx=1
ModelBtn.MouseButton1Click:Connect(function() mIdx=mIdx+1;if mIdx>#mdls then mIdx=1 end;CONFIG.CurrentModel=mdls[mIdx];ModelBtn.Text=CONFIG.CurrentModel end)
SetTab("Chat");KeyPanel.Visible=true
