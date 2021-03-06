extends Node2D
var mainArray = []  #Основний одновимірний масив, в котрому зберігається розташування всіх кульок
var ballObj = load("res://objects/ball.tscn") #Інстанцінг об'єкту кульки
var arrowObj = load("res://objects/arrow.tscn") #Інстанцінг об'єкту кульки
var flagObj = load("res://objects/flag.tscn") #Інстанцінг об'єкту кульки
var steps = 0
var time = 0
var touch = false


var ballPressed = false #Булева змінна, в якій визначається, чи було натиснуто на яку-небудь кульку
var ballPressedName = '' #Ім'я натиснутої кульки
var shiftPressed = Vector2(0,0) #Вектор, що зберігає колонку, напрямок і величину зміщення кульок
var gameSize = Vector2(2,2) #Розмір ігрового поля (кількість кульок по горизонталі і вертикалі
var lastDirection = 0
var hShift = false
var vShift = false
const BALL_SIZE = 64	#Величина, на яку потрібно зав'язати розмірність елементів гри
const MAX_SIZE = Vector2(6,10) #Максимальний розмір ігрового поля
var game_mode = 1
var v_empty_pos = 0
var cControl = false
var cState = true
var cursor_position = Vector2(0,0)
var is_drag = false

#Масив кодових символів для кольорів кульок
const COLORS_NAMES = ['r', 'g', 'b', 'o', 'y', 'p']

#Таблиця кольорів. В ній немає особливої необхідності, але мені видався такий варінат простішим, для осмислення
const COLORS = {
'white' : Color(1,1,1,1),						#Білий					0
'empty' : Color(0,0,0,0),						#Порожня комірка		1
"red" : Color(1,0,0,1),							#Червоний				2
"green" : Color(0,0.6,0,1),						#Зелені					3
"blue" : Color(0,0,1,1),						#Сині					4
"orange" : Color(1.0, 0.5, 0.0, 1.0),			#Помаранчеві			5
"yellow" : Color(0.65, 0.65, 0.0, 1.0),			#Жовті					6
"purple" : Color(0.65, 0.0, 0.65, 1.0),			#Фіолетові				7
"darkBlue" : Color(0.2, 0.2, 0.9, 0.4),			#Темно синій			8
"black" : Color(0, 0, 0, 1),					#Білий					9
}

func fit_to_screen():
	var bottom_pos = get_node("canvas/bottom").get_pos()
	var game_screen_size = get_node("/root/global").screen_size
	var scale = get_node("bg").get_scale()
	scale.y = scale.y *  (bottom_pos.y / game_screen_size.y) 
	get_node("bg").set_scale(scale)

#-------------------------------------------------------------------
func _ready():
	fit_to_screen()
#	get_node("txt1").set_text(str(get_viewport().get_rect().size))
	randomize()
	game_mode = (get_node("/root/global").game_mode)
	set_process_input(true)
	set_fixed_process(true)
	setGameSize(get_node("/root/global").gameSize)
#	generateMainArray()
	shuffleBalls()
	updateBalls()

#===================================================================
func _fixed_process(delta):
	time += delta
	if !cControl and !touch:
		cursor_position = get_local_mouse_pos() 
	var minutes = int(time / 60)
	var sec = int(time - (minutes * 60))
	get_node("canvas/bottom/time").set_text(str("%02d" % minutes) + ":" + str("%02d" % sec))
	

	get_node("txt").set_text(str(cursor_position))
	
	var mouse = cursor_position
	var ballPressedPos = findBallByName(ballPressedName)

	var scale = get_node("game").get_scale().x

	if ballPressed:
		cState = true
		var mouseOnGrid = Vector2(0,0)
		var onGrid = Vector2(0,0)
		
		mouseOnGrid.x = int((mouse.x/scale - ballPressedPos.x) / BALL_SIZE) - 1 
		mouseOnGrid.y = int((mouse.y/scale - BALL_SIZE/2 - ballPressedPos.y) / BALL_SIZE)

		onGrid.x = (int((mouse.x/scale - ballPressedPos.x) / BALL_SIZE) - 1) - ballPressedPos.x
		onGrid.y = int((mouse.y/scale - BALL_SIZE/2 - ballPressedPos.y) / BALL_SIZE) - ballPressedPos.y
