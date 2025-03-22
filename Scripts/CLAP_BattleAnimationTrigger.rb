($imported ||= {})["CLAP_BattleAnimationTrigger"] = true
# ---------------------------------------------------------------------------- #
# INSTRUCTIONS for CLAP_BattleAnimationTrigger
# ---------------------------------------------------------------------------- #
# Set the sound effect you'd like to trigger the skill's ability.
# This means dealing damage, restoring stats and other things of that nature.
# Put this below the Input Combo Skills script.
# ---------------------------------------------------------------------------- #
module CLAP_BattleAnimationTrigger
# ---------------------------------------------------------------------------- #

  # Name of the SE that triggers skills. (putting a "-" before will bring it to
  # the top of the sound list)
  TRIGGER_SE_NAME = "- [ Effect Trigger ]"
  
  # By default, using a flash color along side the trigger will act as a 
  # multiplier if you wish to have different attack damages in the same skill.
  # Since you can't input decimals as color values, they will be divided 
  # by the damage multiplier divider. Damage behaves normally if all are zero.
  # Leaving this at 100 let's you assume what you input is a percentage like so:
  # (Red = 158 / 100 = 1.58x damage, Red = 35 / 100 = 0.35x damage)
  DAMAGE_MULTIPLIER_DIVIDER = 100
  
# ---------------------------------------------------------------------------- #
end

class Sprite_Base < Sprite
  alias battle_animation_trigger_animation_process_timing animation_process_timing
  alias battle_animation_trigger_initialize initialize
  #--------------------------------------------------------------------------
  # * SE and Flash Timing Processing
  #--------------------------------------------------------------------------
  def animation_process_timing(timing)
    return unless @animation
    timing.se.play
    return if $game_temp.battle_animation_triggered
    case timing.flash_scope
    when 1
      self.flash(timing.flash_color, timing.flash_duration * @ani_rate)
    when 2
      if viewport && !@ani_duplicated
        viewport.flash(timing.flash_color, timing.flash_duration * @ani_rate)
      end
    when 3
      self.flash(nil, timing.flash_duration * @ani_rate)
    end
    if $game_party.in_battle
      scene = SceneManager.scene
      frame_index = @animation.frame_max
      frame_index -= (@ani_duration + @ani_rate - 1) / @ani_rate
      if timing.se && timing.frame == frame_index
        return unless timing.se.name == CLAP_BattleAnimationTrigger::TRIGGER_SE_NAME
        user = scene.subject
        $game_temp.battle_effect_multiplier = 0
        if timing.flash_scope > 0
          $game_temp.battle_effect_multiplier += timing.flash_color.red
          $game_temp.battle_effect_multiplier += timing.flash_color.green
          $game_temp.battle_effect_multiplier += timing.flash_color.blue
        else
          $game_temp.battle_effect_multiplier = CLAP_BattleAnimationTrigger::DAMAGE_MULTIPLIER_DIVIDER
        end
        action = scene.subject.current_action
        user_action = scene.subject.current_action
        item = user_action.item
        scene.custom_execute_action
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Update Animation
  #--------------------------------------------------------------------------
  alias battle_animation_trigger_update_animation update_animation
  def update_animation
    return unless animation?
    battle_animation_trigger_update_animation
    if @ani_duration % @ani_rate != 0
      $game_temp.battle_animation_triggered = false
    end
  end
end 

