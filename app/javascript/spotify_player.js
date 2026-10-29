// Spotify の埋め込みプレーヤーを iFrame API で操作する
// https://developer.spotify.com/documentation/embeds/references/iframe-api
//
// - 曲を替えるときは controller.loadEntity を使わず、controller を作り直す。
//   loadEntity は iframe の src を書き換えるため、ブラウザの履歴に積まれて戻るボタンが効かなくなる（Firefox で確認）
// - playback_update の e.data は { isPaused, isBuffering, position, duration, playingURI }（position / duration はミリ秒）。
//   未ログインでは 30 秒ほどのプレビューになり、最後まで再生すると position === duration のまま isPaused: false で届き続ける
// - play() は自動再生の制限でブラウザによっては効かない（Safari など）。その場合は読み込んだまま止まっている
const API_URL = "https://open.spotify.com/embed/iframe-api/v1"
const API_TIMEOUT_MS = 10000
const PLAYER_HEIGHT = 80
// 終わりとみなす残り時間
const END_TOLERANCE_MS = 500
// 実際に再生が進んだとみなす位置。ヘッドレスのブラウザなどでは再生せずに position === duration が届くことがあり、
// 進んだのを見ていない曲は終わったことにしない（読み込んだ直後に次の曲へ飛ばないように）
const PROGRESS_MARGIN_MS = 1500

let apiPromise = null

function loadIframeApi() {
  if (apiPromise) return apiPromise

  apiPromise = new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("Spotify iFrame API の読み込みがタイムアウトしました")), API_TIMEOUT_MS)
    window.onSpotifyIframeApiReady = (api) => {
      clearTimeout(timer)
      resolve(api)
    }
    const script = document.createElement("script")
    script.src = API_URL
    script.async = true
    script.onerror = () => {
      clearTimeout(timer)
      reject(new Error("Spotify iFrame API を読み込めませんでした"))
    }
    document.head.appendChild(script)
  })
  // 失敗したら次の表示で読み直す
  apiPromise.catch(() => { apiPromise = null })
  return apiPromise
}

// theme=0 は落ち着いた暗い配色（埋め込みの生成画面の「Dark」と同じ）。URL のクエリは埋め込みにそのまま渡る
const trackUrl = (trackId) => `https://open.spotify.com/track/${encodeURIComponent(trackId)}?theme=0`
const embedUrl = (trackId) => `https://open.spotify.com/embed/track/${encodeURIComponent(trackId)}?theme=0`

export default class EmbedPlayer {
  constructor(slot, { onEnded } = {}) {
    this.slot = slot
    this.onEnded = onEnded
    this.controller = null
    this.trackId = null
    this.requestId = 0
    this.destroyed = false
    this.resetPlayback()
  }

  // 再生中か（一時停止中・未再生・最後まで再生した後は false）
  get isPlaying() {
    return this.playing
  }

  // 曲を読み込む。play: true なら読み込めたら再生する。素早く続けて呼ばれたら最後の 1 曲だけを読み込む
  async load(trackId, { play = false } = {}) {
    if (!trackId || this.destroyed) return

    const requestId = ++this.requestId
    this.trackId = trackId
    this.resetPlayback()

    let api
    try {
      api = await loadIframeApi()
    } catch {
      if (requestId === this.requestId && !this.destroyed) this.showPlainEmbed(trackId)
      return
    }
    if (requestId !== this.requestId || this.destroyed) return

    this.controller?.destroy()
    this.controller = null
    const element = document.createElement("div")
    this.slot.replaceChildren(element)

    api.createController(element, { url: trackUrl(trackId), width: "100%", height: PLAYER_HEIGHT }, (controller) => {
      if (requestId !== this.requestId || this.destroyed) {
        controller.destroy()
        return
      }
      this.controller = controller
      this.slot.querySelector("iframe")?.setAttribute("title", "Spotify プレーヤー")
      controller.addListener("ready", () => {
        if (play && requestId === this.requestId) controller.play()
      })
      controller.addListener("playback_update", (event) => this.onPlaybackUpdate(requestId, event?.data))
    })
  }

  destroy() {
    this.destroyed = true
    this.requestId++
    this.controller?.destroy()
    this.controller = null
  }

  resetPlayback() {
    this.playing = false
    this.progressed = false
    this.ended = false
  }

  onPlaybackUpdate(requestId, data) {
    if (requestId !== this.requestId || !data) return

    const { isPaused, position, duration } = data
    const atEnd = duration > 0 && position >= duration - END_TOLERANCE_MS
    this.playing = !isPaused && !atEnd
    if (!isPaused && position > 0 && position < duration - PROGRESS_MARGIN_MS) this.progressed = true

    if (atEnd && this.progressed && !this.ended) {
      this.ended = true
      this.onEnded?.()
    }
  }

  // iFrame API が使えないときは、操作できない普通の埋め込みを出す
  showPlainEmbed(trackId) {
    const iframe = document.createElement("iframe")
    iframe.src = embedUrl(trackId)
    iframe.title = "Spotify プレーヤー"
    iframe.width = "100%"
    iframe.height = String(PLAYER_HEIGHT)
    iframe.loading = "lazy"
    iframe.allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
    iframe.className = "block w-full border-0"
    this.slot.replaceChildren(iframe)
  }
}
