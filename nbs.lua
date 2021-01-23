local fs=require("filesystem")
local nbs={}
nbs.BLOCKS={'dirt','oak_planks','cobblestone','sand','glass','wool','clay','gold_block','packed_ice','bone_block'}
nbs.INSTRUMENTS={'harp','bass','basedrum','snare','hat','guitar','flute','bell','chime','xylophone','guitar'}
local function read_byte(file)
  return string.unpack("<B",file:read(1))
end
local function read_short(file)
  return string.unpack("<H",file:read(2))
end
local function read_int(file)
  return string.unpack("<I4",file:read(4))
end
local function read_string(file)
  return file:read(read_int(file))
end
function nbs.jump(file)
  local value=-1
  return function()
    local jump=read_short(file)
    if jump==0 then
      return nil
    end
    value=value+jump
    return value
  end
end
function nbs.parse_header(file)
  local song_length=read_short(file)
  local version=0
  if song_length==0 then
    version=read_byte(file)
  end
  local data={version=version,song_length=song_length,loop=false,max_loop_count=0,loop_start=0}
  if version > 0 then data.default_instruments=read_byte(file) end
  if version >=3 then data.song_length=read_short(file) end
  data.song_layers=read_short(file)
  data.song_name=read_string(file)
  data.song_author=read_string(file)
  data.original_author=read_string(file)
  data.description=read_string(file)
  data.tempo=read_short(file)/100
  data.auto_save=read_byte(file)==1
  data.auto_save_duration=read_byte(file)
  data.time_signature=read_byte(file)
  data.minutes_spent=read_int(file)
  data.left_clicks=read_int(file)
  data.right_clicks=read_int(file)
  data.blocks_added=read_int(file)
  data.blocks_removed=read_int(file)
  data.song_origin=read_string(file)
  if version >= 4 then
    data.loop=read_byte(file)==1
    data.max_loop_count=read_byte(file)
    data.loop_start=read_short(file)
  end
  return data
end
function nbs.parse_notes(file,version)
  notes={}
  for current_tick in nbs.jump(file) do
    for current_layer in nbs.jump(file) do
      if current_layer==nil then break end
      local note={tick=current_tick,layer=current_layer,velocity=100,panning=0,pitch=0}
      note.instrument=read_byte(file)
      note.key=read_byte(file)
      if version >= 4 then
        note.velocity=read_byte(file)
        note.panning=read_byte(file)
        note.pitch=read_byte(file)
      end
      table.insert(notes,note)
    end
    if current_tick==nil then break end
  end
  return notes
end
function nbs.parse_layers(file,layers_count, version)
  local layers={}
  for i=1,layers_count do
    local layer={lock=false,panning=0}
    layer.name=read_string(file)
    if version >= 4 then
      layer.lock=read_byte(file)==1
    end
    layer.volume=read_byte(file)
    if version >= 2 then
      layer.panning=read_byte(file)-100
    end
    layers[i]=layer
  end
  return layers
end
function nbs.parse_instruments(file,version)
  local instruments={}
  for i=1,read_byte(file) do
    local ins={}
    ins.name=read_string(file)
    ins.sound_file=read_string(file)
    ins.pitch=read_byte(file)
    ins.press=read_byte(file)
    instruments[i]=ins
  end
  return instruments
end
function nbs.parse_file(file)
  if type(file)=="string" then
    file=fs.open(file)
  end
  local data={headers=nbs.parse_header(file)}
  data.notes=nbs.parse_notes(file,data.headers.version)
  data.layers=nbs.parse_layers(file,data.headers.song_layers,data.headers.version)
  data.instruments=nbs.parse_instruments(file,data.headers.version)
  file:close()
  return data
end
return nbs