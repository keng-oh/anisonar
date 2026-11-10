module Admin
  # 一覧から編集画面を開いたとき、保存・キャンセルの後に開く前の一覧（条件とページ）へ戻す。
  # 戻り先は return_to パラメータで運び、その一覧のパスに一致するときだけ使う（オープンリダイレクト対策）
  module ReturnToList
    extend ActiveSupport::Concern

    included do
      helper_method :return_to_list_path
    end

    private

      def return_to_list_path(default_path)
        raw = params[:return_to].to_s
        return default_path if raw.blank?

        uri = URI.parse(raw)
        return default_path if uri.host || uri.scheme || uri.path != default_path

        uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
      rescue URI::InvalidURIError
        default_path
      end
  end
end
