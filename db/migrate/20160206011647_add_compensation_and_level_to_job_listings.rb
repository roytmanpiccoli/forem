class AddCompensationAndLevelToJobListings < ActiveRecord::Migration[4.2]
  def change
    add_column :job_listings, :compensation_description, :string
    add_column :job_listings, :experience_level, :string
  end
end
