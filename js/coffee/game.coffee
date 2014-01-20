class Game

	constructor: (@container, @tileSize, {viewHeight, viewWidth} = {})->
		@viewHeight = viewHeight ? 400
		@viewWidth = viewWidth ? 600
		@tileHeight = @tileSize
		@tileWidth = @tileSize * 2
		@levels = []
		@level = 0 #start at the first level
	
		paused = false

	start: ->
		@setup()
		@then = Date.now()
		setInterval @tick, 60
		
	setup: ->

		@world = new World @container, @tileWidth, @tileHeight, @viewWidth, @viewHeight
		@inputHandler = new InputHandler @world
	
	tick: =>
		@now = Date.now()
		@twixt = @now - @then #the frame rate
		@then = @now
		

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
		@quickScroll = false
		@objects = []
		@entities = []
		@square = false #hex or square?
	
		@createWorld()
		@createHUD()

	createWorld: ->
		@el = @container
		$(@el).css({
			'display': 'block'
			'position': 'relative'
			'width': '90%'
			'height': @h + 'px'
		}).attr('data-dragging', 'false')
		
	createHUD: ->
		elements = ['frames']
		options =[]
		
		@hud = new HUD @container, elements:elements, options:options
		

class InputHandler

	keysPressed: []
	clicked: false
	mousePos: {}
	mouseDown: false
	dragging: false
	dragStart: {}

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
		{x: evt.clientX - $(rect).offset().left - @world.scrollX, y: evt.clientY - $(rect).offset().top + wScrollY - @world.scrollY}


class HUD
	
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
		
	createElement: (element)->
		el = new HUDElement element, @el

class HUDElement

	constructor: (element, hud)->
		console.log element, hud
		el = document.createElement('div')
		el.setAttribute('id', element)
		hud.appendChild(el)
		@el = el

window.onload = ->
  console.log 'starting'
  
  gameContainer = document.getElementById('game')
  
  game = new Game gameContainer, 44
  game.start() 