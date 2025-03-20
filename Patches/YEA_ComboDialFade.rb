# Makes the combo window fade out if a skill is currently being used.
# Needs to go below YEA - Input Combo Skill related scripts

unless !$imported["YEA-InputComboSkills"]
($imported ||= {})["CLAP_InputComboSkillsFade"] = true
class Scene_Battle < Scene_Base
  alias combo_fade_create_all_windows scene_battle_create_all_windows_ics
  alias combo_fade_update_combo_skill_queue update_combo_skill_queue
  alias combo_fade_scene_battle_update_basic_ics scene_battle_update_basic_ics
  
  def scene_battle_create_all_windows_ics
    @combo_skill_queue = []
    @combo_list_is_empty = true  
    combo_fade_create_all_windows
    
    # ----------------------------------------------------------
    
    # Edit this to your desired opacity (255 is fully visible)
    @dimmed_opacity = 64
    
    # Edit this to change the speed of the fade (1.0 is instant)
    @dim_lerp_value = 0.25
    
    # ----------------------------------------------------------
    
  end
  
  def update_combo_skill_queue
    @combo_list_is_empty = @combo_skill_queue ? @combo_skill_queue.empty? : true
    combo_fade_update_combo_skill_queue
    @combo_list_is_empty = @combo_skill_queue ? @combo_skill_queue.empty? : true
  end
  def scene_battle_update_basic_ics
    combo_fade_scene_battle_update_basic_ics
    dim_combo_window
  end
  #--------------------------------------------------------------------------
  # * Dim the combo window
  #--------------------------------------------------------------------------
  def dim_combo_window
    if @combo_list_is_empty
      @input_combo_skill_window.contents_opacity  = 
      lerp(@input_combo_skill_window.contents_opacity, 255, @dim_lerp_value)
      @input_combo_info_window.contents_opacity  = 
      lerp(@input_combo_info_window.contents_opacity, 255, @dim_lerp_value)
    else
      @input_combo_skill_window.contents_opacity  = 
      lerp(@input_combo_skill_window.contents_opacity, @dimmed_opacity, @dim_lerp_value)
      @input_combo_info_window.contents_opacity  = 
      lerp(@input_combo_info_window.contents_opacity, @dimmed_opacity, @dim_lerp_value)
    end
  end
  #--------------------------------------------------------------------------
  # * Linear Interpolation
  #--------------------------------------------------------------------------
  def lerp(start, stop, step)
    (stop * step) + (start * (1.0 - step))
  end
end
end