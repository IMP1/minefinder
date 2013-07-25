-- IMP1 GUI Pseudoclasses

--------------------------------------
-- Animation                        --
-- Last Edit: 11/07/2012            --
--------------------------------------

----------------
-- Properties --
----------------
--[[
    x [Number] : x co-ordinate
    y [Number] : y co-ordinate
    rotation [Number] : angle of rotation in radians
    scale [Table]
        x [Number] : horizontal scale factor
        y [Number] : vertical scale factor
    offset [Table]
        x [Number] : horizontal origin offset
        y [Number] : vertical origin offset
    shear [Table]
        x [Number] : horizontal shearing factor
        y [Number] : vertical shearing factor
    tint [Table]
        r [Number] : red value of the tint
        g [Number] : green value of the tint
        b [Number] : blue value of the tint
    opacity [Number] : Opacity when drawn
    quads [Table]
        [1] [LÖVE.Quad] : first frame
        [...] [LÖVE.Quad] : other frames
    image [LÖVE.Image] : image containing the frames
    frame [Number] : quad to be drawn this draw processing
    quad [LÖVE.Quad] : shortcut to frames[frame] i.e the quad to be drawn
    frameWait [Number] : how long between each frame
    loop [Boolean] : whether or not the animation will loop
    finished [Boolean] : whether or not the animation has completed
--]]
---------------
-- Arguments --
---------------
--[[
    x [Number] : x co-ordinate
    y [Number] : y co-ordinate
    delay [Number] : wait between frame change
    image [String]/[LÖVE.Image] : image containing the frames
    framesWide [Number] : how many frames there are in the image horizontally
    framesHigh [Number] : how many frames there are in the image going vertically
--]]

local Animation = {}
Animation.__index = Animation

function Animation.new( x, y, delay, image, framesWide, framesHigh )
  local this = {}
  setmetatable(this, Animation)
  this.x = x
  this.y = y
  this.rotation = 0
  this.scale = { 
    x = 1, 
    y = 1,
  }
  this.offset = { 
    x = 0, 
    y = 0,
  }
  this.shear = { 
    x = 0, 
    y = 0,
  }
  this.tint = {
    r = 255,
    g = 255,
    b = 255,
  }
  this.opacity = 255
  if type(image) == "string" then
    if loadImage == nil then
      this.image = love.graphics.newImage(image)
    else
      this.image = loadImage(image)
    end
  else
    this.image = image
  end
  this.frameCount = 0
  this.frameWait = delay
  this.frame = 1
  this.quads = {}
  local w = this.image:getWidth()
  local h = this.image:getHeight()
  local qw = w / framesWide
  local qh = h / framesHigh
  for j = 1, framesHigh do
    for i = 1, framesWide do
      this.quads[#this.quads+1] = love.graphics.newQuad( (i-1) * qw, (j-1) * qh, qw, qh, w, h )
    end
  end
  this.quad = this.quads[this.frame]
  this.loop = true
  this.finished = false
  return this
end

function Animation:update(dt)
  if #self.quads == 1 then return end -- if no animation, forget about it.
  if self.finished then return end -- if the animation had ended, then it's over.
  self.frameCount = self.frameCount + dt
  if self.frameCount > self.frameWait then
    if (not self.loop) and (self.frame == #self.quads) then
      self.finished = true
    else
      self.frameCount = self.frameCount - self.frameWait
      self.frame = 1 + self.frame % #self.quads
      self.quad = self.quads[self.frame]
    end
  end
end

function Animation:draw(x, y, r)
  local x, y, r = x, y, r
  if y == nil then y = 0 end
  if x == nil then x = 0 end
  if r == nil then r = 0 end
  ------
  love.graphics.setColor( self.tint.r, self.tint.g, self.tint.b, self.opacity )
  love.graphics.drawq( self.image, self.quad, self.x + x, self.y + y, self.rotation + r, self.scale.x, self.scale.y, self.offset.x, self.offset.y, self.shear.x, self.shear.y )
end

return Animation