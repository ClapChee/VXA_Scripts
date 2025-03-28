($imported ||= {})["CLAP_AutoZSort"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_AutoZSort
# ---------------------------------------------------------------------------- #
# Automagically makes characters appear above or below others depending on their
# y position.
# By default, putting "<no_z_sort>" in a comment anywhere on the events page
# will have them behave like normal.
# ---------------------------------------------------------------------------- #

class Game_Event < Game_Character
  attr_accessor :z_sortable
  alias auto_z_sort_initialize initialize
  #--------------------------------------------------------------------------
  # Initialize
  #--------------------------------------------------------------------------
  def initialize(map_id, event)
    auto_z_sort_initialize(map_id, event)
    
    # You can edit the phrase if you'd like
    no_z_sort_phrase = "<no_z_sort>"
    
    @z_sortable = true
    for p in event.pages
      for l in p.list
        if l.code == 108
          @z_sortable = false if l.parameters[0] == no_z_sort_phrase
        end
      end
    end
  end
end

class Game_CharacterBase
  #--------------------------------------------------------------------------
  # Get Z Index
  #--------------------------------------------------------------------------
  def screen_z
    return @priority_type * ($game_map.height * 2) if self.is_a?(Game_Event) && !@z_sortable
    p_check = @priority_type == 0 ? 1 : 0
    return @y + @priority_type + p_check
  end
end
