require "minitest/autorun"
require_relative "../../lib/bff/interpreter"

class TestInterpreter < Minitest::Test
  include BFF::Ops

  def test_empty_tape
    assert_equal "", BFF::Interpreter.run("")
  end

  def test_noop_instruction
    # 'X' is not a defined op, so it should be a NOOP. Tape remains unchanged.
    # Program is "X\x00", initial tape is [Xord, 0]
    assert_equal "X\x00", BFF::Interpreter.run("X\x00")
  end

  def test_incr0_then_plus_modifies_program_byte
    # Program: ">+\x00" (INCR0, PLUS, NULL). Tape length 3.
    # > (INCR0): head_0 = 0 + (1 % 3) = 1. pc=1.
    # + (PLUS): tape[head_0] (tape[1], which is PLUS) becomes (PLUS + 1) & 0xFF.
    #            PLUS (43) + 1 = 44 (ASCII for ','). pc=2.
    # \x00 (NULL): NOOP. pc=3.
    # Expected tape: [INCR0, 44, 0] -> ">\x2C\x00"
    assert_equal ">\x2C\x00", BFF::Interpreter.run(">+\x00")
  end

  def test_decr0_then_plus_modifies_program_byte_with_wrap
    # Program: "<+\x00" (DECR0, PLUS, NULL). Tape length 3.
    # < (DECR0): head_0 = 0 - (1 % 3) = -1. (points to tape[2], the NULL byte). pc=1.
    # + (PLUS): tape[head_0] (tape[2]) becomes (0 + 1) & 0xFF = 1. pc=2.
    # \x00 (now \x01 at tape[2]): NOOP. pc=3.
    # Expected tape: [DECR0, PLUS, 1] -> "<\x2B\x01"
    assert_equal "<\x2B\x01", BFF::Interpreter.run("<+\x00")
  end

  def test_head_movement_on_tape_length_one
    # Program: ">+" (INCR0, PLUS). Tape length 2.
    # This test name is slightly misleading as ">+" is length 2.
    # For tape length 1, e.g. program ">":
    # > (INCR0): head_0 = 0 + (1 % 1) = 0. head_0 remains 0. pc=1.
    # To observe this, let's use ">+" where program is just these two ops.
    # Program: ">+" (INCR0, PLUS). Tape: [INCR0, PLUS]
    # >: If length was 1 (e.g. program ">"), head_0 = 0 + (1%1) = 0.
    #    If program is ">+", length is 2. head_0 = 0 + (1%2) = 1.
    # +: tape[head_0] (tape[1], which is PLUS) becomes (PLUS + 1) & 0xFF = 44.
    # Expected: [INCR0, 44] -> ">\x2C"
    assert_equal ">\x2C", BFF::Interpreter.run(">+")

    # True tape length 1 test: Program: "+"
    # +: tape[0] becomes (PLUS + 1) & 0xFF = 44.
    # Expected: "\x2C"
    assert_equal "\x2C", BFF::Interpreter.run("+")
  end

  # --- Head_1 Movement Tests ---

  def test_incr1_then_copy01 # tape[h1] = tape[h0]
    # Program: "}.AX" (INCR1, COPY01, 'A', 'X'). Tape length 4.
    # Initial: head_0=0, head_1=0. tape[0]=INCR1, tape[1]=COPY01, tape[2]='A', tape[3]='X'
    # } (INCR1): head_1 = 0 + (1 % 4) = 1. pc=1.
    # . (COPY01): tape[head_1] (tape[1], which is COPY01) = tape[head_0] (tape[0], which is INCR1).
    #             So tape[1] becomes INCR1 (125). pc=2.
    # A (ASCII 65): NOOP. pc=3.
    # X (ASCII 88): NOOP. pc=4.
    # Expected: [INCR1, INCR1, 'A', 'X'] -> "}}\x41\x58"
    assert_equal "}}\x41\x58", BFF::Interpreter.run("}.AX") # Use '.' for COPY01
  end

  def test_decr1_then_copy10_with_wrap # tape[h0] = tape[h1]
    # Program: "{,AX" (DECR1, COPY10, 'A', 'X'). Tape length 4.
    # Initial: head_0=0, head_1=0. tape[0]=DECR1, tape[1]=COPY10, tape[2]='A', tape[3]='X'
    # { (DECR1): head_1 = 0 - (1 % 4) = -1 (points to tape[3], 'X'). pc=1.
    # , (COPY10): tape[head_0] (tape[0], which is DECR1) = tape[head_1] (tape[3], which is 'X').
    #             So tape[0] becomes 'X' (88). pc=2.
    # A: NOOP. pc=3.
    # X: NOOP. pc=4.
    # Expected: ['X', COPY10, 'A', 'X'] -> "\x58,\x41\x58"
    tape = [DECR1.chr, COPY10.chr, "A", "X"].join
    expected = ["X", COPY10.chr, "A", "X"].join
    assert_equal expected, BFF::Interpreter.run(tape)
  end

  # --- Cell Value Operation Tests (using DECR0 to target a data cell) ---

  def test_plus_on_data_cell
    # Program: "<+\x00" (DECR0, PLUS, initial_value_0). Tape length 3.
    # < (DECR0): head_0 = -1 (points to tape[2], which is 0). pc=1.
    # + (PLUS): tape[head_0] (tape[2]) becomes (0 + 1) & 0xFF = 1. pc=2.
    # \x00 (tape[2] is now 1): NOOP. pc=3.
    # Expected: [DECR0, PLUS, 1] -> "<\x2B\x01"
    assert_equal "<\x2B\x01", BFF::Interpreter.run("<+\x00") # This is same as test_decr0_then_plus_modifies_program_byte_with_wrap
  end

  def test_plus_overflow_on_data_cell
    # Program: "<+\xFF" (DECR0, PLUS, initial_value_255). Tape length 3.
    # < (DECR0): head_0 = -1 (points to tape[2], which is 255). pc=1.
    # + (PLUS): tape[head_0] (tape[2]) becomes (255 + 1) & 0xFF = 0. pc=2.
    # \xFF (tape[2] is now 0): NOOP. pc=3.
    # Expected: [DECR0, PLUS, 0] -> "<\x2B\x00"
    assert_equal "<\x2B\x00", BFF::Interpreter.run("<+\xFF")
  end

  def test_minus_on_data_cell
    # Program: "<-\x01" (DECR0, MINUS, initial_value_1). Tape length 3.
    # < (DECR0): head_0 = -1 (points to tape[2], which is 1). pc=1.
    # - (MINUS): tape[head_0] (tape[2]) becomes (1 - 1) & 0xFF = 0. pc=2.
    # \x01 (tape[2] is now 0): NOOP. pc=3.
    # Expected: [DECR0, MINUS, 0] -> "<\x2D\x00"
    assert_equal "<\x2D\x00", BFF::Interpreter.run("<-\x01")
  end

  def test_minus_underflow_on_data_cell
    # Program: "<-\x00" (DECR0, MINUS, initial_value_0). Tape length 3.
    # < (DECR0): head_0 = -1 (points to tape[2], which is 0). pc=1.
    # - (MINUS): tape[head_0] (tape[2]) becomes (0 - 1) & 0xFF = 255. pc=2.
    # \x00 (tape[2] is now 255): NOOP. pc=3.
    # Expected: [DECR0, MINUS, 255] -> "<\x2D\xFF"
    assert_equal "<\x2D\xFF".bytes, BFF::Interpreter.run("<-\x00").bytes
  end

  # --- Loop Tests ---

  def test_loop_skip_if_val_at_head0_is_null
    # Program: "<[+]\x41\x00" (DECR0, '[', '+', ']', 'A', NULL). head_0 targets NULL at tape[5].
    # < (DECR0): head_0 = -1 (points to tape[5], which is NULL). pc=1.
    # [ (LOOP_START): tape[head_0] (tape[5]) is NULL. Skip loop.
    #                  PC scans: finds '+' at tape[2], then ']' at tape[3]. PC becomes 3.
    # After loop processing, pc increments to 4. ec increments for '['.
    # Next op is tape[4] ('A'). NOOP. pc=5.
    # Next op is tape[5] (NULL). NOOP. pc=6.
    # Expected: Tape unchanged. "<[+]\x41\x00"
    assert_equal "<[+]\x41\x00", BFF::Interpreter.run("<[+]\x41\x00")
  end

  def test_loop_executes_and_terminates # Based on count_down example
    # Program: "<[-]\xFF" (DECR0, '[', '-', ']', 255). head_0 targets 255 at tape[4].
    # < : head_0 = -1 (points to tape[4], value 255).
    # Loop runs 255 times, decrementing tape[4] each time until it's 0.
    # Finally, tape[4] is 0.
    # [ : tape[head_0] (tape[4]) is 0. Skip loop. PC becomes index of ']' (3).
    # Then pc increments. Next op is tape[4] (now 0). NOOP.
    # Expected: "<[-]\x00"
    assert_equal "<[-]\x00", BFF::Interpreter.run("<[-]\xFF")
  end

  def test_nested_loop_skip
    # Program: "<[[+]]\x00" (DECR0, '[', '[', '+', ']', ']', NULL). head_0 targets NULL at tape[6].
    # < : head_0 = -1 (points to tape[6], value NULL).
    # [ (outer): tape[head_0] is NULL. Skip. PC scans for matching ']' (the last one).
    #            Finds '[' at tape[2], '+' at tape[3], ']' at tape[4], ']' at tape[5]. PC becomes 5.
    # Then pc increments. Next op is tape[6] (NULL). NOOP.
    # Expected: "<[[+]]\x00" (tape unchanged)
    assert_equal "<[[+]]\x00", BFF::Interpreter.run("<[[+]]\x00")
  end

  # --- Execution Limit Test ---
  def test_execution_limit
    # Program: "<[+]\x01" (DECR0, '[', '+', ']', 1).
    # < : head_0 = -1 (points to tape[4], value 1). ec=1.
    # Loop: '[', '+', ']'. tape[4] increments.
    # The loop will execute, incrementing tape[4] from 1 up to 255, then to 0.
    # When tape[4] becomes 0:
    #   - The '+' operation makes tape[4] = 0.
    #   - The ']' operation is encountered. Since tape[head_0] (tape[4]) is 0, the loop does not jump back.
    #   - The program counter advances past ']'.
    # This process takes 1 (for '<') + 255 * (1 for '[', 1 for '+', 1 for ']') = 1 + 255 * 3 = 766 execution steps.
    # This is well below EXECUTION_LIMIT (8192).
    # The final value of tape[4] will be 0.
    # Expected: "<[+]\x00"
    assert_equal "<[+]\x00", BFF::Interpreter.run("<[+]\x01")
  end

  # --- Test from User Examples ---
  def test_add_five_example
    # Program: "<+++++\x00"
    # < : head_0 = -1 (points to tape[6], value \x00).
    # + (5 times): tape[6] becomes 5.
    # \x00 (tape[6] is now 5): NOOP.
    # Expected: "<+++++\x05"
    assert_equal "<+++++\x05", BFF::Interpreter.run("<+++++\x00")
  end
end
