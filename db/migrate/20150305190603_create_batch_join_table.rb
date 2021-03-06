class CreateBatchJoinTable < ActiveRecord::Migration
  def change
    create_join_table :batches, :items do |t|
      # t.index [:batch_id, :item_id]
      t.index [:item_id, :batch_id], unique: true
    end
  end
end
