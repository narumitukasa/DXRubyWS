# coding: utf-8

module WS
  # テキストボックス
  class WSTextBox < WSControl
    attr_accessor :text

    def initialize(tx, ty, sx, sy)
      super(tx, ty, sx, sy)
      self.image = Image.new(sx, sy, C_WHITE)

      self.image.line(0,0,@width-1,0,[80,80,80])
                .line(0,0,0,@height-1,[80,80,80])
                .line(1,1,@width-1,1,[120,120,120])
                .line(1,1,1,@height-1,[120,120,120])
                .line(@width-2,1,@width-2,@height-2,[200,200,200])
                .line(1,@height-2,@width-2,@height-2,[200,200,200])
                .line(@width-1,0,@width-1,@height-1,[240,240,240])
                .line(0,@height-1,@width-1,@height-1,[240,240,240])
      @text = ""
      @cursor_count = 0 # カーソル点滅用カウント
      @cursor_pos = 0   # カーソル位置
      @selected_range_first = nil # 範囲選択始点
      @selected_range_last = nil  # 範囲選択終点
      @font = Font.new(12)
      @focusable = true # フォーカスをあてれるかどうか

      # 特殊キーのハンドラ
      add_key_handler(K_BACKSPACE) do
        if @selected_range_first
          min = [@selected_range_first, @selected_range_last].min
          max = [@selected_range_first, @selected_range_last].max-1
          @text[min..max] = ""
          @selected_range_first = nil
          @cursor_pos = min
        else
          if @cursor_pos > 0
            @text[@cursor_pos-1] = ""
            @cursor_pos -= 1
          end
        end
      end

      add_key_handler(K_DELETE) do
        if @selected_range_first
          min = [@selected_range_first, @selected_range_last].min
          max = [@selected_range_first, @selected_range_last].max-1
          @text[min..max] = ""
          @selected_range_first = nil
          @cursor_pos = min
        else
          @text[@cursor_pos] = ""
        end
      end

      add_key_handler(K_LEFT) do
        if @cursor_pos > 0
          if Input.key_down?(K_LSHIFT) or Input.key_down?(K_RSHIFT)
            if @selected_range_first
              @selected_range_last = @cursor_pos-1
            else
              @selected_range_first = @cursor_pos
              @selected_range_last = @cursor_pos-1
            end
            @selected_range_first = nil if @selected_range_first == @selected_range_last
          else
            @selected_range_first = nil
          end
          @cursor_pos -= 1
        end
      end

      add_key_handler(K_RIGHT) do
        if @cursor_pos < @text.length
          if Input.key_down?(K_LSHIFT) or Input.key_down?(K_RSHIFT)
            if @selected_range_first
              @selected_range_last = @cursor_pos+1
            else
              @selected_range_first = @cursor_pos
              @selected_range_last = @cursor_pos+1
            end
            @selected_range_first = nil if @selected_range_first == @selected_range_last
          else
            @selected_range_first = nil
            @selected_range_last = nil
          end
          @cursor_pos += 1
        end
      end

      add_key_handler(K_HOME) do
        if Input.key_down?(K_LSHIFT) or Input.key_down?(K_RSHIFT)
          if @selected_range_first
            @selected_range_last = 0
          else
            @selected_range_first = @cursor_pos
            @selected_range_last = 0
          end
          @selected_range_first = nil if @selected_range_first == @selected_range_last
        else
          @selected_range_first = nil
        end
        @cursor_pos = 0
      end

      add_key_handler(K_END) do
        if Input.key_down?(K_LSHIFT) or Input.key_down?(K_RSHIFT)
          if @selected_range_first
            @selected_range_last = @text.length
          else
            @selected_range_first = @cursor_pos
            @selected_range_last = @text.length
          end
          @selected_range_first = nil if @selected_range_first == @selected_range_last
        else
          @selected_range_first = nil
        end
        @cursor_pos = @text.length
      end

      add_key_handler(K_A) do
        if Input.key_down?(K_LCONTROL) or Input.key_down?(K_RCONTROL)
          @selected_range_first = 0
          @selected_range_last = @text.length
        end
      end
    end

    # キーが押されたらカーソル点滅カウントを初期化
    def on_key_push(key)
      @cursor_count = 0
      super
    end

    # 文字が入力されたらカーソル位置に挿入
    def on_string(str)
      if @selected_range_first
        min = [@selected_range_first, @selected_range_last].min
        max = [@selected_range_first, @selected_range_last].max-1
        @text[min..max] = str
        @cursor_pos = min + str.length - 1
      else
        @text[@cursor_pos, 0] = str
      end
      @selected_range_first = nil
      @cursor_pos += str.length
    end

    # カーソル点滅と位置設定処理
    def update
      if @active
        @cursor_count += 1
        tx, ty = self.get_global_vertex
        Input::IME.set_cursor(tx + @font.get_width(@text[0, @cursor_pos]) + 4, ty + 4)
      end
    end

    # フォーカス取得
    def on_enter
      Input::IME.enable = true
      Input::IME.set_font(@font)
      @selected_range_first = 0
      @selected_range_last = @text.length
      @cursor_pos = @text.length
      @cursor_count = 0
      super
    end

    # フォーカス喪失
    def on_leave
      Input::IME.enable = false
      super
    end

    def draw
      super

      # 選択範囲表示
      if @selected_range_first and @active
        tx1 = self.x + @font.get_width(@text[0, [@selected_range_first, @selected_range_last].min]) + 4
        tx2 = self.x + @font.get_width(@text[0, [@selected_range_first, @selected_range_last].max]) + 4
        (0..(@font.size+1)).each do |ty|
          self.target.draw_line(tx1, self.y + ty + 3, tx2, self.y + ty + 3, [200, 200, 255])
        end
      end

      # 文字列表示
      self.target.draw_font(self.x + 4, self.y + 4, @text, @font, :color=>C_BLACK)

      # カーソル表示
      if @active and (@cursor_count / 30) % 2 == 0
        tx = self.x + @font.get_width(@text[0, @cursor_pos]) + 4
        self.target.draw_line(tx, self.y + 3, tx, self.y + 2 + @font.size, C_BLACK)
      end
    end

    # クリックされたらフォーカスをあてる
    # このタイミングではテキストボックスが乗っているウィンドウはアクティブになっている
    def on_mouse_push(tx, ty)
      WS.focused_object.window_focus = self
      super
    end
  end
end