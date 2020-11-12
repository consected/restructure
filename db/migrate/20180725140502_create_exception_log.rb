class CreateExceptionLog < ActiveRecord::Migration
  def change
    create_table :exception_logs do |t|
      t.string :message
      t.string :main
      t.string :backtrace
      t.belongs_to :user, index: true, foreign_key: true
      t.belongs_to :admin, index: true, foreign_key: true
      t.timestamp :notified_at
      t.timestamps null: false

    end
  end
end
