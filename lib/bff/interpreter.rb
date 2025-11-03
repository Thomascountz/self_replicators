require_relative "ops"

module BFF
  class Interpreter
    include Ops

    EXECUTION_LIMIT = 2**13

    def self.run(tape)
      new(tape).run
    end

    def initialize(tape)
      @tape = tape.bytes

      @program_counter = 0
      @head_0 = 0
      @head_1 = 0

      @execution_count = 0
    end

    def run
      while @program_counter < @tape.length && @execution_count < EXECUTION_LIMIT
        case @tape[@program_counter]
        when DECR0
          @head_0 -= (1 % @tape.length)
        when INCR0
          @head_0 += (1 % @tape.length)
        when DECR1
          @head_1 -= (1 % @tape.length)
        when INCR1
          @head_1 += (1 % @tape.length)
        when MINUS
          @tape[@head_0] = (@tape[@head_0] - 1) & 0xFF
        when PLUS
          @tape[@head_0] = (@tape[@head_0] + 1) & 0xFF
        when COPY01
          @tape[@head_1] = @tape[@head_0]
        when COPY10
          @tape[@head_0] = @tape[@head_1]
        when LOOP_START
          if @tape[@head_0] == NULL
            loop_depth = 1
            while loop_depth > 0 && @program_counter < @tape.length - 1
              @program_counter += 1
              loop_depth += 1 if @tape[@program_counter] == LOOP_START
              loop_depth -= 1 if @tape[@program_counter] == LOOP_END
            end
          end
        when LOOP_END
          if @tape[@head_0] != NULL
            loop_depth = 1
            while loop_depth > 0 && @program_counter > 1
              @program_counter -= 1
              loop_depth += 1 if @tape[@program_counter] == LOOP_END
              loop_depth -= 1 if @tape[@program_counter] == LOOP_START
            end
          end
        else
          # NOOP
        end

        @program_counter += 1
        @execution_count += 1
      end

      @tape.map(&:chr).join
    end
  end
end
