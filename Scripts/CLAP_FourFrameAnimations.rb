($imported ||= {})["CLAP_FourFrameAnimation"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_FourFrameAnimation
# ---------------------------------------------------------------------------- #
# Simply put an "&" in front of the character spritesheet you wish to have
# 4 frames.
# EG: "&Player" for a big sheet, "&$Player" for a small sheet.
#
# Be wary that this makes the first frame it's default, rather than the
# middle/second frame like it usually is.
# Best used in conjuction with CLAP_MovementPoses.
# ---------------------------------------------------------------------------- #

class Game_CharacterBase
  attr_accessor :four_frames
  #--------------------------------------------------------------------------
  # * Initialize public members
  #--------------------------------------------------------------------------
  alias four_direction_init_public_members init_public_members
  def init_public_members
    four_direction_init_public_members
    @four_frames = false
  end
  #--------------------------------------------------------------------------
  # * Set character graphic
  #--------------------------------------------------------------------------
  alias four_direction_set_graphic set_graphic
  def set_graphic(character_name, character_index)
    four_direction_set_graphic(character_name, character_index)
    if @four_frames
      @original_pattern = 0
    end
  end
  
end
# ---------------------------------------------------------------------------- #
class Sprite_Character < Sprite_Base
  alias four_frame_update_src_rect update_src_rect
  alias four_frame_set_character_bitmap set_character_bitmap
  #--------------------------------------------------------------------------
  # * Set Character Bitmap
  #--------------------------------------------------------------------------
  def set_character_bitmap
    if $imported["CLAP_MovementPoses"]
      @character.movement_poses = false
    end
    @character.four_frames = false
    sign = @character_name[/^[\&\$]./]
    if sign && sign.include?('&')
      self.bitmap = Cache.character(@character_name)
      @character.four_frames = true
      if sign.include?('$')
        @cw = bitmap.width / 4
        @ch = bitmap.height / 4
      else
        @cw = bitmap.width / 16
        @ch = bitmap.height / 8
        if $imported["CLAP_MovementPoses"]
          @character.movement_poses = true
        end
      end
      self.ox = @cw / 2
      self.oy = @ch
    else
      four_frame_set_character_bitmap
    end
  end
  #--------------------------------------------------------------------------
  # * Update sprite's frame
  #--------------------------------------------------------------------------
  def update_src_rect
    if @character.four_frames
      index = @character.character_index
      pattern = @character.pattern < 4 ? @character.pattern : 0
      sx = (index % 4 * 4 + pattern) * @cw
      sy = (index / 4 * 4 + (@character.direction - 2) / 2) * @ch
      self.src_rect.set(sx, sy, @cw, @ch)
    else
      four_frame_update_src_rect
    end
  end
end

class Window_Base
  alias four_frame_draw_character draw_character
  #--------------------------------------------------------------------------
  # * Set Character Bitmap
  #--------------------------------------------------------------------------
  def draw_character(character_name, character_index, x, y)
    return unless character_name
    bitmap = Cache.character(character_name)
    sign = character_name[/^[\&\$]./]
    if sign && sign.include?('&') && sign.include?('$')
      cw = bitmap.width / 4
      ch = bitmap.height / 4
    elsif sign && sign.include?('&')
      cw = bitmap.width / 16
      ch = bitmap.height / 8
    else
      four_frame_draw_character
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    contents.blt(x - cw / 2, y - ch, bitmap, src_rect)
  end
end