#
		if (onGrid.x != 0 or hShift) and !vShift:
			hShift = true
			var rowToShift = []
			var colToCut = []
			
			var selector = get_node("game/hSelector")
			var selectorPos = selector.get_pos()
			selectorPos.y = (ballPressedPos.y + 1) * BALL_SIZE - BALL_SIZE/2
			selector.set_pos(selectorPos)
			selector.show()

			for i in range(gameSize.x):
				var b = get_node("game/balls/b" + mainArray[i * gameSize.y + ballPressedPos.y])
				rowToShift.append(b)
			for i in range(rowToShift.size()):
				var b = get_node("game/balls/b" + mainArray[mainArray.size() - 1])
				if ballPressedPos.y < gameSize.y:
					b = get_node("game/balls/b" + mainArray[i * gameSize.y + ballPressedPos.y])
				var pos = b.get_pos()
				pos.x = ((int(i + mouseOnGrid.x - ballPressedPos.x) % int(gameSize.x)))
				if pos.x < 0:
					pos.x = int(pos.x + gameSize.x) % int(gameSize.x)
				pos.x = pos.x * BALL_SIZE
				b.set_pos(pos)

			shiftPressed = Vector2(ballPressedPos.y, onGrid.x)
			var empty = findBallByName('')

			
			if onGrid.x > lastDirection:
				get_node("game/arrows/right/R" + str(ballPressedPos.y)).set_texture(1)
				get_node("game/arrows/left/L" + str(ballPressedPos.y)).set_texture(0)
			elif onGrid.x < lastDirection:
				get_node("game/arrows/right/R" + str(ballPressedPos.y)).set_texture(0)
				get_node("game/arrows/left/L" + str(ballPressedPos.y)).set_texture(1)
			lastDirection = onGrid.x

		if (onGrid.y != 0 or vShift)  and !hShift:
			if mouseOnGrid.x == findBallByName('').x:

				if sign(int(onGrid.y)) == sign(int(findBallByName('').y - ballPressedPos.y )) and !vShift:

					cutCol(ballPressedPos)
					updateBalls()
					vShift = true
	if !ballPressed and cState:
		cState = false
		if shiftPressed.y != 0:
			shiftRow(shiftPressed.x, shiftPressed.y)
			steps += 1
		elif !hShift and !vShift and ballPressedName != '':
			if findBallByName('').x == findBallByName(ballPressedName).x:
				var sCol = findBallByName(ballPressedName).x
				cutCol(findBallByName(ballPressedName))
				updateBalls()
				steps += 1
		if vShift and v_empty_pos != findBallByName('').y:
			steps += 1
		var ballPressedPos = findBallByName(ballPressedName)
		get_node("game/arrows/right/R" + str(ballPressedPos.y)).set_texture(0)
		get_node("game/arrows/left/L" + str(ballPressedPos.y)).set_texture(0)
		get_node("game/hSelector").hide()
		hShift = false
		vShift = false
		ballPressed = false
		updateBalls()
		shiftPressed = Vector2(0,0)
		check_victory()

#===================================================================
#===================================================================


func update_flags():
# Видалення всіх прапорців

	for flag in get_node("game/flags").get_children():
		flag.free()
		
# Створення кольорових прапорців-підказок, зо зазначають як саме мать бути розташовані колонки кольорів
	if game_mode > 0:
		for i in range(gameSize.x):
			var flag = flagObj.instance()
			get_node("game/flags").add_child(flag)
			flag.set_name("f" + str(i))
			flag.set_pos(Vector2(BALL_SIZE * i + BALL_SIZE * 1.5,BALL_SIZE/2))
			flag.get_node("flag").set_modulate(toColor(COLORS_NAMES[i]))
	

#Встановлення розміру ігрового поля та маштабування ігрових елементів, для коректного заповнення
func setGameSize(size):
	if size.x <= MAX_SIZE.x and size.y <= MAX_SIZE.y and size.x > 1 and size.y > 1:
		for b in get_node("game/balls").get_children():
			b.free()
		gameSize = size
		generateMainArray() #Виклик функції для генерації основного ігрового масиву
		updateBalls()	#Оновлення/створення кульок
		
		var rightButtons = get_node("game/arrows/right")
		var leftButtons = get_node("game/arrows/left")

