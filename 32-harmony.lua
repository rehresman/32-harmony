-- -- -- -- -- -- -- 32-harmony -- -- -- -- -- -- -
--
-- is a random sequencer
--
--
--
--
-- -- -- ynomrah-23 -- -- -- -- -- -- -- -- -- -- -

engine.name = "32Harmony"

math.randomseed(os.time())

-- set this to true for limitless exploration
-- beware: it's dark out there
local random_scale_degrees = false

local shift = false
local viz = {
   rate = 0,
   ampL = 0,
   ampR = 0,
   phase = 0,
   separation = 1.0,
   size = 0.0,
   quant = 0
}

local ampL_poll = nil
local ampR_poll = nil
local viz_clock

local function sr(n)
  return 2 ^(n/12)
end

local semitones = {sr(0),sr(1),sr(2),sr(3),sr(4),sr(5),sr(6),sr(7),sr(8),sr(9),sr(10),sr(11)}
local semitones_init = {sr(0),sr(1),sr(2),sr(3),sr(4),sr(5),sr(6),sr(7),sr(8),sr(9),sr(10),sr(11)}

-- takes scale degrees as parameters, not indexes
local function scale(d1,d2,d3,d4,d5)
  return {semitones_init[d1+1], semitones_init[d2+1], semitones_init[d3+1], semitones_init[d4+1], semitones_init[d5+1]}
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- scales were created with the following procedure:
-- 1. take the major pentatonic scale,
-- 2. vary one scale degree
-- 3. (if necessary) alter related scale degrees
-- 4. repeat for the minor pentatonic scale
--
-- i avoided certain sounds
-- based on preference
--
-- i encourage you, dearest gentle reader
-- to generate your own
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
local scales = {scale(0,2,4,7,9),
                scale(1,2,4,7,9),
                scale(11,2,4,7,9),
                scale(0,1,5,7,10),
                scale(11,3,4,6,8),
                scale(0,2,3,7,9),
                scale(0,2,5,7,9),
                scale(0,2,4,6,9),
                scale(0,2,4,8,10),
                scale(0,2,4,7,8),
                scale(0,2,4,7,10),
                scale(0,2,4,7,11),
                scale(0,3,5,7,10),
                scale(1,3,5,7,10),
                scale(11,3,6,8,10),
                scale(0,4,5,7,10),
                scale(0,2,5,7,10),
                scale(11,1,3,4,8),
                scale(0,3,6,8,10),
                scale(0,3,5,6,10),
                scale(0,3,5,8,10),
                scale(0,3,5,7,9),
                scale(1,3,5,8,11)
}

local current_scale = 1

local function norm_rate(rate)
  local min_rate = 0.1
  local max_rate = 20000
  local t = math.log(rate / min_rate) / math.log(max_rate / min_rate)
  return util.clamp(t, 0, 1)
end

local function rate_to_display(rate)
  local t = norm_rate(rate)
  local orbit_hz = rate / 8
  local separation = 1.0 - t^2
  local size = t
  return orbit_hz, separation, size
end

local function amp_to_level(amp)
    if amp > 0.0041 then
      amp = util.clamp(64*amp, 0, 1)
    end
    return math.floor(amp * 15) -- 0..15
end

local function update_binary_stars(dt)
  local orbit_hz, separation, size = rate_to_display(viz.rate)

  viz.phase = (viz.phase + 2 * math.pi * orbit_hz * dt) % (2 * math.pi)
  viz.separation = separation
  viz.size = size

end

local function draw_binary_stars()
  local cx = 96
  local cy = 16
  local orbit_r = 12

  local phase = viz.phase
  local r2_factor = ((3.9038*viz.quant^2) - (6.8087*viz.quant) + 3.9048)
  local sep_r1 = orbit_r * viz.separation
  local sep_r2 = orbit_r * viz.separation * r2_factor
  local size = 2.8 - (1.35 * viz.size)

  local xL = cx + math.cos(phase) * sep_r2
  local yL = cy + math.sin(phase) * sep_r1
  local xR = cx + math.cos(phase + math.pi) * sep_r1
  local yR = cy + math.sin(phase + math.pi) * sep_r2

  local starLevelL = amp_to_level(viz.ampL)
  local starLevelR = amp_to_level(viz.ampR)

  local starSizeL = size + viz.ampL * 2.5
  local starSizeR = size + viz.ampR * 2.5
  -- stars
  if starLevelL > 0 then
    screen.level(starLevelL)
    screen.circle(xL, yL, starSizeL)
    screen.fill()
  end

  if starLevelR > 0 then
    screen.level(starLevelR)
    screen.circle(xR, yR, starSizeR)
    screen.fill()
  end
end


