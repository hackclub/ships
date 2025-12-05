class YswsProjectEntry < ApplicationRecord
  has_encrypted :map_lat
  has_encrypted :map_long
end
