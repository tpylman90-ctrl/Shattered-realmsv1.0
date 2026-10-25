class_name FieldSurface
extends RefCounted

var outline := PackedVector2Array()
var vertices := PackedVector3Array()
var triangles := PackedInt32Array()
var camera: Camera3D
var graph := AStar2D.new()

func configure(view: Camera3D, points: Array, heights: Array) -> void:
	camera = view
	outline.clear()
	vertices.clear()
	for i in points.size():
		var point := Vector2(points[i][0], points[i][1])
		outline.append(point)
		var origin := camera.project_ray_origin(point)
		var direction := camera.project_ray_normal(point)
		vertices.append(Plane(Vector3.UP, float(heights[i])).intersects_ray(origin, direction))
	triangles = Geometry2D.triangulate_polygon(outline)
	graph.clear()
	for i in outline.size():
		graph.add_point(i, outline[i])
	for i in outline.size():
		for j in range(i + 1, outline.size()):
			if visible_segment(outline[i], outline[j]):
				graph.connect_points(i, j)

func contains(point: Vector2) -> bool:
	if Geometry2D.is_point_in_polygon(point, outline):
		return true
	for i in outline.size():
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, outline[i], outline[(i + 1) % outline.size()])) < 0.1:
			return true
	return false

func constrain(point: Vector2) -> Vector2:
	if contains(point):
		return point
	var result := outline[0]
	var distance := INF
	for i in outline.size():
		var candidate := Geometry2D.get_closest_point_to_segment(point, outline[i], outline[(i + 1) % outline.size()])
		if candidate.distance_squared_to(point) < distance:
			distance = candidate.distance_squared_to(point)
			result = candidate
	return result

func visible_segment(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(2, ceili(a.distance_to(b) / 3.0))
	for step in range(1, steps):
		if not contains(a.lerp(b, float(step) / steps)):
			return false
	return true

func world_at(point: Vector2) -> Vector3:
	point = constrain(point)
	var origin := camera.project_ray_origin(point)
	var direction := camera.project_ray_normal(point)
	for i in range(0, triangles.size(), 3):
		var hit = Geometry3D.ray_intersects_triangle(origin, direction, vertices[triangles[i]], vertices[triangles[i + 1]], vertices[triangles[i + 2]])
		if hit != null:
			return hit
	# Boundary precision fallback: move a fraction toward an adjacent triangle's center.
	for i in range(0, triangles.size(), 3):
		var a := outline[triangles[i]]
		var b := outline[triangles[i + 1]]
		var c := outline[triangles[i + 2]]
		if Geometry2D.is_point_in_polygon(point, PackedVector2Array([a, b, c])):
			var inner := point.lerp((a + b + c) / 3.0, 0.001)
			var hit = Geometry3D.ray_intersects_triangle(camera.project_ray_origin(inner), camera.project_ray_normal(inner), vertices[triangles[i]], vertices[triangles[i + 1]], vertices[triangles[i + 2]])
			if hit != null:
				return hit
	return vertices[0]

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	from = constrain(from)
	to = constrain(to)
	if visible_segment(from, to):
		return PackedVector2Array([to])
	var start := outline.size()
	var finish := start + 1
	graph.add_point(start, from)
	graph.add_point(finish, to)
	for i in outline.size():
		if visible_segment(from, outline[i]):
			graph.connect_points(start, i)
		if visible_segment(to, outline[i]):
			graph.connect_points(finish, i)
	var path := graph.get_point_path(start, finish)
	graph.remove_point(start)
	graph.remove_point(finish)
	if path.size() > 0:
		path.remove_at(0)
	return path

func collision_faces() -> PackedVector3Array:
	var faces := PackedVector3Array()
	for i in range(0, triangles.size(), 3):
		var a := vertices[triangles[i]]
		var b := vertices[triangles[i + 1]]
		var c := vertices[triangles[i + 2]]
		if (b - a).cross(c - a).y < 0:
			faces.append_array(PackedVector3Array([a, c, b]))
		else:
			faces.append_array(PackedVector3Array([a, b, c]))
	return faces
