# 管理画面のレイアウトは application.css / application.js を参照する。これらはビルド成果物（git 管理外）で、
# CI や素の環境には無く、request spec で画面を描画すると Propshaft::MissingAssetError になる。
# 無いときだけ空のファイルを置いて描画できるようにする（本物のビルドがあればそれを使う）
RSpec.configure do |config|
  config.before(:suite) do
    builds = Rails.root.join("app/assets/builds")
    FileUtils.mkdir_p(builds)
    %w[application.css application.js].each do |name|
      path = builds.join(name)
      FileUtils.touch(path) unless path.exist?
    end
  end
end
