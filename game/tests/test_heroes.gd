extends GutTest

const HeroModel = preload("res://scripts/hero_model.gd")

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func test_both_starters_have_skeleton_and_animated_clips() -> void:
	for choice in ["male", "female"]:
		var hero = HeroModel.new()
		add_child_autofree(hero)
		hero.setup(choice)
		var skeleton := _find_skeleton(hero)
		assert_not_null(skeleton)
		assert_eq(skeleton.get_bone_count(), 53)
		for clip in ["Idle", "Walk", "Run"]:
			hero.play_clip(clip)
			assert_eq(hero.current_clip, clip)
			var anim: Animation = hero.animation_player.get_animation(hero.animation_player.current_animation)
			assert_gt(anim.length, 0.5)
			assert_eq(anim.loop_mode, Animation.LOOP_LINEAR)
			assert_gte(anim.get_track_count(), 12, "Constant tracks may be optimized by Godot")
		hero.play_clip("Walk")
		hero.animation_player.play("Walk", 0.0)
		hero.animation_player.seek(0.0, true)
		var thigh := skeleton.find_bone("thigh_l")
		var before := skeleton.get_bone_pose_rotation(thigh)
		hero.animation_player.seek(0.25, true)
		assert_ne(skeleton.get_bone_pose_rotation(thigh), before, "Walk actually moves a leg bone")

func test_hero_selection_switches_model_and_keeps_clip() -> void:
	var scene = load("res://scenes/hero_select.tscn").instantiate()
	add_child_autofree(scene)
	scene.clip = "Run"
	scene.choose("female")
	assert_eq(scene.appearance, "female")
	assert_eq(scene.hero.current_clip, "Run")

	scene.choose("male")
	assert_eq(scene.appearance, "male")
	assert_eq(scene.hero.current_clip, "Run")

func test_elbows_flex_and_hands_stay_clear_of_hips() -> void:
	for choice in ["female", "male"]:
		var hero = HeroModel.new()
		add_child_autofree(hero)
		hero.setup(choice)
		var skeleton := _find_skeleton(hero)
		for clip in ["Idle", "Walk", "Run"]:
			hero.animation_player.play(clip, 0.0)
			var duration: float = hero.animation_player.get_animation(clip).length
			for side in ["l", "r"]:
				var smallest_bend := PI
				var largest_bend := 0.0
				var shoulder := skeleton.find_bone("upperarm_" + side)
				hero.animation_player.seek(duration * 0.25, true)
				var first := skeleton.get_bone_pose_rotation(shoulder)
				hero.animation_player.seek(duration * 0.75, true)
				if clip != "Idle":
					assert_gt(first.angle_to(skeleton.get_bone_pose_rotation(shoulder)), 0.5,
						choice + " " + clip + " swings from the shoulder")
				for sample in range(24):
					hero.animation_player.seek(duration * sample / 24.0, true)
					skeleton.force_update_all_bone_transforms()
					var wrist := skeleton.get_bone_global_pose(skeleton.find_bone("hand_" + side)).origin
					var hip := skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin
					var shoulder_pos := skeleton.get_bone_global_pose(shoulder).origin
					var elbow := skeleton.get_bone_global_pose(skeleton.find_bone("lowerarm_" + side)).origin
					var bend := (elbow - shoulder_pos).angle_to(wrist - elbow)
					smallest_bend = minf(smallest_bend, bend)
					largest_bend = maxf(largest_bend, bend)
					assert_gt(absf(wrist.x - hip.x), 0.25,
						choice + " " + clip + " keeps the wrist outside the hip silhouette")
				if clip != "Idle":
					assert_gt(largest_bend - smallest_bend, 0.2,
						choice + " " + clip + " changes elbow bend through the stride")
				if clip == "Run":
					assert_gt(smallest_bend, 0.8, choice + " runs with bent elbows")

func test_field_uses_skinned_hero_and_movement_selects_clip() -> void:
	var scene = load("res://scenes/ravenwood.tscn").instantiate()
	add_child_autofree(scene)
	assert_not_null(_find_skeleton(scene.hero_visual))
	scene.transition_lock = 100
	scene._walk(Vector2.RIGHT, 0.1)
	assert_eq(scene.hero_visual.current_clip, "Walk")
	scene.waypoints.clear()
	scene._walk(Vector2.ZERO, 0.1)
	assert_eq(scene.hero_visual.current_clip, "Idle")

func test_choice_persists_without_class_restriction() -> void:
	var path := "user://test-hero-selection.cfg"
	for choice in ["female", "male"]:
		assert_eq(HeroModel.save_choice(choice, path), OK)
		assert_eq(HeroModel.selected(path), choice)
	assert_eq(HeroModel.save_choice("unknown", path), ERR_INVALID_PARAMETER)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_locomotion_matches_speed_and_exposes_running() -> void:
	var hero = HeroModel.new()
	add_child_autofree(hero)
	hero.setup("female")
	hero.update_locomotion(0.5642, 0.7, false)
	assert_eq(hero.current_clip, "Walk")
	assert_almost_eq(hero.animation_player.speed_scale, 1.0, 0.01)
	hero.update_locomotion(1.5274, 0.7, true)
	assert_eq(hero.current_clip, "Run")
	assert_almost_eq(hero.animation_player.speed_scale, 1.0, 0.01)
	hero.update_locomotion(0.0, 0.7, true)
	assert_eq(hero.current_clip, "Idle")
