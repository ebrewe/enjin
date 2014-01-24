class Game

	constructor: (@container, @tileSize, {viewHeight, viewWidth} = {})->
		@viewHeight = viewHeight ? 400
		@viewWidth = viewWidth ? 600
		@tileHeight = @tileSize
		@tileWidth = @tileSize * 2
		@levels = []
		@currentLevel = 0 #start at the first level
	
		paused = false

	start: ->
		@setup()
		@then = Date.now()
		setInterval @tick, 1000/30
		
	setup: ->

		@world = new World @container, @tileWidth, @tileHeight, @viewWidth, @viewHeight
		@inputHandler = new InputHandler @world
	
	update: (options)->
		updates = options ? false
		@inputHandler.update()
		@world.update(updates)
	
	tick: =>
		@now = Date.now()
		@twixt = @now - @then #the frame rate
		@then = @now
		updates = 
			hud: {frameRate:@twixt}
		@update(updates)
		@world.draw()
		
	initiate: (levels) ->
		
		@levels = levels
		if @levels[@currentLevel]
			@world.doScene @levels[@currentLevel]
		
		$(@world.el).click ()=>
			@inputHandler.clicked = true
		$(@world.el).on 'mousedown', ()=>
			@inputHandler.mouseDown = true
			@inputHandler.startClick @then
		$(@world.el).on 'mouseup', ()=>
			@inputHandler.endDrag()

###
******************************
THE GREAT WORLD CLASS
******************************
###
class World

	scene: []
	sprites: []
	background: false
	defaultScroll: {x:0, y:0}

	constructor: (@container, @tileWidth, @tileHeight, @w, @h, {scrollX, scrollY} ={} ) ->
		@scrollX = scrollX ? 0
		@scrollY = scrollY ? 0
		@defaultScrollX = scrollX ? 0
		@defaultScrollY = scrollY ? 0
		@scrollTarget = {x:@defaultScrollX, y:@defaultScrollY}
		@quickScroll = false
		@objects = []
		@entities = []
		@square = false #hex or square?
	
		@createWorld()

	createWorld: ->
		@el = @container
		$(@el).css({
			'display': 'block'
			'position': 'relative'
			'width': '90%'
			'height': @h + 'px'
		}).attr('data-dragging', 'false')
		
	createHUD: (elements)->
		options =[]
		
		@hud = new HUD @container, elements:elements, options:options
		
		
	update: (updates)->
		hupdates = updates.hud ? {}
		if hupdates.frameRate
			@hud.elements.frames.update hupdates.frameRate
		if @tiles
			tile.update() for tile in @tiles
		ent.update() for ent in @entities
			
		if @quickScroll then @scrollQuick() 
			
	draw: ->
		if @tiles
			tile.draw() for tile in @tiles
		ent.draw() for ent in @entities
			
	doScene: (scene)->
		@scene = scene ? {}
		@square = @scene.square
		@scene.hud ?= []
		@createHUD(@scene.hud)
		$(@hud.el).on 'click', '#center', =>
			@scrollTarget = {x:@defaultScrollX, y:@defaultScrollY}
			@quickScroll = true
			
		if @scene.scroll
			@scrollX = @scene.scroll.x
			@scrollY = @scene.scroll.y
			@defaultScrollX = @scene.scroll.x
			@defaultScrollY = @scene.scroll.y
		if @scene.map 
			@tiles = []
			@map = new LevelMap @scene.map, @tileWidth, @tileHeight, @square
			@map.image = @scene.mapImage ? false
			if @map.image == false
				@map.image = if @square then 'images/square_iso_small.png' else 'images/hextile_iso_v.png'
		
			@cMap =@scene.map
			for row in @cMap
				for tile in row
					if row[tile] == 'x' 
						row[tile] = 1
					else
						row[tile] = 0

			@createPFGrid(@cMap)
			
			@placeTiles()

	createPFGrid: (map)->
		@grid = new PF.Grid( map[0].length, map.length, map)
		@finder = new PF.BreadthFirstFinder()
		
	placeTiles: ->
		world = this
		m = @map.tiles ? false
		if m
			for rIndex, row of m
				for cIndex, column of row
					tile = @map.tiles[rIndex][cIndex]
					tile.tile = new Tile world, tile.x, tile.y, @tileWidth, @tileWidth, @map.image, {row: rIndex, col:cIndex, type:tile.type, offset:{x:0, y:22}, render:true}
					@tiles.push tile.tile
					
	makePath: (start, end)->
		gridClone = @clone @grid

		@finder.findPath start.x, start.y, end.x, end.y, gridClone

	clone: (obj) ->
	
	
		if not obj? or typeof obj isnt 'object'
			return obj

		if obj instanceof Date
			return new Date(obj.getTime()) 

		if obj instanceof RegExp
			flags = ''
			flags += 'g' if obj.global?
			flags += 'i' if obj.ignoreCase?
			flags += 'm' if obj.multiline?
			flags += 'y' if obj.sticky?
			return new RegExp(obj.source, flags) 

		newInstance = new obj.constructor()

		for key of obj
			newInstance[key] = @clone obj[key]

		newInstance
		
	scrollQuick: ->
		if Math.abs(@scrollX - @scrollTarget.x) <= @tileWidth
			@scrollTarget.x = @scrollX
		else
			@scrollX = if @scrollX > @scrollTarget.x then @scrollX - @tileWidth else @scrollX + @tileWidth
			
		if Math.abs(@scrollY - @scrollTarget.y) <= @tileWidth
			@scrollTarget.y = @scrollY
		else
			@scrollY = if @scrollY > @scrollTarget.y then @scrollY - @tileWidth else @scrollY + @tileWidth
	
		if @scrollX == @scrollTarget.x and @scrollY == @scrollTarget.y
			@quickScroll = false

