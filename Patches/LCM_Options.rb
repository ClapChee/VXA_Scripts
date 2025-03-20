# Allow various LCM options to appear in YEA - System Options
# Currently supported:
# Auto-Jump (Requiring OK to be pressed to jump)
# Works best when placed below both scripts.

unless !$imported['Liam-LisaCoreMove'] || !$imported['YEA-SystemOptions']
$imported['CLAP_LisaCoreMoveOptions'] = true
module LCM
  module OPTIONS
    
    # EDIT THESE !
    # ---------------------------------------------------------------------------- #

    # Should Auto-Jump (Jumping without pressing OK) be in the menu?
    AUTO_JUMP = true

    # ---------------------------------------------------------------------------- #
    # STOP EDITING !
    
  end
end
#--------------------------------------------------------------------------
# * Hook into Liam - Lisa Core Movement
#--------------------------------------------------------------------------
class Game_CharacterBase
  alias lcm_options_move_straight move_straight
  #--------------------------------------------------------------------------
  # * Patch in the AutoJump
  #--------------------------------------------------------------------------
  def move_straight(d, turn_ok = true)
    return lcm_options_move_straight(d, turn_ok = true) unless $game_system.lcm_options_auto_jump && LCM::OPTIONS::AUTO_JUMP
    # TODO: See how many lines can be removed
    allScriptExecutionReqsMet = true
    allLedgeJumpReqsMet = true
    if allScriptExecutionReqsMet == true
      allScriptExecutionReqsMet = $game_party.getExSaveData('lcmScriptToggle', LCM::LCM_TOGGLE_INIT)
    end
    allScriptExecutionReqsMet = false unless is_a?(Game_Player) || is_a?(Game_Follower)
    if (allScriptExecutionReqsMet == true) && is_a?(Game_Follower)
      allScriptExecutionReqsMet = $game_party.getExSaveData('lcmFollowerToggle', LCM::LCM_FOLLOWERS_ENABLED)
      allScriptExecutionReqsMet = isFollowerAssigned? if allScriptExecutionReqsMet == true
    end
    areFollowersEnabled = $game_party.getExSaveData('lcmFollowerToggle', LCM::LCM_FOLLOWERS_ENABLED)
    charIsFollower = is_a?(Game_Follower)
    followersGameOverDisabled = !LCM::LCM_FOLLOWER_GAMEOVER_ALLOWED
    doFollowerGameOverChecks = (allScriptExecutionReqsMet == true) && (areFollowersEnabled == true) && charIsFollower && followersGameOverDisabled
    doFollowerGameOverChecks = false if through == true
    followerGameOverChecksNecessary = (d != @lastDirection) || !@lastMoveGameOverAvoided
    return if !followerGameOverChecksNecessary && @lastMoveGameOverAvoided && (through == false)
    if doFollowerGameOverChecks && followerGameOverChecksNecessary
      moveWillSucceed = passable?(@x, @y, d)
      lcmGameOverCaused = false
      if moveWillSucceed == true && [4, 6].include?(d)
        refreshCharacterOutfitByActor
        lcmGameOverCaused = followerGameOverChecks(d)
        @lastMoveGameOverAvoided = lcmGameOverCaused
      end
      return if lcmGameOverCaused
    end
    @move_succeed = passable?(@x, @y, d)
    if @move_succeed
      set_direction(d)
      @x = $game_map.round_x_with_direction(@x, d)
      @y = $game_map.round_y_with_direction(@y, d)
      @real_x = $game_map.x_with_direction(@x, reverse_dir(d))
      increase_steps
      if (allScriptExecutionReqsMet == true) && (LCM::LCM_CHECK_EVENT_INDIVIDUAL_OFF_TAGS == true) && (is_a?(Game_Player) || (LCM::LCM_APPLY_OFF_TAGS_TO_PLAYER_ONLY == false))
        tileContainslcmOffToggleEvent = $game_map.checklcmScriptOffTag(@x, @y)
        allScriptExecutionReqsMet = false if tileContainslcmOffToggleEvent == true
      end
      if allScriptExecutionReqsMet == true
        refreshCharacterOutfitByActor
        if d == 4
          @lastDirection = d
          sideFallChecks(@lastDirection)
        elsif d == 6
          @lastDirection = d
          sideFallChecks(@lastDirection)
        end
      end
    elsif turn_ok
      set_direction(d)
      if allScriptExecutionReqsMet == true
        refreshCharacterOutfitByActor
        # -----------------------------------------------------
        # * Patch here
        # if ((allLedgeJumpReqsMet == true) && (self.kind_of?(Game_Player)))
          # if (!LCM::OPTIONS::AUTO_JUMP)
            # allLedgeJumpReqsMet = Input.trigger?(:C)
          # end
        # end
        # -----------------------------------------------------
        if allLedgeJumpReqsMet == true
          if d == 8
            jumpUpLedgeChecks
          elsif d == 2
            jumpDownLedgeChecks
          end
        end
        areFollowersEnabled = $game_party.getExSaveData('lcmFollowerToggle', LCM::LCM_FOLLOWERS_ENABLED)
        lcmGetPlayerFollowers.move if is_a?(Game_Player) && (areFollowersEnabled == true)
      end
      check_event_trigger_touch_front
    end
  end
