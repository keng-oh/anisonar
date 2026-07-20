require "rails_helper"

RSpec.describe "ActiveRecord i18n", type: :model do
  describe "attribute humanization" do
    it "shows Artist name in Japanese on validation errors" do
      artist = Artist.new

      I18n.with_locale(:ja) do
        artist.validate
      end

      expect(artist.errors.full_messages).to include("アーティスト名を入力してください")
    end
  end
end