function init()
  params:add_control("pitch", "pitch", controlspec.new(20, 2000, 'exp', 0, 32.7, 'hz'))
  params:add_control("decay", "decay", controlspec.new(0.01, 12, 'exp', 0, 3.5, 's'))
  params:add_control("range", "range", controlspec.new(1, 9, 'lin', 1, 4, 'oct'))

  params:add_control("quantize", "quantize", controlspec.new(0, 1, 'lin', 0, 0.6))
  params:add_control("rate", "rate", controlspec.new(0.1, 20000, 'exp', 0, 1, 'hz'))
  params:add_control("cutoff", "cutoff", controlspec.new(20, 20000, 'exp', 0, 4000, 'hz'))

  params:set_action("pitch", function(x)
    engine.rootIn(x)
  end)

  params:set_action("decay", function(x)
    engine.decayIn(x)
  end)

  params:set_action("range", function(x)
    engine.range1In(x)
    engine.range2In(x)
  end)

  params:set_action("quantize", function(x)
    local y = math.atan(50*x)/math.atan(50)
    viz.quant = x
    engine.quantAmtIn(y)
  end)

  params:set_action("cutoff", function(x)
    engine.lpfCutoffIn(x)
  end)

  params:set_action("rate", function(x)
    viz.rate = x
    engine.rate1In(x)
    engine.rate2In(x)
  end)

  ampL_poll = poll.set("amp_out_l")
  ampL_poll.callback = function(v)
    viz.ampL = v
  end
  ampL_poll.time = 1/30
  ampL_poll:start()

  ampR_poll = poll.set("amp_out_r")
  ampR_poll.callback = function(v)
    viz.ampR = v
  end
  ampR_poll.time = 1/30
  ampR_poll:start()

  viz.rate = params:get("rate")
  viz.quant = params:get("rate")

  viz_clock = metro.init()
  viz_clock.time = 1 / 30
  viz_clock.event = function()
    update_binary_stars(viz_clock.time)
    redraw()
  end
  viz_clock:start()

  redraw()
end

function enc(n, d)
  if shift then
    if n == 1 then
      params:delta("quantize", d)
    elseif n == 2 then
      params:delta("rate", d)
    elseif n == 3 then
      params:delta("cutoff", d)
    end
  else
    if n == 1 then
      params:delta("pitch", d)
    elseif n == 2 then
      params:delta("decay", d)
    elseif n == 3 then
      params:delta("range", d)
    end
  end
  redraw()
end

local function init_scale()
  engine.step0In(semitones_init[1])
  engine.step1In(semitones_init[3])
  engine.step2In(semitones_init[5])
  engine.step3In(semitones_init[8])
  engine.step4In(semitones_init[10])
end

local function rand_scale()
  local d1,d2,d3,d4,d5
  local r
  if random_scale_degrees then
    for i = 1, #semitones - 1 do
      local j = math.random(i, #semitones)
      semitones[i], semitones[j] = semitones[j], semitones[i]
    end
    d1 = semitones[1]
    d2 = semitones[3]
    d3 = semitones[5]
    d4 = semitones[8]
    d5 = semitones[10]
  else
    r = math.random(1, #scales)
    if r == current_scale then
      r = ((r + 1) % #scales) + 1
    end
    current_scale = r
    d1,d2,d3,d4,d5 = table.unpack(scales[r])
  end
  engine.step0In(d1)
  engine.step1In(d2)
  engine.step2In(d3)
  engine.step3In(d4)
  engine.step4In(d5)
end

function key(n, z)
  if n == 1 then
    shift = (z == 1)
  elseif n == 2 then
    if shift and z == 1 then
      init_scale()
    elseif z == 1 then
      rand_scale()
    end
  elseif n == 3 then
    if shift and z == 1 then
      engine.freqMultIn(1.49830707688)
    elseif z == 1 then
      engine.freqMultIn(1.1224620)
    else
      engine.freqMultIn(1)
    end
  end

  redraw()
end

function draw_low_control_block(x, y, slot)
  local key_label, enc_label, value_string
  key_label, enc_label, value_string = get_display_info(slot)

  screen.level(15)
  screen.move(x, y)
  screen.text(enc_label)

  screen.move(x, y + 13)
  screen.text(key_label)

  screen.level(10)
  screen.move(x+ 23, y + 7)
  screen.text(value_string)
end

function draw_hi_control_block(x, y, slot)
  local key_label, enc_label, value_string
  key_label, enc_label, value_string = get_display_info(slot)

  screen.level(15)
  screen.move(x, y)
  screen.text(key_label)

  screen.move(x+ 32, y)
  screen.text(enc_label)

  screen.level(10)
  screen.move(x+13, y + 10)
  screen.text(value_string)
end

function redraw()
  screen.clear()

  draw_binary_stars()
  draw_hi_control_block(4, 10, 1)
  draw_low_control_block(4, 40, 2)
  draw_low_control_block(70, 40, 3)

  screen.update()
end

function get_display_info(slot)
  local key_label, enc_label, value_string

  if shift then
    if slot == 1 then
      key_label = "(shift)"
      enc_label = "quantize"
      value_string = params:string("quantize")
    elseif slot == 2 then
      key_label = "init scale"
      enc_label = "rate"
      value_string = params:string("rate")
    elseif slot == 3 then
      key_label = "V chord"
      enc_label = "lpf cutoff"
      value_string = params:string("cutoff")
    end
  else
    if slot == 1 then
      key_label = "(shift)"
      enc_label = "pitch"
      value_string = params:string("pitch")
    elseif slot == 2 then
      key_label = "rand scale"
      enc_label = "decay"
      value_string = params:string("decay")
    elseif slot == 3 then
      key_label = "II chord"
      enc_label = "range"
      value_string = params:string("range")
    end
  end

  return key_label, enc_label, value_string
end

function cleanup()
  if ampL_poll then
    ampL_poll:stop()
  end

  if ampR_poll then
    ampR_poll:stop()
  end

  if viz_clock then
    viz_clock:stop()
  end
end
