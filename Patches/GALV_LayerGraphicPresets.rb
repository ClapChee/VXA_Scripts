unless !$imported["Galv_Layers"]
($imported ||= {})["CLAP_LayerGraphicPresets"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_LayerGraphicPresets
# ---------------------------------------------------------------------------- #
# Set presets below and call them in the map's note tag to automatically 
# initialize them when a map is loaded.
# ---------------------------------------------------------------------------- #
module CLAP_LayerGraphicPresets
  
#["Filename", AutoScrollX, AutoScrollY, Opacity, Z, Blend, ParallaxX, ParallaxY]
# Put the preset ID in the map's note like this: <preset: MyPreset>
PRESETS = { 
  "Desert" =>
  [
    ["Desert Background", 0, 0, 255, -10, 0, 0, 0],
    ["Desert Mountains Back", 0, 0, 255, -9, 0, -26, -26],
    ["Desert Clouds", 0.1, 0, 255, -7, 0, -24, -24],
    ["Desert Mountains", 0, 0, 255, -8, 0, -22, -22]
  ],
  "Park" =>
  [
    ["Park Background", 0, 0, 255, -10, 0, 0, 0],
    ["Park Mountains", 0, 0, 255, -8, 0, -26, -26],
    ["Park Trees Background", 0, 0, 255, -7, 0, -20, 32],
    ["Park Sun", 0, 0, 255, -9, 0, -28, 28]
  ]
}
end

# ---------------------------------------------------------------------------- #
# Set the layers for the maps via note
# ---------------------------------------------------------------------------- #
class Game_Map
  attr_accessor :map
  alias preset_layer_graphics_setup setup
  
  def setup(map_id)
    @map = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
    map = @map
    match = map.note.match(/<preset:\s*(.+?)\s*>/)
    map_note = match ? match[1] : nil
    
    if CLAP_LayerGraphicPresets::PRESETS[map_note]
      counter = 0
      for i in CLAP_LayerGraphicPresets::PRESETS[map_note]
        interpreter.layer(map_id, counter, CLAP_LayerGraphicPresets::PRESETS[map_note][counter])
        counter += 1
      end
    end
    
    preset_layer_graphics_setup(map_id)
    
  end
end
# ---------------------------------------------------------------------------- #
# Patches to remove flicker from layers
# ---------------------------------------------------------------------------- #
class Layer_Graphic < Plane
  def init_settings
    @name = @layers[@id][0]
    if @layers[0] && @layers[0][@id]
      @movedx = @layers[0][@id][1].to_f
      @movedy = @layers[0][@id][2].to_f
    else
      @movedx = 0.to_f
      @movedy = 0.to_f
    end
    @width = Cache.layers(@name).width
    @height = Cache.layers(@name).height
    pos = initial_display_pos($game_player.new_x, $game_player.new_y)
    self.ox = 0 + pos[0] * 32 + pos[0] * @layers[@id][6]
    self.oy = 0 + pos[1] * 32 + pos[1] * @layers[@id][7]
    self.z = @layers[@id][4]
    self.blend_type = @layers[@id][5]
    self.bitmap = Cache.layers(@name)
  end
  
  def initial_display_pos(x, y)
    if x < $game_map.screen_tile_x
      x /= 2
    else
      x = (x + 2) / 2
    end
    if y < $game_map.screen_tile_y
      y = 0
    else
      y = (y - 2) / 2
    end
    x = (x + $game_map.width) % $game_map.width
    y = (y + $game_map.height) % $game_map.height
    return [x, y]
  end
end

class Game_Player < Game_Character
  attr_accessor :new_x
  attr_accessor :new_y
end
end