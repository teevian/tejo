extends SceneTree
const Art = preload('res://scripts/open_world_art.gd')
class Preview:
 extends Node2D
 var phase=0.0
 var dirs=[Vector2.DOWN,Vector2(1,1).normalized(),Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized()]
 func _ready():
  var ink=ShaderMaterial.new();ink.shader=preload('res://shaders/opaque_cutout.gdshader');material=ink
 func _draw():
  for kind in 2:
   for d in 8:
    Art.draw_pose(self,kind,dirs[d],true,phase*Art.STRIDE,Vector2(65+d*130,210+kind*230))
func _initialize():call_deferred('run')
func run():
 var view=SubViewport.new();view.size=Vector2i(1040,480);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view);RenderingServer.set_default_clear_color(Color('56665c'))
 var preview=Preview.new();view.add_child(preview)
 DirAccess.make_dir_recursive_absolute('/tmp/tejo-gait-verified')
 for frame in 48:
  preview.phase=float(frame)/24.0;preview.queue_redraw()
  await process_frame
  RenderingServer.force_draw()
  view.get_texture().get_image().save_png('/tmp/tejo-gait-verified/%03d.png'%frame)
 quit()
