# CI ではアセットをビルドしないので、レイアウトが読み込む application.css / application.js が無い。
# リクエストスペックは画面の中身を確かめるもので、アセットは対象外なので、タグの出力だけ止める
RSpec.configure do |config|
  config.before(type: :request) do
    allow_any_instance_of(ActionView::Base).to receive(:stylesheet_link_tag).and_return("")
    allow_any_instance_of(ActionView::Base).to receive(:javascript_include_tag).and_return("")
  end
end
