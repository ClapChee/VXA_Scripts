class Layer_Graphic < Plane
  def initialize(viewport,id)
    super(viewport)
    @id = id
    if SceneManager.scene_is?(Scene_Battle)
      @layers = $game_map.blayers
    else
      @layers = $game_map.layers[$game_map.map_id]
    end
    @layers
    init_settings
  end

  def init_settings
    # get filename from first element of current layer data array in the array of layers
    @name = @layers[@id][0]  # filename
    self.bitmap = Cache.layers(@name)
    @width = self.bitmap.width
    @height = self.bitmap.height
    
    if (!@layers[@id].nil?)
      # get stored values for movedx and movedy
      @movedx = @layers[@id][8].to_f
      @movedy = @layers[@id][9].to_f
    end
    
  end

  def update
    change_graphic if @name != @layers[@id][0]
    update_opacity
    update_movement
  end
  
  def change_graphic
    @name = @layers[@id][0]
    self.bitmap = Cache.layers(@name)
    @width = self.bitmap.width
    @height = self.bitmap.height
  end
  
  def update_movement
    
    # check if movedx/movedy conflict with stored values,
    # if they do, update movedx and movedy to the stored values
    if ((@layers[@id][8] != @movedx) || (@layers[@id][9] != @movedy))
      @movedx = @layers[@id][1]
      @movedy = @layers[@id][2]
    end
    
    # move the layer on the x and y axis according to map speed
    self.ox = 0 + $game_map.display_x * 32 + @movedx + xoffset
    self.oy = 0 + $game_map.display_y * 32 + @movedy + yoffset
    @movedx += @layers[@id][1] # x move speed
    @movedy += @layers[@id][2] # y move speed
    @movedx = 0 if @movedx >= @width
    @movedy = 0 if @movedy >= @height
    
    # update stored values for movedx and movedy
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
      # make sure the map layer data isn't nil
      if (!$game_map.layers[$game_map.map_id].nil?)
        $game_map.layers[$game_map.map_id][@id][8] = @movedx.to_f
        $game_map.layers[$game_map.map_id][@id][9] = @movedy.to_f
      end
    end
    
    self.z = @layers[@id][4]
    self.blend_type = @layers[@id][5]
  end
  
  def xoffset
    $game_map.display_x * @layers[@id][6]
  end
  def yoffset
    $game_map.display_y * @layers[@id][7]
  end

  def update_opacity
    self.opacity = @layers[@id][3]
  end
  
  def dispose
    $game_map.layers[0][@id] = [@movedx,@movedy]
    self.bitmap.dispose if self.bitmap
    super
  end
end # Layer_Graphic < Plane