class Scene_Battle < Scene_Base
  alias battle_animation_trigger_start start # Start
  alias battle_animation_trigger_process_action process_action_end # Process Action
  attr_accessor :targets
  attr_accessor :spriteset
  attr_accessor :custom_animations
  attr_accessor :triggered
  
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  def start
    @targets = []
    @triggered = false
    @using_combo_skills = false
    battle_animation_trigger_start
  end
  #--------------------------------------------------------------------------
  # * Custom execute action
  #--------------------------------------------------------------------------
  def custom_execute_action(target = nil)
    return if !@targets
    @triggered = true
    $game_temp.battle_animation_triggered = true
    item = @subject.current_action.item
    for target in @targets
      target.sprite_effect_type = :whiten
      invoke_item(target, item)
    end
    refresh_status
  end
  #--------------------------------------------------------------------------
  # * Use Skill/Item
  #--------------------------------------------------------------------------
  def custom_use_item
    item = @subject.current_action.item
    @log_window.clear
    @log_window.display_use_item(@subject, item)
    @subject.use_item(item)
    @targets = @subject.current_action.make_targets.compact
    show_animation(@targets, item.animation_id)
    wait_for_animation
    @targets.each {|target| item.repeats.times { invoke_item(target, item) } } unless @triggered
    @triggered = false
  end
  #--------------------------------------------------------------------------
  # * Invoke Skill/Item
  #--------------------------------------------------------------------------
  def invoke_item(target, item)
    if rand < target.item_cnt(@subject, item)
      invoke_counter_attack(target, item)
    elsif rand < target.item_mrf(@subject, item)
      invoke_magic_reflection(target, item)
    elsif @spriteset.animation? && $game_temp.battle_animation_triggered
      apply_item_effects(apply_substitute(target, item), item)
    elsif !@spriteset.animation? && !$game_temp.battle_animation_triggered
      apply_item_effects(apply_substitute(target, item), item)
    elsif !$game_temp.battle_animation_triggered
      apply_item_effects(apply_substitute(target, item), item)
    end
    @subject.last_target_index = target.index
  end

  #--------------------------------------------------------------------------
  # * Processing at End of Action
  #--------------------------------------------------------------------------
  def process_action_end
    @triggered = false
    $game_temp.battle_animation_triggered = false
    battle_animation_trigger_process_action
  end
  
  #--------------------------------------------------------------------------
  # * Patches if using YEA - Input Combo Skills 
  #--------------------------------------------------------------------------  
  if $imported["YEA-InputComboSkills"]
    alias battle_animation_trigger_break_input_combo break_input_combo?
  end
  
  def use_item
    return custom_use_item if !$imported["YEA-InputComboSkills"]
    @subject.enable_input_combo(true)
    item = @subject.current_action.item
    combo_skill_list_appear(true, item)
    start_input_combo_skill_counter(item)
    custom_use_item
    while !break_input_combo?(item)
      update_basic
      update_combo_skill_queue
    end
    combo_skill_list_appear(false, item)
    @subject.enable_input_combo(false)
  end
  
  def update_combo_skill_queue
    return if !@combo_skill_queue || @combo_skill_queue.empty?
    action = @combo_skill_queue.shift
    return unless @subject.usable?(action)
    @subject.current_action.set_input_combo_skill(action.id)
    target_dead = false
    for target in SceneManager.scene.targets
      target_dead = true if target.hp == 0
    end
    SceneManager.scene.targets = @subject.current_action.make_targets.compact if target_dead
    custom_use_item
  end
  
  def break_input_combo?(item)
    return false if @spriteset.animation?
    battle_animation_trigger_break_input_combo(item)
  end
end
  
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # * Wait
  #--------------------------------------------------------------------------
  def wait
    return if SceneManager.scene.triggered
    @num_wait += 1
    @method_wait.call(message_speed) if @method_wait
  end
  #--------------------------------------------------------------------------
  # * Wait for effect
  #--------------------------------------------------------------------------
  def wait_for_effect
    return if SceneManager.scene.triggered
    @num_wait += 1
    @method_wait.call(message_speed) if @method_wait
  end
end

class Game_Battler < Game_BattlerBase 
  #--------------------------------------------------------------------------
  # * Calculate Damage
  #--------------------------------------------------------------------------
  def make_damage_value(user, item)
    value = item.damage.eval(user, self, $game_variables)
    value *= item_element_rate(user, item)
    value *= pdr if item.physical?
    value *= mdr if item.magical?
    value *= rec if item.damage.recover?
    value = apply_critical(value) if @result.critical
    value = apply_variance(value, item.damage.variance)
    value *= $game_temp.battle_effect_multiplier / CLAP_BattleAnimationTrigger::DAMAGE_MULTIPLIER_DIVIDER
    value = apply_guard(value)
    @result.make_damage(value.to_i, item)
  end
end

class Game_Temp
  alias battle_animation_trigger_initialize initialize
  attr_accessor :battle_animation_triggered
  attr_accessor :battle_effect_multiplier
  
  def initialize
    battle_animation_trigger_initialize
    @battle_animation_triggered = false
    @battle_effect_multiplier = CLAP_BattleAnimationTrigger::DAMAGE_MULTIPLIER_DIVIDER
  end
end