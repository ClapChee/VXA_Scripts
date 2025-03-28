unless !$imported["Galv_Layers"]
($imported ||= {})["CLAP_LayerGraphicPresets"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_LayerGraphicPresets
# ---------------------------------------------------------------------------- #
# Set presets below and call them in the map's note tag to automatically 
# initialize them when a map is loaded.
# ---------------------------------------------------------------------------- #
module CLAP_LayerGraphicPresets
#
#["Filename", AutoScrollX, AutoScrollY, Opacity, Z, Blend, ParallaxX, ParallaxY]
# Put the preset ID in the map's note like this: <preset: MyPreset>
#
# Setting either Parallax X or ParallaxY to nil will make that function like a
# regular parallax; calculating the offset via map and image size
#
# Assign the first layer to "SWITCH" and the first entry after the switch to make
# it conditional.
#
PRESETS = { 
  "Desert" =>
  [
	["SWITCH", 7],
    ["Desert Background", 0, 0, 255, -10, 0, nil, nil],
    ["Desert Mountains Back", 0, 0, 255, -9, 0, -26, -26],
    ["Desert Clouds", 0.1, 0, 255, -7, 0, -24, -24],
    ["Desert Mountains", 0, 0, 255, -8, 0, -22, -22]
  ],
  "Park" =>
  [
    ["Park Background", 0, 0, 255, -10, 0, nil, nil],
    ["Park Mountains", 0, 0, 255, -8, 0, -26, -26],
    ["Park Trees Background", 0, 0, 255, -7, 0, -20, 32],
    ["Park Sun", 0, 0, 255, -9, 0, nil, nil]
  ],
}
end

# ---------------------------------------------------------------------------- #
# Set the layers for the maps via note
# ---------------------------------------------------------------------------- #
class Game_Map
  attr_accessor :map
  alias preset_layer_graphics_setup setup
  
  def setup(map_id)
    preset_layer_graphics_setup(map_id)
    map_note = ""
    
    map.note.split("\n").each do |line| # Don't clear if no preset
      match = line.match(/<preset:\s*(.+?)\s*>/)
      map_note = match ? match[1] : nil
      if map_note
        layers[@map_id].clear if layers[@map_id]
        break
      end
    end 
    
    if map_note == "" # Don't bother with layers if no preset
      interpreter.refresh_layers if SceneManager.scene.is_a?(Scene_Map)
      return
    end
    
    @map = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
    map = @map
    enabled = true
    switchless = ""
    
    # We check every note to see if they have a switch
    map.note.split("\n").each do |line|
      match = line.match(/<preset:\s*(.+?)\s*>/)
      map_note = match ? match[1] : nil
      next if map_note.nil?
      switchless = map_note if CLAP_LayerGraphicPresets::PRESETS[map_note][0][0] != "SWITCH"
      if CLAP_LayerGraphicPresets::PRESETS[map_note][0][0] == "SWITCH"
        enabled = false
        switch_num = CLAP_LayerGraphicPresets::PRESETS[map_note][0][1]
        switch_val = $game_switches[switch_num]
        if switch_val
          enabled = true
          break
        end
        map_note = ""
      end
    end
    
    # Process the layers
    if (CLAP_LayerGraphicPresets::PRESETS[map_note] && enabled) || switchless != ""
      counter = 0
      map_note = switchless if map_note == ""
      for i in CLAP_LayerGraphicPresets::PRESETS[map_note]
        if CLAP_LayerGraphicPresets::PRESETS[map_note][counter][0] == "SWITCH"
          counter += 1
          next
        end
        if layers[map_id].nil? || layers[map_id][counter].nil?
          interpreter.layer(map_id, counter, CLAP_LayerGraphicPresets::PRESETS[map_note][counter])
        end
        counter += 1
      end
    end
    interpreter.refresh_layers if SceneManager.scene.is_a?(Scene_Map)
  end
end

class Game_Player < Game_Character # WE REFRESH ONLY IF DONE TRANSFERING
  attr_accessor :transferring
  alias original_perform_transfer_patch perform_transfer
  def perform_transfer
    if transfer?
      original_perform_transfer_patch
      SceneManager.scene.spriteset.refresh_layers if SceneManager.scene.is_a?(Scene_Map)
    end
  end
end

class Layer_Graphic < Plane
  def init_settings
    self.z = @layers[@id][4]
    self.blend_type = @layers[@id][5]
    @name = @layers[@id][0]
    self.bitmap = Cache.layers(@name)
    @width = self.bitmap.width
    @height = self.bitmap.height
    
    if (!@layers[@id].nil?)
      @movedx = @layers[@id][8].to_f
      @movedy = @layers[@id][9].to_f
    end
  end
end

class Spriteset_Map  # DO NOT!!! Refresh if we are mid-transfer
  def refresh_layers
    dispose_layers
    return if $game_player.transferring
    create_layers
  end
end

# ---------------------------------------------------------------------------- #
# Patches to allow for default Parralax behaviour for layers
# ---------------------------------------------------------------------------- #

class Layer_Graphic < Plane
  def update_movement
    if ((@layers[@id][8] != @movedx) || (@layers[@id][9] != @movedy))
      @movedx = @layers[@id][1]
      @movedy = @layers[@id][2]
    end
    
    if @layers[@id][6].nil? && @layers[@id][7].nil? # We patch in here
      self.ox = parallax_ox(bitmap)
      self.oy = parallax_oy(bitmap)
    else
      self.ox = 0 + $game_map.display_x * 32 + @movedx + xoffset
      self.oy = 0 + $game_map.display_y * 32 + @movedy + yoffset
    end
    @movedx += @layers[@id][1]
    @movedy += @layers[@id][2]
    @movedx = 0 if @movedx >= @width
    @movedy = 0 if @movedy >= @height
    
    @layers[@id][8] = @movedx.to_f
    @layers[@id][9] = @movedy.to_f
    if (SceneManager.scene_is?(Scene_Battle))
      if (!$game_map.blayers.nil?)
        if (!$game_map.blayers[@id].nil?)
          $game_map.blayers[@id][8] = @movedx.to_f
          $game_map.blayers[@id][9] = @movedy.to_f
        end
      end
    else
      if (!$game_map.layers[$game_map.map_id].nil?)
        $game_map.layers[$game_map.map_id][@id][8] = @movedx.to_f
        $game_map.layers[$game_map.map_id][@id][9] = @movedy.to_f
      end
    end
    
    self.z = @layers[@id][4]
    self.blend_type = @layers[@id][5]
  end
  
  # We yoink these straight from the base code
  #--------------------------------------------------------------------------
  # * Calculate X Coordinate of Parallax Display Origin
  #--------------------------------------------------------------------------
  def parallax_ox(bitmap)
    if $game_map.map.parallax_loop_x
      $game_map.display_x * 16
    else
      w1 = [bitmap.width - Graphics.width, 0].max
      w2 = [$game_map.map.width * 32 - Graphics.width, 1].max
      $game_map.display_x * 32 * w1 / w2
    end
  end
  #--------------------------------------------------------------------------
  # * Calculate Y Coordinate of Parallax Display Origin
  #--------------------------------------------------------------------------
  def parallax_oy(bitmap)
    if $game_map.map.parallax_loop_y
      $game_map.display_y * 16
    else
      h1 = [bitmap.height - Graphics.height, 0].max
      h2 = [$game_map.map.height * 32 - Graphics.height, 1].max
      $game_map.display_y * 32 * h1 / h2
    end
  end
end
end