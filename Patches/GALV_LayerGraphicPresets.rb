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
#
# Assign the first layer to "SWITCH" and the first entry after the switch to make
# it conditional.
PRESETS = { 
  "Desert" =>
  [
    ["SWITCH", 7],
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
    
    map.note.split("\n").each do |line| # Don't clear if no preset
      match = line.match(/<preset:\s*(.+?)\s*>/)
      map_note = match ? match[1] : nil
      if map_note
        layers[@map_id].clear if layers[@map_id]
        break
      end
    end 
    
    @map = load_data(sprintf("Data/Map%03d.rvdata2", map_id))
    map = @map
    enabled = true
    map_note = ""
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
end