end
#--------------------------------------------------------------------------
# * Hook into YEA - System Options
#--------------------------------------------------------------------------
if LCM::OPTIONS::AUTO_JUMP
  YEA::SYSTEM::COMMANDS.push(:lcm_options_auto_jump)
  YEA::SYSTEM::COMMAND_VOCAB[:lcm_options_auto_jump] = [
    'Auto-Jump', 'On', 'Off',
    'Automatically jump without pressing OK.'
  ]
end
# Game system
class Game_System
  alias lcm_options_initialize initialize
  attr_accessor :lcm_options_auto_jump
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize
    lcm_options_initialize
    @lcm_options_auto_jump = false if @lcm_options_auto_jump.nil?
  end
end
# YEA - System Options Window
class Window_SystemOptions < Window_Command
  alias lcm_options_draw_item draw_item
  alias lcm_options_draw_toggle draw_toggle
  alias lcm_options_cursor_change cursor_change
  alias lcm_options_change_toggle change_toggle
  alias lcm_options_make_command_list make_command_list
  #--------------------------------------------------------------------------
  # * Make command list
  #--------------------------------------------------------------------------
  def make_command_list
    lcm_options_make_command_list
    return unless LCM::OPTIONS::AUTO_JUMP
    add_command(YEA::SYSTEM::COMMAND_VOCAB[:lcm_options_auto_jump][0], :lcm_options_auto_jump)
    @help_descriptions[:lcm_options_auto_jump] = YEA::SYSTEM::COMMAND_VOCAB[:lcm_options_auto_jump][3]
    old_index = @list.size - 1
    new_index = [old_index - 4, 0].max
    @list.insert(new_index, @list.delete_at(old_index))
  end
  #--------------------------------------------------------------------------
  # Draw the option
  #--------------------------------------------------------------------------
  def draw_item(index)
    case @list[index][:symbol]
    when :lcm_options_auto_jump
      reset_font_settings
      rect = item_rect(index)
      contents.clear_rect(rect)
      draw_toggle(item_rect_for_text(index), index, @list[index][:symbol])
    else
      lcm_options_draw_item(index)
      nil
    end
  end
  #--------------------------------------------------------------------------
  # Draw the toggle text
  #--------------------------------------------------------------------------
  def draw_toggle(rect, index, symbol)
    name = @list[index][:name]
    dx = contents.width / 2
    case symbol
    when :lcm_options_auto_jump
      enabled = !$game_system.lcm_options_auto_jump
    else
      lcm_options_draw_toggle(rect, index, symbol)
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
    when :lcm_options_auto_jump
      change_toggle(direction)
    else
      lcm_options_cursor_change(direction)
      nil
    end
  end
  #--------------------------------------------------------------------------
  # Process the toggle
  #--------------------------------------------------------------------------
  def change_toggle(direction)
    value = direction == :left
    case current_symbol
    when :lcm_options_auto_jump
      current_case = $game_system.lcm_options_auto_jump
      $game_system.lcm_options_auto_jump = value
    else
      lcm_options_change_toggle(direction)
      return
    end
    Sound.play_cursor if value != current_case
    draw_item(index)
  end
end
end