($imported ||= {})["CLAP_MovementPoses"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_MovementPoses
# ---------------------------------------------------------------------------- #
# Set the character indexs below. This uses the bigger sheet format, so don't
# start the sprite file with "$" and make sure it's 12x8 frames large, or
# 16x8 if using CLAP_FourFrameAnimation
# ---------------------------------------------------------------------------- #

module CLAP_MovementPoses
#------------------------------------------------------------------------------#

  # Character index when standing still
    IDLE_INDEX = 0 
  # Character index when moving still
    MOVE_INDEX = 1 
  # Character index when dashing still
    DASH_INDEX = 2 
  # Character index when dashing still
    JUMP_INDEX = 5 
  # Character index when jumping and dashing
    DASH_JUMP_INDEX = 6 
  
  # The following require CLAP_MovementSystem
  # -----------------------------------------#
  # Character index when you take a hard landing
    FALL_INDEX = 4 
  # Character index when climbing a rope
    ROPE_INDEX = 3 
    
#------------------------------------------------------------------------------#
end

class Game_CharacterBase
  alias movement_poses_update_animation update_animation
  alias movement_poses_init_public_members init_public_members
  
  attr_accessor :movement_poses

  #--------------------------------------------------------------------------
  # * Initialize public members
  #--------------------------------------------------------------------------
  def init_public_members
    movement_poses_init_public_members
    @movement_poses = false
    @dash_jump_lock = false
    @on_rope = false
  end
  #--------------------------------------------------------------------------
  # * Update animation
  #--------------------------------------------------------------------------
  def update_animation
    movement_poses_update_animation
    swap_character_index
  end
  #--------------------------------------------------------------------------
  # * Swap out character index
  #--------------------------------------------------------------------------
  def swap_character_index
    if @movement_poses == true
      if jumping? && @dash_jump_lock
        @character_index = CLAP_MovementPoses::DASH_JUMP_INDEX
      elsif jumping?
        @character_index = CLAP_MovementPoses::JUMP_INDEX
      elsif moving? && dash? && !@on_rope
        @character_index = CLAP_MovementPoses::DASH_INDEX
      elsif moving? && !@on_rope
        @character_index = CLAP_MovementPoses::MOVE_INDEX
      elsif !@on_rope
        @character_index = CLAP_MovementPoses::IDLE_INDEX
      end
      if $imported["CLAP_MovementSystem"]
        if terrain_tag == CLAP_MovementSystem::ROPE_TERRAIN_TAG
          @on_rope = true
          @character_index = CLAP_MovementPoses::ROPE_INDEX
        else
          y_dir = @direction == 2 ? (@real_y - 0.99).ceil : (@real_y + 0.99).floor
          if y_dir == @y
            @on_rope = false
          end
        end
      end
    end
    if !jumping?
      @dash_jump_lock = dash?
    end
  end
end

class Sprite_Character < Sprite_Base
  alias movement_poses_set_character_bitmap set_character_bitmap
  #--------------------------------------------------------------------------
  # * Scan for "&" to trigger movement poses
  #--------------------------------------------------------------------------
  def set_character_bitmap
    sign = @character_name[/^[\&\$]./]
    if sign && !sign.include?('$') && sign.include?('&') && !$imported["CLAP_FourFrameAnimation"]
      @character.movement_poses = true
    else
      movement_poses_set_character_bitmap
    end
  end
  
end
