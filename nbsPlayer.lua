local nbs=require("nbs")
local component=require("component")
local gpu=component.gpu
local event=require("event")
local shell=require("shell")

local X,Y=gpu.getResolution()
local args=shell.resolve(...)
if args==nil then
  print("nbsPlayer <file>")
  os.exit(-1)
end
local file=nbs.parse_file(args)

local notes={}

for k,v in component.list("iron_noteblock") do
  table.insert(notes,component.proxy(k))
end
if #notes==0 or #notes<file.headers.song_layers then
  io.stderr:write(string.format("This nbs file need %d iron note blocks,but found %d iron note blocks.\n",file.headers.song_layers,#notes))
  os.sleep(5)
end
setmetatable(notes,{__index=function() return {playNote=function() end} end})
local ticks={}
for _,i in ipairs(file.notes) do
  for j=1,i.tick+1 do
    if ticks[j]==nil then
      ticks[j]={}
    end
  end
  for j=1,i.layer+1 do
    if ticks[i.tick+1][j]==nil then
      ticks[i.tick+1][j]={}
    end
  end
  ticks[i.tick+1][i.layer+1]={math.max(1,math.min(i.key-33,24)),i.instrument,i.layer+1}
end
local colors={0x3d3c84,0x98c09c,0xc59d9d,0xbf98c0,0x844587,0x838180,0x7a843c,0x874572,0x457887,0x676767,0}
gpu.fill(1,1,X,Y," ")
local function update(tick)
  gpu.copy(1,1,X,Y,-2,0)
  local layer=1
  if ticks[tick] and #ticks[tick]~=0 then
    for k,i in ipairs(ticks[tick]) do
      if #i~=0 then
        gpu.setForeground(colors[i[2]+1]|0xFFFFFF)
        gpu.setBackground(colors[i[2]+1])
        gpu.set(X-1,layer,string.format("%0.2d",i[1]))
      else
        gpu.setBackground(0)
        gpu.set(X-1,layer,"  ")
      end
      layer=layer+1
    end
  else
    gpu.setBackground(0)
    gpu.fill(X-1,1,2,Y," ")
  end
  gpu.setBackground(0)
end
local paused=false
local function keydown(_,_,key)
  if key==32 then
    paused=not paused
  end
end
event.listen("key_down",keydown)
local stop=false
local delay=1/file.headers.tempo
local function wait()
  while paused do
    xpcall(os.sleep,function() stop=true end,delay)
    gpu.set(1,Y,"Paused.")
  end
  xpcall(os.sleep,function() stop=true end,delay)
end
for i=1,math.ceil(X/2) do
  update(i)
  wait()
  if stop then
    break
  end
end
local a=math.ceil(X/2)-1
for j,i in ipairs(ticks) do
  if stop then
    break
  end
  for _,i in ipairs(i) do
    if #i~=0 then
      notes[i[3]+1].playNote(nbs.INSTRUMENTS[i[2]+1],i[1])
    end
  end
  update(j+a)
  wait()
end
event.ignore("key_down",keydown)
require("term").clear()
