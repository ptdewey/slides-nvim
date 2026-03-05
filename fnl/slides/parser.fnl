(fn parse-bold [text]
  "Parse **bold** spans from text. Returns (cleaned-text, bold-ranges)."
  (local ranges [])
  (local result [])
  (var pos 1)
  (var byte-offset 0)
  (while (<= pos (length text))
    (let [(s e) (text:find "%*%*(.-)%*%*" pos)]
      (if (not s)
          (do
            (table.insert result (text:sub pos))
            (lua :break))
          (do
            ;; text before the bold marker
            (let [before (text:sub pos (- s 1))]
              (table.insert result before)
              (set byte-offset (+ byte-offset (length before))))
            ;; bold content (without ** markers)
            (let [content (text:sub (+ s 2) (- e 2))]
              (table.insert ranges
                            {:start byte-offset
                             :end (+ byte-offset (length content))})
              (table.insert result content)
              (set byte-offset (+ byte-offset (length content))))
            (set pos (+ e 1))))))
  (values (table.concat result) ranges))

(fn flush [current-lines slides]
  "Flush accumulated lines into a new slide."
  (when (> (length current-lines) 0)
    (var slide-type :content)
    (local parsed [])
    (each [_ raw (ipairs current-lines)]
      (if ;; heading 1
          (raw:match "^#%s+")
          (let [text (raw:gsub "^#%s+" "")
                (clean bolds) (parse-bold text)]
            (set slide-type :title)
            (table.insert parsed {:type :h1 :text clean :indent 0 :bold bolds}))
          ;; heading 2
          (raw:match "^##%s+")
          (let [text (raw:gsub "^##%s+" "")
                (clean bolds) (parse-bold text)]
            (table.insert parsed {:type :h2 :text clean :indent 0 :bold bolds}))
          ;; bullet
          (raw:match "^%s*[%-%*]%s+")
          (let [(spaces marker-and-text) (raw:match "^(%s*)[%-%*]%s+(.*)")
                indent (math.floor (/ (length spaces) 2))
                (clean bolds) (parse-bold marker-and-text)]
            (table.insert parsed {:type :bullet
                                  :text clean
                                  : indent
                                  :bold bolds}))
          ;; blank line
          (raw:match "^%s*$")
          (table.insert parsed {:type :blank :text "" :indent 0 :bold []})
          ;; plain text
          (let [(clean bolds) (parse-bold raw)]
            (table.insert parsed {:type :text
                                  :text clean
                                  :indent 0
                                  :bold bolds}))))
    (table.insert slides {:type slide-type :lines parsed})))

(fn parse [lines]
  "Parse a list of lines into a table of slides."
  (let [slides []
        current-lines []]
    ;; Skip everything before the first level-1 heading (e.g. YAML frontmatter)
    (var start 1)
    (each [i line (ipairs lines) &until (not= start 1)]
      (when (line:match "^#%s+")
        (set start i)))
    ;; Parse slides separated by ---
    (for [i start (length lines)]
      (let [line (. lines i)]
        (if (line:match "^%-%-%-+%s*$")
            (do
              (flush current-lines slides)
              ;; clear current-lines in place
              (for [j (length current-lines) 1 -1]
                (table.remove current-lines j)))
            (table.insert current-lines line))))
    (flush current-lines slides)
    slides))

{: parse}
