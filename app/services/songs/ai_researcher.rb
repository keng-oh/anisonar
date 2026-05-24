module Songs
  # アニメ1作品について Claude + web_search で楽曲情報を検索する。
  #
  # 返り値:
  #   {
  #     items: [
  #       { title:, artist_name:, song_type:, source_url: },
  #       ...
  #     ],
  #     raw_response: ...  # デバッグ用
  #   }
  class AiResearcher
    class Error < StandardError; end

    SUBMIT_TOOL_NAME = "submit_anime_songs".freeze

    SUBMIT_TOOL = {
      name: SUBMIT_TOOL_NAME,
      description: "Submit the final list of songs found for the given anime. Call this exactly once with all songs you found.",
      input_schema: {
        type: "object",
        properties: {
          songs: {
            type: "array",
            items: {
              type: "object",
              properties: {
                title:       { type: "string", description: "正式な楽曲タイトル。'(TV size)' '〜 アニメver' 等の付加情報は除く。" },
                artist_name: { type: "string", description: "アーティスト名。公式表記を優先。" },
                song_type:   { type: "string", enum: %w[op ed insert image], description: "op=オープニング, ed=エンディング, insert=挿入歌, image=イメージソング" },
                source_url:  { type: "string", description: "情報源の URL。任意。" }
              },
              required: %w[title artist_name song_type]
            }
          }
        },
        required: %w[songs]
      }
    }.freeze

    WEB_SEARCH_TOOL = {
      type: "web_search_20250305",
      name: "web_search",
      max_uses: 2
    }.freeze

    SYSTEM_PROMPT = <<~PROMPT.freeze
      あなたはアニメ楽曲データベースの調査アシスタントです。
      ユーザーが指定したアニメ作品について、Web 検索を行い、OP・ED・挿入歌・イメージソングを正確に列挙してください。

      ルール:
      - ユーザーが提示する「優先調査 URL」(Wikipedia / 公式サイト) があれば、必ず最初にそこを調査する
      - 公式情報源（Wikipedia、公式サイト、レコード会社、Apple Music 等）を優先する
      - 楽曲タイトルは正式表記。「(TV size)」「〜 アニメver」「short ver.」等は付けない
      - アーティスト名は公式表記。複数アーティストのコラボ表記もそのまま残す
      - OP/ED が複数ある場合は全て列挙する
      - 挿入歌・イメージソングは確実な情報のみ。推測は除外
      - 該当作品の楽曲のみ。シリーズ別作の楽曲は混ぜない
      - 最後に必ず submit_anime_songs ツールで結果を返す
    PROMPT

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(anime:, client: Ai::ClaudeClient.new)
      @anime  = anime
      @client = client
    end

    def call
      response = @client.create_message(
        system:   SYSTEM_PROMPT,
        messages: [ { role: "user", content: user_prompt } ],
        tools:    [ WEB_SEARCH_TOOL, SUBMIT_TOOL ],
        max_tokens: 8000
      )

      items = extract_submitted_songs(response)
      raise Error, "Claude did not call #{SUBMIT_TOOL_NAME}" if items.nil?

      { items: items, raw_response: response }
    end

    private

      def user_prompt
        parts = []
        parts << "以下のアニメ作品の楽曲を調査してください。"
        parts << ""
        parts << "タイトル: #{@anime.title}"
        parts << "英題: #{@anime.title_en}" if @anime.title_en.present?
        parts << "シーズン: #{@anime.season}" if @anime.season.present?
        parts << "シリーズ: #{@anime.anime_series.name}" if @anime.anime_series.present?
        parts << "メディア: #{@anime.media_type}"

        priority_urls = [ @anime.wikipedia_url, @anime.official_site_url ].compact_blank
        if priority_urls.any?
          parts << ""
          parts << "優先調査 URL（必ず最初に確認すること）:"
          priority_urls.each { |url| parts << "- #{url}" }
        end

        parts.join("\n")
      end

      def extract_submitted_songs(response)
        content = Array(response["content"])
        tool_use = content.find { |c| c["type"] == "tool_use" && c["name"] == SUBMIT_TOOL_NAME }
        return nil unless tool_use

        Array(tool_use.dig("input", "songs")).map do |s|
          {
            title:       s["title"].to_s.strip,
            artist_name: s["artist_name"].to_s.strip,
            song_type:   s["song_type"],
            source_url:  s["source_url"]
          }
        end
      end
  end
end
