class RemoveAiNoteFromSongs < ActiveRecord::Migration[8.1]
  # AI取り込みが notes に付けていた "[AI]" マーカーは廃止したため、既存データからも除去する
  def up
    execute "UPDATE songs SET notes = NULL WHERE notes = '[AI]'"
  end

  def down
    # マーカーの復元は不要
  end
end
