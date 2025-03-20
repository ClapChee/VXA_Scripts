($imported ||= {})["CLAP_SmoothBattlelog"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_SmoothBattlelog
# ---------------------------------------------------------------------------- #
# Simply adds a small slide for the battlelog text. Can be disabled from the
# options menu if YEA - System Options is present.
# ---------------------------------------------------------------------------- #

module CLAP_SmoothBattleLog
#------------------------------------------------------------------------------#
  # How many frames to wait at the end of a turn?
    DELAY = 60
  # How fast should the text slide in? 1 is instant.
    SLIDE_VALUE = 0.15
#------------------------------------------------------------------------------#
end

class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  alias smooth_battlelog_initialize initialize
  def initialize
    smooth_battlelog_initialize
    @line_pos = {}
    $game_system.smooth_battlelog = false if !$imported["YEA-SystemOptions"]
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    draw_background
    contents.clear
    @lines.size.times {|i| draw_line(i) }
  end
  #--------------------------------------------------------------------------
  # * Draw Line
  #--------------------------------------------------------------------------
  def draw_line(line_number)
    return if !hash_valid(line_number)
    line_hash_index = @line_pos[line_number]
    draw_text_ex(line_hash_index[:x], line_hash_index[:y], @lines[line_number])
  end
  #--------------------------------------------------------------------------
  # * Wait
  #--------------------------------------------------------------------------
  def wait(wait_val = -1)
    if wait_val < 1 || wait_val == CLAP_SmoothBattleLog::DELAY
      wait_val = 1
    end
    @num_wait += 1
    @method_wait.call(wait_val) if @method_wait
  end
  #--------------------------------------------------------------------------
  # * Wait and Clear
  #--------------------------------------------------------------------------
  def wait_and_clear
    wait(CLAP_SmoothBattleLog::DELAY) while @num_wait < CLAP_SmoothBattleLog::DELAY if line_number > 0
    clear
  end
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  def clear
    @num_wait = 0
    @lines.clear
    @line_pos.clear if hash_valid(@line_pos[0])
    refresh
  end
  #--------------------------------------------------------------------------
  # * Replace Text
  #--------------------------------------------------------------------------
  def replace_text(text)
    @lines.pop
    @lines.push(text)
    pop_hash(@lines.size - 1)
    add_to_line_pos(@lines.size - 1)
  end
  #--------------------------------------------------------------------------
  # * Add Text
  #--------------------------------------------------------------------------
  def add_text(text)
    @lines.push(text)
    add_to_line_pos(@lines.size - 1)
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  alias smooth_battlelog_update update
  def update
    smooth_battlelog_update
    if @lines.size > 0 && $game_system.smooth_battlelog
      lerp_val = CLAP_SmoothBattleLog::SLIDE_VALUE
      @line_pos.each do |line_number, position|
        position[:x] = lerp(position[:x], position[:original_x], lerp_val)
        position[:y] = lerp(position[:y], position[:original_y], lerp_val)
      end
      refresh
    elsif @lines.size > 0
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # * Add line position into hash
  #--------------------------------------------------------------------------
  def add_to_line_pos(line_number)
    rect = Rect.new
    rect.width = item_width
    rect.height = item_height
    rect.x = (line_number % col_max * (item_width + spacing)) + standard_padding
    rect.y = (line_number / col_max * item_height) + custom_padding
    
    line_hash_index = @line_pos[line_number] if hash_valid(line_number)
       
    @line_pos[line_number] = { 
    x: $game_system.smooth_battlelog ? 0 : rect.x + 16, 
    y: rect.y, 
    original_x: rect.x + 16,
    original_y: rect.y}
  end
  #--------------------------------------------------------------------------
  # * Pop the position hash
  #--------------------------------------------------------------------------
  def pop_hash(line_number)
    return if !hash_valid(line_number)
    last_key, last_value = @line_pos.to_a.pop
    @line_pos.delete(last_key)
  end
  #--------------------------------------------------------------------------
  # * Check if Hash exists and has values
  #--------------------------------------------------------------------------
  def hash_valid(line_number)
    line_hash_index = @line_pos[line_number]
    return false if !line_hash_index
    return false if !line_hash_index.key?(:x) || !line_hash_index.key?(:y)
    return true
  end
  #--------------------------------------------------------------------------
  # * Go Back One Line
  #--------------------------------------------------------------------------
  def back_one
    @lines.pop
    pop_hash(@lines.size - 1)
    refresh
  end
  #--------------------------------------------------------------------------
  # * Linear Interpolation
  #--------------------------------------------------------------------------
  def lerp(start, stop, step)
    (stop * step) + (start * (1.0 - step))
  end
  #--------------------------------------------------------------------------
  # * Get Standard Padding Size
  #--------------------------------------------------------------------------
  def standard_padding
    return 0
  end
  #--------------------------------------------------------------------------
  # * Get Custom Padding Size
  #--------------------------------------------------------------------------
  def custom_padding
    return 12
  end
  #--------------------------------------------------------------------------
  # * Get Background Rectangle
  #--------------------------------------------------------------------------
  def back_rect
    Rect.new(0, custom_padding, width, line_number * line_height)
  end
end

class Game_System
  alias smooth_battle_log_initialize initialize
  attr_accessor :smooth_battlelog
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize
    smooth_battle_log_initialize
    @smooth_battlelog = true if @smooth_battlelog.nil? || !$imported["YEA-SystemOptions"]
  end
end

#--------------------------------------------------------------------------
# * Hook into YEA - System Options
#--------------------------------------------------------------------------
if $imported["YEA-SystemOptions"]
  YEA::SYSTEM::COMMANDS.push(:smooth_battlelog)
  YEA::SYSTEM::COMMAND_VOCAB[:smooth_battlelog] = [
    "Smooth Battlelog", "On", "Off",
    "Battlelog text slides into place."
  ]
  class Window_SystemOptions < Window_Command
    alias smooth_battle_log_draw_item draw_item 
    alias smooth_battle_log_draw_toggle draw_toggle
    alias smooth_battle_log_cursor_change cursor_change 
    alias smooth_battle_log_change_toggle change_toggle 
    alias smooth_battle_log_make_command_list make_command_list 
    #--------------------------------------------------------------------------
    # * Make command list
    #--------------------------------------------------------------------------
    def make_command_list
      smooth_battle_log_make_command_list
      add_command(YEA::SYSTEM::COMMAND_VOCAB[:smooth_battlelog][0], :smooth_battlelog)
      @help_descriptions[:smooth_battlelog] = YEA::SYSTEM::COMMAND_VOCAB[:smooth_battlelog][3]
      old_index = @list.size - 1
      new_index = [old_index - 4, 0].max
      @list.insert(new_index, @list.delete_at(old_index))
    end
    #--------------------------------------------------------------------------
    # Draw the option
    #--------------------------------------------------------------------------
    def draw_item(index)
      case @list[index][:symbol]
      when :smooth_battlelog
        reset_font_settings
        rect = item_rect(index)
        contents.clear_rect(rect)
        draw_toggle(item_rect_for_text(index), index, @list[index][:symbol])
      else
        smooth_battle_log_draw_item(index)
        return
      end
    end
    #--------------------------------------------------------------------------
    # Draw the toggle text
    #--------------------------------------------------------------------------
    def draw_toggle(rect, index, symbol)
      name = @list[index][:name]
      dx = contents.width / 2

      case symbol
      when :smooth_battlelog
        enabled = !$game_system.smooth_battlelog
      else
        smooth_battle_log_draw_toggle(rect, index, symbol)
        return
      end
      draw_text(0, rect.y, contents.width / 2, line_height, name, 1)
      change_color(normal_color, !enabled)
      option1 = YEA::SYSTEM::COMMAND_VOCAB[symbol][1]
      draw_text(dx, rect.y, contents.width / 4, line_height, option1, 1)
      dx += contents.width / 4
      change_color(normal_color, enabled)
      option2 = YEA::SYSTEM::COMMAND_VOCAB[symbol][2]
      draw_text(dx, rect.y, contents.width / 4, line_height, option2, 1)
    end
    #--------------------------------------------------------------------------
    # Change cursor positions
    #--------------------------------------------------------------------------
    def cursor_change(direction)
      case current_symbol
      when :smooth_battlelog
        change_toggle(direction)
      else
        smooth_battle_log_cursor_change(direction)
        return
      end
    end
    #--------------------------------------------------------------------------
    # Process the toggle
    #--------------------------------------------------------------------------
    def change_toggle(direction)
      value = direction == :left ? true : false
      case current_symbol
      when :smooth_battlelog
        current_case = $game_system.smooth_battlelog
        $game_system.smooth_battlelog = value
      else
         smooth_battle_log_change_toggle(direction)
         return
      end
      Sound.play_cursor if value != current_case
      draw_item(index)
    end
  end
end