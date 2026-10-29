// トップページの棚（カバーフロー）。横スクロール（スワイプ・トラックパッド）は CSS の scroll-snap に任せ、
// 中央に最も近い曲を「選択中」にする。マウスホイールの縦回転と ← / → キー、前後ボタンでも 1 曲ずつ送る
//
// 選択中の曲は Spotify の埋め込みプレーヤーで聴ける。再生中に曲を替えると次の曲も再生し、
// 最後まで再生したら次の曲へ送って再生する（年を切り替えたときは棚ごと作り直すので再生しない）
import EmbedPlayer from "./spotify_player"

const LOAD_MORE_THRESHOLD = 6
const WHEEL_STEP_INTERVAL_MS = 450
// 素早く送っている間にプレーヤーを何度も読み直さないよう、止まってから差し替える
const PLAYER_SWITCH_DELAY_MS = 400

export default function recordShelf() {
  // プレーヤーは Alpine のリアクティブな状態に入れない（外部の iframe を持つので Proxy で包ませない）
  let player = null

  return {
    active: 0,
    // ボタンやキーで送った先。スムーズスクロールの途中で続けて押されても 1 曲ずつ進めるために持つ
    target: null,
    current: {},
    nextUrl: null,
    frame: null,
    wheelLockedUntil: 0,
    playerTimer: null,
    // 最後まで再生して次の曲へ送ったとき、その曲を再生する
    playNext: false,
    loadingPromise: null,

    init() {
      this.nextUrl = this.$el.dataset.nextUrl || null
      player = new EmbedPlayer(this.$refs.playerSlot, { onEnded: () => this.advanceAfterEnd() })
      player.load(this.$refs.playerSlot.dataset.trackId)
      this.updateActive()
    },

    items() {
      return this.$refs.track.querySelectorAll("[data-shelf-item]")
    },

    onScroll() {
      if (this.frame) return
      this.frame = requestAnimationFrame(() => {
        this.frame = null
        this.updateActive()
      })
    },

    updateActive() {
      const track = this.$refs.track
      const center = track.scrollLeft + track.clientWidth / 2
      let best = 0
      let bestDistance = Infinity
      this.items().forEach((item, index) => {
        const distance = Math.abs(item.offsetLeft + item.offsetWidth / 2 - center)
        if (distance < bestDistance) {
          best = index
          bestDistance = distance
        }
      })
      if (best === this.target) this.target = null
      this.setActive(best)
    },

    // スワイプなどで利用者が自分でスクロールし始めたら、送り先は捨てる
    cancelTarget() {
      this.target = null
    },

    setActive(index) {
      const items = this.items()
      if (items.length === 0) return

      items.forEach((item, i) => {
        item.dataset.active = String(i === index)
        if (i === index) item.setAttribute("aria-current", "true")
        else item.removeAttribute("aria-current")
      })
      this.active = index
      const { title, artist, work, workUrl, typeLabel, typeClass, spotifyUrl, trackId } = items[index].dataset
      this.current = { title, artist, work, workUrl, typeLabel, typeClass, spotifyUrl }
      this.schedulePlayer(trackId)

      if (index >= items.length - LOAD_MORE_THRESHOLD) this.loadMore()
    },

    scrollToIndex(index) {
      const items = this.items()
      if (index < 0 || index >= items.length) return

      this.target = index
      const item = items[index]
      const track = this.$refs.track
      track.scrollTo({
        left: item.offsetLeft + item.offsetWidth / 2 - track.clientWidth / 2,
        behavior: this.reducedMotion() ? "auto" : "smooth",
      })
    },

    centerItem(button) {
      this.scrollToIndex([...this.items()].indexOf(button.closest("[data-shelf-item]")))
    },

    atEnd() {
      return !this.nextUrl && (this.target ?? this.active) >= this.items().length - 1
    },

    prev() {
      this.scrollToIndex((this.target ?? this.active) - 1)
    },

    next() {
      this.scrollToIndex((this.target ?? this.active) + 1)
    },

    onKeydown(event) {
      if (event.target.closest("input, textarea, select, [contenteditable]")) return
      if (event.key === "ArrowLeft") this.prev()
      else if (event.key === "ArrowRight") this.next()
      else return
      event.preventDefault()
    },

    // 横方向のホイール（トラックパッド・Shift+ホイール）はそのままスクロールさせる。
    // 縦回転だけを 1 曲送りに変える（小刻みな scrollBy は snap で元に戻されるため）
    onWheel(event) {
      if (Math.abs(event.deltaY) <= Math.abs(event.deltaX)) return

      event.preventDefault()
      const now = Date.now()
      if (now < this.wheelLockedUntil) return
      this.wheelLockedUntil = now + WHEEL_STEP_INTERVAL_MS
      if (event.deltaY > 0) this.next()
      else this.prev()
    },

    schedulePlayer(trackId) {
      clearTimeout(this.playerTimer)
      if (!trackId || trackId === player.trackId) return

      this.playerTimer = setTimeout(() => {
        const play = player.isPlaying || this.playNext
        this.playNext = false
        player.load(trackId, { play })
      }, PLAYER_SWITCH_DELAY_MS)
    },

    // 最後まで再生したら次の曲へ送る。読み込んだ分の最後なら続きを読み込んでから送り、本当に次が無ければ止まる
    async advanceAfterEnd() {
      const index = this.target ?? this.active
      if (index >= this.items().length - 1) await this.loadMore()
      if (index >= this.items().length - 1) return

      this.playNext = true
      this.scrollToIndex(index + 1)
    },

    destroy() {
      clearTimeout(this.playerTimer)
      player?.destroy()
    },

    // 読み込み中に呼ばれたら、その読み込みが終わるのを待つ
    loadMore() {
      if (!this.nextUrl) return Promise.resolve()

      this.loadingPromise ||= this.fetchMore().finally(() => { this.loadingPromise = null })
      return this.loadingPromise
    },

    async fetchMore() {
      try {
        const response = await fetch(this.nextUrl, { headers: { Accept: "text/html" } })
        if (!response.ok) return

        const template = document.createElement("template")
        template.innerHTML = await response.text()
        const marker = template.content.querySelector("[data-shelf-next]")
        this.nextUrl = marker ? marker.dataset.shelfNext : null
        marker?.remove()
        this.$refs.end.before(template.content)
      } catch {
        // 通信に失敗しても棚はそのまま使える。次に端へ近づいたときに読み直す
      }
    },

    reducedMotion() {
      return window.matchMedia("(prefers-reduced-motion: reduce)").matches
    },
  }
}
