(local parser (require :slides.parser))
(local renderer (require :slides.renderer))

(local state {:buf nil :win nil :slides nil :current 0 :original-buf nil})

(fn render-current []
  (when (and state.slides state.buf (vim.api.nvim_buf_is_valid state.buf))
    (renderer.render (. state.slides (+ state.current 1))
                     {:buf state.buf
                      :win state.win
                      :current state.current
                      :total (length state.slides)})))

(fn next []
  (when state.slides
    (when (< state.current (- (length state.slides) 1))
      (set state.current (+ state.current 1))
      (render-current))))

(fn prev []
  (when state.slides
    (when (> state.current 0)
      (set state.current (- state.current 1))
      (render-current))))

(fn stop []
  (when (and state.win (vim.api.nvim_win_is_valid state.win))
    (vim.api.nvim_win_close state.win true))
  (when (and state.buf (vim.api.nvim_buf_is_valid state.buf))
    (vim.api.nvim_buf_delete state.buf {:force true}))
  (set state.buf nil)
  (set state.win nil)
  (set state.slides nil)
  (set state.current 0)
  (set state.original-buf nil))

(fn start []
  ;; stop any existing presentation
  (when state.win (stop))
  (set state.original-buf (vim.api.nvim_get_current_buf))
  (let [lines (vim.api.nvim_buf_get_lines state.original-buf 0 -1 false)
        slides (parser.parse lines)]
    (set state.slides slides)
    (when (= (length slides) 0)
      (vim.notify "slides: no slides found" vim.log.levels.WARN)
      (lua :return))
    ;; create buffer
    (set state.buf (vim.api.nvim_create_buf false true))
    (vim.api.nvim_set_option_value :buftype :nofile {:buf state.buf})
    (vim.api.nvim_set_option_value :filetype :slides {:buf state.buf})
    ;; create fullscreen floating window
    (let [width vim.o.columns
          height (- vim.o.lines 1)]
      (set state.win
           (vim.api.nvim_open_win state.buf true
                                  {:relative :editor
                                   : width
                                   : height
                                   :row 0
                                   :col 0
                                   :style :minimal
                                   :border :none})))
    ;; window options
    (vim.api.nvim_set_option_value :cursorline false {:win state.win})
    (vim.api.nvim_set_option_value :number false {:win state.win})
    (vim.api.nvim_set_option_value :relativenumber false {:win state.win})
    (vim.api.nvim_set_option_value :signcolumn :no {:win state.win})
    (vim.api.nvim_set_option_value :wrap false {:win state.win})
    ;; key mappings
    (let [map-opts {:buffer state.buf :silent true}]
      (vim.keymap.set :n :n next map-opts)
      (vim.keymap.set :n :l next map-opts)
      (vim.keymap.set :n :<Right> next map-opts)
      (vim.keymap.set :n :<Space> next map-opts)
      (vim.keymap.set :n :p prev map-opts)
      (vim.keymap.set :n :h prev map-opts)
      (vim.keymap.set :n :<Left> prev map-opts)
      (vim.keymap.set :n :q stop map-opts)
      (vim.keymap.set :n :<Esc> stop map-opts))
    ;; render first slide
    (set state.current 0)
    (render-current)))

(fn setup [opts])
;; reserved for future user config

{: setup : start : stop : next : prev}