# Видалення всіх точок
		for button in rightButtons.get_children():
			button.free()
		for button in leftButtons.get_children():
			button.free()

		for i in range(gameSize.y):
			var lButton = arrowObj.instance()
			var rButton = arrowObj.instance()
			#button.set_name(name)
			leftButtons.add_child(lButton)
			rightButtons.add_child(rButton)
			lButton.set_pos(Vector2(0,i * BALL_SIZE))
			rButton.set_pos(Vector2(0,i * BALL_SIZE))
			lButton.set_name(str('L' + str(i)))
			rButton.set_name(str('R' + str(i)))
			rButton.flip(true)
		update_flags()

		var rbPos = rightButtons.get_pos()
		rbPos.x = (gameSize.x + 2)* BALL_SIZE - BALL_SIZE / 2
		rightButtons.set_pos(rbPos)
		
# Встановлення маштабу ігрового поля, для кращого відображення елементів гри
		get_node("game").set_scale(Vector2(8 / (gameSize.x + 2), 8 / (gameSize.x + 2))) 


# Генерація основного масиву
func generateMainArray():
	mainArray = []
	for i in range(gameSize.x):
		for j in range(gameSize.y):
			mainArray.append(str(COLORS_NAMES[i] + str(j)))
	mainArray[mainArray.size() - 1] = ''

	

#Обробка подій (натискання клавіш)
func _input(event):
	if !cControl:
		if event.type == InputEvent.SCREEN_TOUCH:
			touch = true
			if event.index == 0:
				if event.pressed:
					get_node("txt2").set_text(str(event.pos))
					cursor_position = event.pos
					var cursor_pos = get_ball_at_cursor(cursor_position)
					if cursor_pos.x < gameSize.x and cursor_pos.y < gameSize.y:
						ballPressedName = get_ball_on_grid(cursor_pos)
						ballPressed = true
				if event.released:
					ballPressed = false
		if event.type == InputEvent.SCREEN_DRAG:
			if event.index == 0:
				cursor_position = event.pos

		if event.is_action_pressed("LMB") and !touch:
			cursor_position = get_local_mouse_pos()
			var cursor_pos = get_ball_at_cursor(cursor_position)
			get_node("txt1").set_text(str(cursor_position) + ' ' + str(cursor_pos))
			if cursor_pos.x < gameSize.x and cursor_pos.y < gameSize.y:
				ballPressedName = get_ball_on_grid(cursor_pos)
				ballPressed = true
	
		if event.is_action_released("LMB"):
			ballPressed = false

#	if event.is_action_released("space"): 
#		shuffleBalls()
#		updateBalls()
#		ballPressed = false
#	
#	if event.is_action_released("ui_right"): 
#		setGameSize(Vector2(gameSize.x + 1, gameSize.y))
#	if event.is_action_released("ui_left"): 
#		setGameSize(Vector2(gameSize.x - 1, gameSize.y))
#		
#	if event.is_action_released("ui_down"): 
#		setGameSize(Vector2(gameSize.x, gameSize.y + 1))
#	if event.is_action_released("ui_up"): 
#		setGameSize(Vector2(gameSize.x, gameSize.y - 1))
#
#	if event.is_action_pressed("LMB") and !cControl:
#		is_drag = true

#		cursor_position = get_local_mouse_pos() 
#		cursor_position = get_local_mouse_pos() 
#		var cursor_pos = get_ball_at_cursor(cursor_position)
#		get_node("txt1").set_text(str(cursor_position) + ' ' + str(cursor_pos))
#		if cursor_pos.x < gameSize.x and cursor_pos.y < gameSize.y:
#			ballPressedName = get_ball_on_grid(cursor_pos)
#			ballPressed = true
		

	

# Перевірка, чи гру виграно
func check_victory():
	if game_mode > 0:
		var game_complited = true
		for i in range(gameSize.x):
			var column = []
			var col_complited = 0
			var ballCount = gameSize.y
			if i == gameSize.x - 1:
				ballCount = gameSize.y - 1
			for b in range(gameSize.y):
				column.append(mainArray[b + i * gameSize.y])
				if mainArray[b + i * gameSize.y]:
					if (mainArray[b + i * gameSize.y][0] == COLORS_NAMES[i]):
						col_complited += 1

			if col_complited == ballCount:
				get_node("game/flags/f" + str(i)).get_node("highlite").show() 
			else:
				get_node("game/flags/f" + str(i)).get_node("highlite").hide() 
				game_complited = false
				
			
		if game_complited:

			get_node("/root/global").time = time
			get_node("/root/global").steps = steps
			get_node("/root/global").goto_scene("res://scenes/score.tscn")


#Створення однієї кульки за заданими параметрами
func createBall(name):
	var balls = get_node("game/balls")
	var ball = ballObj.instance()
	ball.set_name(name)
	balls.add_child(ball)
	var color = Color(0,0,0,0)
	if name != 'b':
		color = toColor(name[1])

	ball.setColor(color)
	
