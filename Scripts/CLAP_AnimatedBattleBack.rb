($imported ||= {})["CLAP_AnimatedBattleback"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_AnimatedBattleback
# ---------------------------------------------------------------------------- #
# Adds a bit of animation to the blurry background.
# ---------------------------------------------------------------------------- #

class Spriteset_Battle  
  #--------------------------------------------------------------------------
  # * Create Battle Background Bitmap from Processed Map Screen
  #--------------------------------------------------------------------------
  def create_blurry_background_bitmap
    source = SceneManager.background_bitmap
    bitmap = Bitmap.new(720, 540)
    bitmap.stretch_blt(bitmap.rect, source, source.rect)
    bitmap.radial_blur(120, 16)
    return bitmap
  end
  #--------------------------------------------------------------------------
  # * Create the animated battle background layer
  #--------------------------------------------------------------------------
  def create_battleback2
    @back2_sprite = Sprite.new(@viewport1)
    @back2_sprite.bitmap = copy_bitmap(@back1_sprite.bitmap)
    @back2_sprite.z = 1
    @back2_sprite.opacity = 64
    @back2_sprite.wave_amp = 32
    @back2_sprite.wave_length = Graphics.height / 3
    @back2_sprite.wave_speed = 128
    center_sprite(@back2_sprite)
  end
  
  #--------------------------------------------------------------------------
  # * Copy the background bitmap
  #-------------------------------------------------------------------------- 
  def copy_bitmap(original)
    return nil unless original && !original.disposed? 
    
    copy = Bitmap.new(original.width, original.height)
    copy.blt(0, 0, original, original.rect)
  
    return copy
  end
end