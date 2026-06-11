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

      【重要】調査結果に関わらず、必ず最後に submit_anime_songs ツールを呼ぶこと。
      楽曲が見つからなかった場合・確認できなかった場合は songs を空配列 [] にして呼ぶこと。
      テキストで回答せず、必ずツールで返すこと。
    PROMPT

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(anime:, client: Ai::ClaudeClient.new, firecrawl: Ai::FirecrawlClient.new)
      @anime     = anime
      @client    = client
      @firecrawl = firecrawl
    end

    def call
      response = @client.create_message(
        system:   SYSTEM_PROMPT,
        messages: [ { role: "user", content: user_prompt } ],
        tools:    [ WEB_SEARCH_TOOL, SUBMIT_TOOL ],
        max_tokens: 8000
      )

      items = extract_submitted_songs(response)

      if items.nil?
        # ツールを呼ばずテキストで返した場合（楽曲情報なし・調査不能なケース）
        Rails.logger.warn "[AiResearcher] #{SUBMIT_TOOL_NAME} not called for anime_id=#{@anime.id} " \
                          "title=#{@anime.title} response=#{text_response(response)}"
        items = []
      end

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

        scraped = scrape_priority_urls
        if scraped.any?
          parts << ""
          parts << "## 事前取得済みのページ内容（これを最優先で参照すること）"
          scraped.each do |url, markdown|
            parts << ""
            parts << "### #{url}"
            parts << markdown
          end
        else
          # Firecrawl が使えない場合は URL ヒントのみ渡す（従来の挙動）
          priority_urls = [ @anime.wikipedia_url, @anime.official_site_url ].compact_blank
          if priority_urls.any?
            parts << ""
            parts << "優先調査 URL（必ず最初に確認すること）:"
            priority_urls.each { |url| parts << "- #{url}" }
          end
        end

        parts.join("\n")
      end

      # wikipedia_url / official_site_url を Firecrawl でスクレイプする。
      # 失敗した URL はスキップして警告ログだけ残す。
      # @return [Hash<String, String>] { url => markdown }
      def scrape_priority_urls
        urls = [ @anime.wikipedia_url, @anime.official_site_url ].compact_blank
        return {} if urls.empty?

        urls.each_with_object({}) do |url, hash|
          markdown = @firecrawl.scrape(url)
          hash[url] = markdown if markdown.present?
        rescue Ai::FirecrawlClient::Error => e
          Rails.logger.warn "[AiResearcher] Firecrawl スキップ url=#{url} reason=#{e.message}"
        end
      end

      # submit_anime_songs ツール呼び出しから楽曲リストを取り出す。
      # ツールが呼ばれなかった場合は nil を返す（呼び出し元でフォールバック処理）。
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

      # Claude がテキストで返した場合の内容をログ用に取り出す。
      def text_response(response)
        Array(response["content"])
          .select { |c| c["type"] == "text" }
          .map { |c| c["text"] }
          .join("\n")
          .truncate(200)
      end
  end
end
