class Friend < ApplicationRecord
  belongs_to :user_a, class_name: "User", optional: true
  belongs_to :user_b, class_name: "User", optional: true
end