class LevelMap

	constructor: (@map, @tileWidth, @tileHeight, @square)->
		@columns = @map.length
		@rows = @map[0].length
		@tiles = {}
		@build()

	build: ->
		for rIndex, row of @map
			@tiles[rIndex] = {}
			for cIndex, column of row
				tx = cIndex * @tileWidth
				ty = rIndex * @tileHeight
				
				coords = @toIso tx, ty, rIndex, cIndex
				
				@tiles[rIndex][cIndex] = {x: coords.x, y:coords.y,type: column, }

	toIso: (x, y, r, c)->
		if @square
			dx = x / 2 + ((@rows - r) * (@tileWidth/2 ))
			dy = y / 2 + (c * (@tileHeight / 2 ) - .5)
		else
			dx = x * 2 / 3
			dy = y + ((c % 2) * @tileHeight / 2 )
			
		return {x: dx, y:dy}

###
******************************
THE IMPACTFUL INPUT-HANDLER
******************************
###

class InputHandler

	keysPressed: []
	clicked: false
	mousePos: {}
	mouseDown: false
	dragging: false
	dragStart: {}
	hovering: false

	constructor: (@world) ->
		@bindMouse()
	
	bindMouse: =>
		that = this
		document.addEventListener 'mousemove', (evt)->
			that.mousePos = that.getMousePos(evt)
	
	getMousePos: (evt)->
		rect = @world.el
		wScrollX = $('body').scrollLeft()
		wScrollY = $('body').scrollTop()

		#scroll must account for world scrolls and window scroll for vertical
		{x: evt.clientX - $(rect).offset().left, y: evt.clientY - $(rect).offset().top + wScrollY }

	update:=>
		if @world.tiles
			@hovering = false
			for tile in @world.tiles
				tile.clearFlags ['hover']
				if @mousePos.x >= tile.rx and @mousePos.x <= tile.rx + tile.w and @mousePos.y >= tile.ry and @mousePos.y <= tile.ry + tile.h
					@hovering = tile
				
		if @hovering
			@hovering.setFlags ['hover']
			if @clicked then console.log @hovering.row, @hovering.col
			
		if @mouseDown
			@checkDrag()
		$(@world.el).attr('data-dragging', false)
		if @dragging
			$(@world.el).attr('data-dragging', true)
			dX = (@mousePos.x - @dragStart.x ) 
			dY = (@mousePos.y - @dragStart.y)
			if Math.abs( dX ) > 5
				@world.scrollX = dX
			if Math.abs( dY ) > 5
				@world.scrollY = dY 
				
		#reset click
		@clicked = false	
			
	checkDrag: ->
		now = new Date()
		holding = now - @clickStart
		if holding >= 200
			@dragging = true
			return true
		return false
		
	startClick: (time)->
		@clickStart = time
		@dragStart = {x:@mousePos.x - @world.scrollX, y:@mousePos.y - @world.scrollY}
	
	endDrag: ->
		@mouseDown = false
		@dragging = false

class HUD
	
	elements: {}
	
	constructor: (container, {elements, options}={})->
		@parent = container
		HUD = document.createElement('div')
		HUD.setAttribute('id', 'game_hud')
		@parent.appendChild(HUD)
		@el = HUD
		$(@el).css({
			'display': 'block'
			'position': 'absolute'
			'top':	0
			'left': 0
			'width': $(@parent).width()
			'height': $(@parent).height()
		})
		if elements
			for element in elements
				@createElement element
				
		return this
		
	createElement: (element)->
		el = new HUDElement element, @el
		@elements[element] = el

class HUDElement

	constructor: (@element, hud)->
		el = document.createElement('div')
		el.setAttribute('id', @element)
		hud.appendChild(el)
		@el = el
		@customize()
		$(@el).css({
			"-moz-user-select": "none" 
			"-khtml-user-select": "none" 
			"-webkit-user-select": "none" 
			"-o-user-select": "none" 
		})
		$(@el).on 'mousenter', ->
			$(@el).addClass('hover')
		$(@el).on 'mouseleave', ->
			$(@el).removeClass('hover');
		
	customize: ->
		switch @element
			when 'frames' 
				console.log('frames built!')
			when 'center'
				$(@el).css({
					'display': 'block'
					'width': '50px'
					'height': '50px'
					'background': 'url(images/center_button.png) no-repeat 0 0'
				})
	
	update: (updateVal) ->
		@el.innerHTML=updateVal;
		

