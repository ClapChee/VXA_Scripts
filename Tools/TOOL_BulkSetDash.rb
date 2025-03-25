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

Dir.glob("Data/Map*.rvdata2").each do |file|
map = load_data(file)
if map.is_a?(RPG::Map)
# ---------------------------------------------------------------------------- #
	
map.disable_dashing = false # Set this to true or false yourself
	  
# ---------------------------------------------------------------------------- #
File.open(file, "wb") { |f| Marshal.dump(map, f) }
end
end