local nbs=require("nbs")
local component=require("component")
local gpu=component.gpu

file=nbs.parse_file(require("shell").resolve(...))

notes={}

for k,v in component.list("iron_noteblock") do
  table.insert(notes,component.proxy(k))
end
os.sleep(0.5)
ticks={}
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
  ticks[i.tick+1][i.layer+1]={i.key,i.instrument,i.layer+1}
end
colors={0x3d3c84,0x98c09c,0xc59d9d,0xbf98c0,0x844587,0x838180,0x7a843c,0x874572,0x457887,0x676767,0}
gpu.fill(1,1,160,50," ")
function update(tick)
  gpu.copy(1,1,160,50,-2,0)
  local layer=1
  if ticks[tick] then
    for k,i in ipairs(ticks[tick]) do
      if #i~=0 then
        gpu.setForeground(colors[i[2]+1]|0xFFFFFF)
        gpu.setBackground(colors[i[2]+1])
        gpu.set(159,layer,string.format("%0.2d",i[1]-33))
      else
        gpu.setBackground(0)
        gpu.set(159,layer,"  ")
      end
      layer=layer+1
    end
  else
    gpu.setBackground(0)
    gpu.fill(159,1,2,50," ")
  end
end
if false then
for j,i in ipairs(ticks) do
  for k,i in ipairs(i) do
    if #i~=0 then
      gpu.setForeground(colors[i[2]+1]|0xFFFFFF)
      gpu.setBackground(colors[i[2]+1])
      gpu.set(j*2-1,i[3],string.format("%0.2d",i[1]-33))
    end
  end
end
else
  for i=1,80 do
    update(i)
  end
end
delay=1/file.headers.tempo
os.sleep(1)
for j,i in ipairs(ticks) do
  for _,i in ipairs(i) do
    if #i~=0 then
      notes[i[3]+1].playNote(nbs.INSTRUMENTS[i[2]+1],math.min(24,i[1]-33))
    end
  end
  update(j+79)
  os.sleep(delay)
end
require("term").clear()