###
******************************
THE ALL-SINGING SPRITE CLASSES
******************************
###

class Sprite

	constructor: (@world, @x, @y, @w, @h, @image , options)->
		@offset = options.offset ? {x:0, y:0}
		@zIndex = options.zIndex ? 1
		@z = @zIndex + (@y * @world.tileHeight)
		@name = options.name ? 'sprite'
		console.log @name, @offset
		@current_frame = 0
		@current_animation = 'standard'
		@fps = options.fps ? 1000/24
		@render = options.render ? true
		@animations = 
			'standard': ['a0']
		if @render
			sprite = document.createElement('div')
			sprite.setAttribute('id', @name) unless @name == 'sprite'
			sprite.className += 'sprite ' 
			sprite.className += @name unless @name == 'sprite'
			@world.container.appendChild(sprite)
			@el = sprite
			$(@el).css({
				'display':'block'
				'position': 'absolute'
				'top': @y + 'px'
				'left': @x + 'px'
				'width': @w + 'px'
				'height': @h + 'px'
				'z-index': Math.ceil @z
				'background-image' : 'url(' + @image + ')'
				'background-repeat': 'no-repeat'
			})
	
	update: (modifier) ->
		@z = Math.ceil @zIndex + (@y * @world.tileHeight)
		@ry = @y + @world.scrollY
		@rx = @x + @world.scrollX
	
	getFrame: (animation)->
		if !@frameTime then @frameTime = new Date()
		now = new Date()
		fr = @current_frame
		a = @animations[animation]		
		
		if now - @frameTime < @fps
			return @processFrame a[fr]
		
		if !a then return {x:0, y:0}
		if !a[fr] or !a[fr + 1] or a.length <= 1
			@current_frame = 0
			return @processFrame a[@current_frame]
		
		@current_frame += 1
		return @processFrame a[@current_frame]
		
	processFrame: (aframe)->
		alpha = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']
		c = aframe.substring 0, 1
		r = aframe.substring(1, aframe.length)
		ex = parseInt(r) * @w
		wy = @h * alpha.indexOf c
		return {x:ex, y:wy}
	
	draw: ->
		if @el
			bgi = @getFrame(@current_animation)
			$(@el).css({
				'z-index': @z
				'top': (@ry - @h + @offset.y) + 'px'
				'left': (@rx + @offset.x) + 'px'
				'background-position': '-' + bgi.x + 'px ' + '-' + bgi.y + 'px'
			})

class Tile extends Sprite

	constructor:( world, x, y, w, h, image, options)->
		if !options.name then options.name = 'tile'
		@row = options.row ? false
		@col = options.col ? false
		super world, x, y, w, h, image, options
		@flags = []
		@animations = options.animations ? { 'standard': ['a0'], 'hover': ['a1'], 'selected': ['a2']}
		@type = if options.type or options.type == 0 then @getType(options.type) else {height:0}
		@height = @type.height
		 
		if @el
			$(@el).css({
				'background': 'url(' + @image + ') no-repeat 0 0'
				#'border': '1px solid rgba(0,0,0,0.2)'
			})
		
	update: (modifier)->
		super modifier
		@current_animation = 'standard'
		if @flags['hover']
			@current_animation = 'hover'
		@ry += @height * (-@world.tileHeight)
		
	draw: ->
		super


	setFlags: (flags)->
		for flag in flags
			@flags[flag] = true
			if @el then $(@el).addClass(flag)
	
	clearFlags: (flags) ->
		for flag in flags
			@flags[flag] = false
			if @el then $(@el).removeClass(flag)
			
	getType: (tile)->
		if isFinite(tile)
			@setFlags ['walkable']
			return {height: tile}
		else
			return {height:0}
			
###
******************************
THE ASTONISHING ENTITIES CLASSES
******************************
###

class Entity extends Sprite

	constructor: (world, x, y, w, h, image, options)->
		super world, x, y, w, h, image, options
		@world.entities.push this
		
	update: (modifier)->
		super modifier
	
	draw: ->
		super
	

###
******************************
THE MIND-BOGGLING KICK-OFF CODE
******************************
###

window.onload = ->
	console.log 'starting'
	lvOneMap = [
		['x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'x'],
		['x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x','x'],
	]
	levelOne = 
		map: lvOneMap
		square: true
		scroll: {x:50, y:100}
		hud: ['frames', 'center']
  
	levels = [levelOne,]
	gameContainer = document.getElementById('game')
	
	game = new Game gameContainer, 11
	game.start() 
	game.world.debug = true
	game.initiate levels
	
	bob = new Entity game.world, 150, 150, 44, 66, 'images/eric.png', {animations: { 'standard': ['a0']}, name: 'bob', offset: {x:-15, y:-8}}