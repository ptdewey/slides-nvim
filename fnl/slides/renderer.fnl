(local ns (vim.api.nvim_create_namespace :nvim_slides))

(local bullet-chars ["●" "○" "■"])

(var highlights-defined false)

(fn define-highlights []
  (when (not highlights-defined)
    (set highlights-defined true)
    (vim.api.nvim_set_hl 0 :SlidesH1 {:link :Title})
    (vim.api.nvim_set_hl 0 :SlidesH2 {:link "@markup.heading"})
    (vim.api.nvim_set_hl 0 :SlidesBold {:bold true})
    (vim.api.nvim_set_hl 0 :SlidesBullet {:link "@markup.list"})
    (vim.api.nvim_set_hl 0 :SlidesBody {})))

(fn render-title-slide [slide win-width win-height display-lines line-meta]
  (let [content []
        content-meta []]
    (each [_ ln (ipairs slide.lines)]
      (if (= ln.type :h1)
          (let [pad (math.max 0
                              (math.floor (/ (- win-width
                                                (vim.fn.strdisplaywidth ln.text))
                                             2)))]
            (table.insert content (.. (string.rep " " pad) ln.text))
            (table.insert content-meta
                          {:hl :SlidesH1 :bold ln.bold :offset pad}))
          (= ln.type :blank)
          (do
            (table.insert content "")
            (table.insert content-meta {:hl nil :bold [] :offset 0}))
          ;; other lines on title slide
          (let [pad (math.max 0
                              (math.floor (/ (- win-width
                                                (vim.fn.strdisplaywidth ln.text))
                                             2)))]
            (table.insert content (.. (string.rep " " pad) ln.text))
            (table.insert content-meta
                          {:hl :SlidesBody :bold ln.bold :offset pad}))))
    ;; vertical centering
    (let [top-pad (math.max 0
                            (math.floor (/ (- win-height (length content)) 2)))]
      (for [_ 1 top-pad]
        (table.insert display-lines "")
        (table.insert line-meta {:hl nil :bold [] :offset 0}))
      (each [i ln (ipairs content)]
        (table.insert display-lines ln)
        (table.insert line-meta (. content-meta i))))))

(fn render-content-slide [slide win-width left-margin display-lines line-meta]
  ;; top padding
  (for [_ 1 3]
    (table.insert display-lines "")
    (table.insert line-meta {:hl nil :bold [] :offset 0}))
  (each [_ ln (ipairs slide.lines)]
    (if (= ln.type :h2)
        (do
          (table.insert display-lines (.. (string.rep " " left-margin) ln.text))
          (table.insert line-meta
                        {:hl :SlidesH2 :bold ln.bold :offset left-margin})
          ;; blank line after header
          (table.insert display-lines "")
          (table.insert line-meta {:hl nil :bold [] :offset 0}))
        (= ln.type :bullet)
        (let [char (. bullet-chars
                      (math.min (+ ln.indent 1) (length bullet-chars)))
              indent-str (string.rep "  " ln.indent)
              prefix (.. (string.rep " " left-margin) indent-str char " ")]
          (table.insert display-lines (.. prefix ln.text))
          (table.insert line-meta
                        {:hl :SlidesBody
                         :bold ln.bold
                         :offset (length prefix)
                         :bullet_col (+ left-margin (length indent-str))
                         :bullet_len (length char)}))
        (= ln.type :blank)
        (do
          (table.insert display-lines "")
          (table.insert line-meta {:hl nil :bold [] :offset 0}))
        ;; plain text
        (do
          (table.insert display-lines (.. (string.rep " " left-margin) ln.text))
          (table.insert line-meta
                        {:hl :SlidesBody :bold ln.bold :offset left-margin})))))

(fn apply-extmarks [buf display-lines line-meta]
  (vim.api.nvim_buf_clear_namespace buf ns 0 -1)
  (each [i meta (ipairs line-meta)]
    (let [row (- i 1)
          line-text (. display-lines i)]
      ;; full-line highlight for headings
      (when (or (= meta.hl :SlidesH1) (= meta.hl :SlidesH2))
        (vim.api.nvim_buf_add_highlight buf ns meta.hl row 0 -1))
      ;; bullet character highlight
      (when meta.bullet_col
        (vim.api.nvim_buf_add_highlight buf ns :SlidesBullet row
                                        meta.bullet_col
                                        (+ meta.bullet_col meta.bullet_len)))
      ;; bold spans
      (each [_ b (ipairs (or meta.bold []))]
        (let [col-start (+ (or meta.offset 0) b.start)
              col-end (+ (or meta.offset 0) b.end)]
          (when (<= col-end (length line-text))
            (vim.api.nvim_buf_add_highlight buf ns :SlidesBold row col-start
                                            col-end)))))))

(fn render [slide state]
  "Render a single slide into the given buffer/window."
  (define-highlights)
  (let [buf state.buf
        win state.win
        win-width (vim.api.nvim_win_get_width win)
        win-height (vim.api.nvim_win_get_height win)
        left-margin (math.floor (* win-width 0.12))
        display-lines []
        line-meta []]
    (if (= slide.type :title)
        (render-title-slide slide win-width win-height display-lines line-meta)
        (render-content-slide slide win-width left-margin display-lines
                              line-meta))
    ;; pad to fill window height
    (while (< (length display-lines) win-height)
      (table.insert display-lines "")
      (table.insert line-meta {:hl nil :bold [] :offset 0}))
    ;; slide counter in bottom-right
    (let [counter (string.format " [%d/%d] " (+ state.current 1) state.total)
          last-idx (length display-lines)
          counter-pad (math.max 0 (- win-width (length counter)))]
      (tset display-lines last-idx (.. (string.rep " " counter-pad) counter)))
    ;; write to buffer
    (vim.api.nvim_set_option_value :modifiable true {: buf})
    (vim.api.nvim_buf_set_lines buf 0 -1 false display-lines)
    (vim.api.nvim_set_option_value :modifiable false {: buf})
    ;; apply highlights
    (apply-extmarks buf display-lines line-meta)))

{: render}
