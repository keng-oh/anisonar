module Api
  module Admin
    class AnimeSeriesController < BaseController
      def index
        series = AnimeSeries.order(:name)
        if params[:q].present?
          q = "%#{AnimeSeries.sanitize_sql_like(params[:q])}%"
          series = series.where("name ILIKE :q OR name_en ILIKE :q", q:)
        end
        render json: series.limit(20).map { |s|
          { id: s.id, name: s.name, name_en: s.name_en }
        }
      end
    end
  end
end
