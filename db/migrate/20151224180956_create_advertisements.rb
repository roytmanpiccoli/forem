class CreateAdvertisements < ActiveRecord::Migration[4.2]
  def change
    create_table :advertisements do |t|
      t.string :name
      t.text :body_html
      t.string :kind
      t.boolean :active, default: true

      t.timestamps null: false
    end
  end
end