#Перефарбування кульок у відповідність до зазначених в ключовому масиві кольорів
func toColor(colorMark):
	var color = COLORS['black']
	if not colorMark: 			#Порожня комірка
		color = COLORS['empty']
	elif colorMark == 'r':		#Червоні
		color = COLORS['red']
	elif colorMark == 'g':		#Зелені
		color = COLORS['green']
	elif colorMark == 'b':		#Сині
		color = COLORS['blue']
	elif colorMark == 'o':		#Помаранчеві
		color = COLORS['orange']
	elif colorMark == 'y':		#Жовті
		color = COLORS['yellow']
	elif colorMark == 'p':		#Фіолетові
		color = COLORS['purple']
	return color

#Зміщення рядка ліворуч або праворуч
func shiftRow(row, dir):
	var tempRow = []
	for i in range(gameSize.x):
		tempRow.append(mainArray[i * gameSize.y + row])
	var tail
	if dir < 0:
		for j in range(abs(dir)):
			tail = tempRow[0]
			for i in range(tempRow.size() - 1):
				tempRow[i] = tempRow[i+1]
			tempRow[tempRow.size() - 1] = tail
	elif dir > 0:
		for j in range(abs(dir)):
			tail = tempRow[tempRow.size() - 1]
			for i in range((tempRow.size() - 1), 0 , -1):
				tempRow[i] = tempRow[i - 1]
			tempRow[0] = tail
	for i in range(gameSize.x):
		mainArray[i * gameSize.y + row] = tempRow[i]
		
# Пошук позиції кульки за її ім'ям
func findBallByName(name):
	var index = 0
	for b in mainArray:
		if b == name:
			var col = int(index / gameSize.y)
			var row = (index - col * gameSize.y)
			return(Vector2(col,row))
		index += 1

#Перемішати кульки
func shuffleBalls():
	steps = 0
	var shuffledList = [] 
	var indexList = range(mainArray.size())
	for i in range(mainArray.size()):
		var x = randi()%indexList.size()
		shuffledList.append(mainArray[indexList[x]])
		indexList.remove(x)
	mainArray = shuffledList


#Обновлення позицій кульок
func updateBalls():
	var index = 0
	var table = []
	for b in mainArray:
		var col = int(index / gameSize.y)
		var row = (index - col * gameSize.y)
		var name = "b" + mainArray[index]
		if not get_node("game/balls/" + name):
			createBall(name)
		get_node("game/balls/b" + mainArray[index]).set_pos(Vector2(col * (BALL_SIZE), row * (BALL_SIZE)))
		index += 1
		get_node("canvas/bottom/steps").set_text(str(steps))

#Обробка сигналів кнопок
func _signal_arrow(rowDir):
	shiftRow(abs(rowDir) - 1, sign(int(rowDir)))
	updateBalls()

func cutCol(ball):
	if ball.x < gameSize.x and ball.y < gameSize.y:
		var column = []
		var i
		for b in range(gameSize.y):
			i = b + (ball.x * gameSize.y)
			column.append(mainArray[i])
		var empty = findBallByName('')
	
		var dir = 1
		if empty.y > ball.y:
			dir = -1
		i = empty.y
		while(i != ball.y):
			column[i] = column[i + dir]
			
			i += dir
		column[ball.y] = ''
		for b in range(gameSize.y):
			i = b + (ball.x * gameSize.y)
			mainArray[i] = column[b]

func get_ball_on_grid(onGrid):
	var i = onGrid.y + (onGrid.x * gameSize.y)
	if onGrid.x < gameSize.x and onGrid.y < gameSize.y:
		return mainArray[i]

func get_ball_at_cursor(cursor_pos):
	var cursorOnGrid = Vector2(0,0)
	var scale = get_node("game").get_scale().x
	cursorOnGrid.x = int((cursor_pos.x/scale) / BALL_SIZE) - 1 
	cursorOnGrid.y = int((cursor_pos.y/scale - BALL_SIZE/2) / BALL_SIZE)
	return cursorOnGrid

func _signal_ballClicked(name):
	if name != 'b':
		name = name[1] + name[2]
		ballPressedName = name
	else:
		ballPressedName = ''
	ballPressed = true

func ball_clicked(cursor_position):

	ballPressed = true


func _on_back_pressed():
	get_node("/root/global").goto_scene("res://scenes/startMenu.tscn")

