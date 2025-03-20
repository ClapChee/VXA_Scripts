# Changes the position of damage popups
# Needs to be below Yanfly Engine Ace - Ace Battle Engine

unless !$imported["YEA-BattleEngine"]
class Sprite_Popup < Sprite_Base
  alias sprite_popup_patch_create_popup_bitmap create_popup_bitmap
  def create_popup_bitmap
    sprite_popup_patch_create_popup_bitmap
    
    # ----------------------------------------------------------
    
    # Popup offset for party member portraits
    popup_multiplier_pm = 1.075 
    
    # Popup offset for enemies
    popup_multiplier_en = 1.25 
    
    # ----------------------------------------------------------
    
    self.y = @battler.screen_y - @battler.sprite.oy * popup_multiplier_en
    self.y -= (@battler.screen_y * popup_multiplier_pm) - @battler.screen_y if @battler.actor?
    self.y -= SceneManager.scene.spriteset.viewport1.oy
  end
end
end