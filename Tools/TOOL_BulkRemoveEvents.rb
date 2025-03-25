# Steps for this script
# 1. Install this into the game
# 2. Run the game
# 3. Exit the editor and re-open to make sure you don't save over the changes
# 4. Remove the script since we're done with it!
#
# CAUTION! Tools modify the data directly and they do NOT hesitate.
# Please back up your data folder in case something is changed that you were
# not anticipating!
#
# Set the map ID here! You can find it in the bottom right.
# Be sure to keep the 0's in place, so map 28 would be: 
# reference_map_file = "Data/Map028.rvdata2"
#
# The reference map contains all the events you would like to delete.
# This version has safety guards so events that have graphics are empty
# are not removed, provided you don't request to delete an empty event.
#
# For example, an event on the reference map that has Show Message "Hi!"
# would then be used and if any map has that event, it will be deleted.
#

reference_map_file = "Data/Map000.rvdata2" # Edit here!

reference_map = load_data(reference_map_file)

# Check if Map was found and loaded
if reference_map.is_a?(RPG::Map)
  reference_events = reference_map.events.values
else
  exit
end

# Helper function to validate if we match
def events_identical?(event1, event2)
# Check if there is the same amount of pages
  return false if event1.pages.length != event2.pages.length

# Loop through pages
  event1.pages.each_with_index do |page, index|
    ref_page = event2.pages[index]

# Check if both pages have the same number of commands
    return false if page.list.length != ref_page.list.length

# Loop through each command 
    page.list.each_with_index do |command, cmd_index|
      ref_command = ref_page.list[cmd_index]
# See if it matches exactly, right down to the parameters
      return false if command.code != ref_command.code
    end
  end

  true
end

# The main part where we loop through every map
Dir.glob("Data/Map*.rvdata2").each do |file|
  next if file == reference_map_file # We ignore our reference map

  map = load_data(file)

# Check to see if we loaded a map properly
  if map.is_a?(RPG::Map) && map.events.is_a?(Hash)
    any_removed = false

# Loop through every event
    map.events.keys.each do |key|
      event = map.events[key]
      reference_events.each do |reference_event|
# We see if the event matches with any event on the reference map
        if events_identical?(event, reference_event)
# Check and ignore if there is a graphic
          has_graphic = event.pages.any? { |page| !page.graphic.character_name.empty? || page.graphic.tile_id != 0 }
          if has_graphic
            next
          end
# No graphic was found so we remove it and it matches
          map.events.delete(key)
          any_removed = true
          break
        end
      end
    end

# Save the map when we have deleted at least one thing
    if any_removed
      File.open(file, "wb") { |f| Marshal.dump(map, f) }
    end
  end
end
