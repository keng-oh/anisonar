class RemoveLegacyCrawlRequestFields < ActiveRecord::Migration[8.1]
  # 旧ワークフロー（Dify 連携・クロールと抽出を分けた途中経過）の名残を消す。
  # 今の n8n ワークフローは pending → crawling → done / failed しか使わない。
  # 途中経過のまま止まっている依頼は、今のワークフローでやり直せるよう pending に戻す
  def up
    say_with_time "crawled / extracting の依頼を pending に戻す" do
      execute("UPDATE crawl_requests SET status = 'pending' WHERE status IN ('crawled', 'extracting')")
    end
    remove_column :crawl_requests, :dify_document_id
  end

  def down
    add_column :crawl_requests, :dify_document_id, :string
  end
end
