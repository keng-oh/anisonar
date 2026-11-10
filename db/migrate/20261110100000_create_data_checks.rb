class CreateDataChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :data_check_runs do |t|
      t.string :trigger, null: false
      t.string :status, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.text :error_message
      t.timestamps
    end
    add_index :data_check_runs, :started_at

    create_table :data_check_results do |t|
      t.references :data_check_run, null: false, foreign_key: true
      t.string :check_key, null: false
      t.integer :findings_count, null: false, default: 0
      t.text :error_message
      t.timestamps
    end
    add_index :data_check_results, [ :data_check_run_id, :check_key ], unique: true

    create_table :data_check_findings do |t|
      t.references :data_check_result, null: false, foreign_key: true
      # レコードが後で消えても一覧が壊れないよう、外部キー制約は付けない
      t.string :record_type
      t.bigint :record_id
      t.string :label, null: false
      t.text :detail
      t.timestamps
    end
    add_index :data_check_findings, [ :record_type, :record_id ]
  end
end
