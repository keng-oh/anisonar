require 'rails_helper'

RSpec.describe "Admin::DataChecks", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  def create_run_with_findings
    run = create(:data_check_run)
    song = create(:song, title: "青春コンプレックス (TV size)")
    result = run.results.create!(check_key: DataChecks::NoisySongTitles::KEY, findings_count: 1)
    result.findings.create!(record: song, label: song.title, detail: "含まれる文字列: TV size")
    run.results.create!(check_key: DataChecks::CrawlFailures::KEY, error_message: "boom")
    [ run, song ]
  end

  context "管理者" do
    before { sign_in admin }

    it "index は点検が未実行でも 200" do
      get admin_data_checks_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("まだ点検を実行していません")
    end

    it "index に項目ごとの件数と、失敗した項目の表示が出る" do
      create_run_with_findings

      get admin_data_checks_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("曲名の混入物", "クロールの失敗", "失敗")
    end

    it "show に対象と理由、編集画面へのリンクが出る" do
      _run, song = create_run_with_findings

      get admin_data_check_path(DataChecks::NoisySongTitles::KEY)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("青春コンプレックス (TV size)", "含まれる文字列: TV size", edit_admin_song_path(song))
    end

    it "show はレコードが消えていてもリンクなしで表示できる" do
      _run, song = create_run_with_findings
      song.destroy!

      get admin_data_check_path(DataChecks::NoisySongTitles::KEY)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("青春コンプレックス (TV size)")
    end

    it "失敗した項目の show は失敗と分かる" do
      create_run_with_findings

      get admin_data_check_path(DataChecks::CrawlFailures::KEY)

      expect(response.body).to include("点検は失敗しました")
    end

    it "未知の key の show は 404" do
      get admin_data_check_path("unknown")

      expect(response).to have_http_status(:not_found)
    end

    it "create でジョブを積む" do
      expect { post admin_data_checks_path }.to have_enqueued_job(DataCheckJob).with("manual")
      expect(response).to redirect_to(admin_data_checks_path)
    end

    it "実行中なら create はジョブを積まない" do
      create(:data_check_run, status: :running, started_at: 5.minutes.ago, finished_at: nil)

      expect { post admin_data_checks_path }.not_to have_enqueued_job(DataCheckJob)
      expect(flash[:notice]).to include("実行中")
    end
  end

  context "一般ユーザー" do
    before { sign_in create(:user) }

    it "index はリダイレクトされる" do
      get admin_data_checks_path

      expect(response).to redirect_to(root_path)
    end

    it "create はジョブを積まない" do
      expect { post admin_data_checks_path }.not_to have_enqueued_job(DataCheckJob)
    end
  end

  it "未ログインはログインへリダイレクトされる" do
    get admin_data_checks_path

    expect(response).to have_http_status(:redirect)
  end
end
