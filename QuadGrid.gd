## @file QuadGrid.gd
# Godot 3.0 implementation of generative art described by Benjamin Kovach in 
# https://www.kovach.me/posts/2018-03-07-generating-art.html
# 
# The way Perlin noise is added to the quad vertecies is not the same as in Benjamin's
# article, but it winds up looking very similar.
#
# GdScript implementation of Perlin noise is from PerduGames: 
# https://github.com/PerduGames/SoftNoise-GDScript-
# @see softnoise.gd
#
# Color palette is the same as used by Benjamin Kovach:
# https://coolors.co/eef4d4-daefb3-ea9e8d-d64550-1c2826
#
# @note There is no antialiasing in 2D in Godot yet. 
# @see https://github.com/godotengine/godot/issues/12840

extends Node2D

var fSoftnoiseScript = preload("res://softnoise.gd")
var fSoftnoise

const COLORS = PoolColorArray([ \
	Color("#eef4d4"), \
	Color("#daefb3"), \
	Color("#ea9e8d"), \
	Color("#d64550"), \
	Color("#1c2826") \
	])

const GRID_SIZE_PX = 600
const GRID_SIZE_QUADS = 24
const GRID_PAD_PX = 16
const GRID_BG_COLOR = Color("#eef4d4")

const QUAD_SIZE_PX = 24
const QUAD_PAD_PX = 8
const QUAD_LINE_WIDTH = 3.0

const CHANCE_FILL = 40		## 40% of the quads are filled
const CHANCE_OUTLINE = 60	## 60% of the quads are outlined/stroked

const XY_NOISE_ARG_SCALE = 100	## Number by which to divide x, y coords that are inputs into the noise function
const NOISE_SCALE = 10			## Number by which to multiply the noise before it's added to x, y coords

## Draw a quad with various parameters.
#
# @param [in]	polyPoints		Quad vertex coords inn PoolVector2Array
# @param [in]	outlineColor	Color with which to outline the quad/poly
# @param [in]	fillColor		Color with which to fill the quad/poly
# @param [in]	drawOutline		When true, the outline is drawn around the quad with @outlineColor
# @param [in]	drawFill		When true, the quad is filled with @fillColor
#
func quadDraw(polyPoints, outlineColor, fillColor, drawOutline, drawFill):
	if drawFill:
		draw_polygon(polyPoints, PoolColorArray([fillColor]))
	if drawOutline:
		# Add the first point to the end of the point list. draw_polygon doesn't like repeating
		# vertices, but draw_polyline requires it
		polyPoints.append(polyPoints[0])
		draw_polyline(polyPoints, outlineColor, QUAD_LINE_WIDTH, false)
		

## Add Perlin 2D nosie to coordinates of every quad point.
# @see SCALE constants in the file header.
#
# @param [in]	qP 	PoolVector2Array of the four quad vertex coordinates
#
func quadAddNoise(qP):
	qP[0].x += fSoftnoise.perlin_noise2d(qP[0].x / XY_NOISE_ARG_SCALE, qP[0].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE
	qP[0].y += fSoftnoise.perlin_noise2d(qP[0].x / XY_NOISE_ARG_SCALE, qP[0].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE

	qP[1].x += fSoftnoise.perlin_noise2d(qP[1].x / XY_NOISE_ARG_SCALE, qP[1].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE
	qP[1].y += fSoftnoise.perlin_noise2d(qP[1].x / XY_NOISE_ARG_SCALE, qP[1].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE

	qP[2].x += fSoftnoise.perlin_noise2d(qP[2].x / XY_NOISE_ARG_SCALE, qP[2].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE
	qP[2].y += fSoftnoise.perlin_noise2d(qP[2].x / XY_NOISE_ARG_SCALE, qP[2].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE

	qP[3].x += fSoftnoise.perlin_noise2d(qP[3].x / XY_NOISE_ARG_SCALE, qP[3].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE
	qP[3].y += fSoftnoise.perlin_noise2d(qP[3].x / XY_NOISE_ARG_SCALE, qP[3].y / XY_NOISE_ARG_SCALE) * NOISE_SCALE
	
	return qP

func _draw():
	randomize()
	
	# Fill background
	draw_rect(Rect2(Vector2(0, 0), OS.window_size), GRID_BG_COLOR, true)

	var quadBBSizeVector = Vector2(QUAD_SIZE_PX, QUAD_SIZE_PX)
	var quadBBRect = Rect2(Vector2(GRID_PAD_PX - QUAD_SIZE_PX, GRID_PAD_PX - QUAD_SIZE_PX), Vector2(QUAD_SIZE_PX, QUAD_SIZE_PX))

	# Seed noise maker with a random integer every time this runs
	fSoftnoise = fSoftnoiseScript.SoftNoise.new(randi())
	
	# Add noise to vertexes of the square in quadBBRect and probabiliscally fill and outline the quad
	for row in range(GRID_SIZE_QUADS):
		quadBBRect.position.x = GRID_PAD_PX
		quadBBRect.position.y += QUAD_SIZE_PX + QUAD_PAD_PX

		for col in range(GRID_SIZE_QUADS):
			quadBBRect.position.x += QUAD_SIZE_PX + QUAD_PAD_PX
			var v2a = PoolVector2Array()
			v2a.append(quadBBRect.position)
			v2a.append(quadBBRect.position + Vector2(quadBBRect.size.x, 0))
			v2a.append(quadBBRect.end)
			v2a.append(quadBBRect.position + Vector2(0, quadBBRect.size.y))

			var fill = false
			var outline = false
			var fillColor = COLORS[0]
			var outlineColor = COLORS[0]
			if (randi() % 100 < CHANCE_FILL):
				fill = true
				fillColor = COLORS[randi() % COLORS.size()-1]
			else:
				outline = true
				outlineColor = COLORS[randi() % COLORS.size()-1]
			quadDraw(quadAddNoise(v2a), outlineColor, fillColor, outline, fill)

