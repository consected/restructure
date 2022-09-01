# frozen_string_literal: true

require 'rails_helper'

# Generating conditions to pass to a regular _fpa_show_if.js calculation with
# bl = Redcap::DataDictionaries::BranchingLogic.new(condition_string)
# bl.generate_show_if
# NOTE: There are likely to be situations where this fails, if we have
# multiple and / or conditions in a line without parentheses to make the precedence clear

RSpec.describe 'Redcap::DataDictionaries::BranchingLogic', type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  describe 'simple conversion to show_if structure' do
    it 'converts variables to real field names' do
      test = <<~ENDSTR.strip
        [test_var] = "0"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% = "0"
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var']

      test = <<~ENDSTR.strip
        [yesno(1)] = "1"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% = "1"
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['yesno___1']

      test = <<~ENDSTR.strip
        [some_var]='sadf' and [yesno(1)] = "1"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%%='sadf' and %%VAR1%% = "1"
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      expect(@bl.vars).to eq ['some_var', 'yesno___1']

      expect(@bl.condition_string).to eq exp

      test = <<~ENDSTR.strip
        [test] <> "" and [test2] = "hello"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% <> "" and %%VAR1%% = "hello"
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      expect(@bl.vars).to eq ['test', 'test2']

      expect(@bl.condition_string).to eq exp
    end

    it 'tokenizes literals' do
      test = <<~ENDSTR.strip
        [yesno(1)] = "1"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% = %%LIT0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['yesno___1']
      expect(@bl.literals).to eq ['1']
      expect(@bl.numbers).to eq []

      test = <<~ENDSTR.strip
        [test] <> "" and [test2] = "hello"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% <> %%LIT0%% and %%VAR1%% = %%LIT1%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test', 'test2']
      expect(@bl.literals).to eq ['', 'hello']
      expect(@bl.numbers).to eq []

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> 'some "value"')
      ENDSTR

      exp = <<~ENDSTR.strip
        (%%VAR1%% = %%LIT0%% and %%VAR0%% <> %%LIT1%%)
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)
      @bl.tokenize_vars

      @bl.tokenize_literals

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'yesno___1']
      expect(@bl.literals).to eq ['1', 'some "value"']
      expect(@bl.numbers).to eq []

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> "some (other) 'value'") or [ants] > 10
      ENDSTR

      exp = <<~ENDSTR.strip
        (%%VAR2%% = %%LIT0%% and %%VAR0%% <> %%LIT1%%) or %%VAR1%% > %%NUM0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars

      @bl.tokenize_literals

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'ants', 'yesno___1']
      expect(@bl.literals).to eq ['1', "some (other) 'value'"]
      expect(@bl.numbers).to eq [10]
    end

    it 'tokenizes operators' do
      test = <<~ENDSTR.strip
        [yesno(1)] = "1"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% = %%LIT0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['yesno___1']
      expect(@bl.literals).to eq ['1']
      expect(@bl.operators).to eq []

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> "some value")
      ENDSTR

      exp = <<~ENDSTR.strip
        (%%VAR1%% = %%LIT0%% %%OP0%% %%VAR0%% <> %%LIT1%%)
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'yesno___1']
      expect(@bl.literals).to eq ['1', 'some value']
      expect(@bl.operators).to eq ['and']

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> "some (other) 'value'") or [ants] = 'many'
      ENDSTR

      exp = <<~ENDSTR.strip
        (%%VAR2%% = %%LIT0%% %%OP0%% %%VAR0%% <> %%LIT1%%) %%OP1%% %%VAR1%% = %%LIT2%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'ants', 'yesno___1']
      expect(@bl.literals).to eq ['1', "some (other) 'value'", 'many']
      expect(@bl.operators).to eq ['and', 'or']
    end

    it 'tokenizes comparisons' do
      test = <<~ENDSTR.strip
        [yesno(1)] = "1"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%VAR0%% %%COMP0%% %%LIT0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['yesno___1']
      expect(@bl.literals).to eq ['1']
      expect(@bl.operators).to eq []
      expect(@bl.comps).to eq ['=']

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> "some value")
      ENDSTR

      exp = <<~ENDSTR.strip
        (%%VAR1%% %%COMP0%% %%LIT0%% %%OP0%% %%VAR0%% %%COMP1%% %%LIT1%%)
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'yesno___1']
      expect(@bl.literals).to eq ['1', 'some value']
      expect(@bl.operators).to eq ['and']
      expect(@bl.comps).to eq ['=', '<>']

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> "some (other) 'value'") or [ants] > 10
      ENDSTR

      exp = <<~ENDSTR.strip
        (%%VAR2%% %%COMP0%% %%LIT0%% %%OP0%% %%VAR0%% %%COMP1%% %%LIT1%%) %%OP1%% %%VAR1%% %%COMP2%% %%NUM0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'ants', 'yesno___1']
      expect(@bl.literals).to eq ['1', "some (other) 'value'"]
      expect(@bl.numbers).to eq [10]
      expect(@bl.operators).to eq ['and', 'or']
      expect(@bl.comps).to eq ['=', '<>', '>']
    end

    it 'converts parentheses to blocks' do
      test = <<~ENDSTR.strip
        [yesno(1)] = "1"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%BLOCK0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps
      @bl.tokenize_blocks

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['yesno___1']
      expect(@bl.literals).to eq ['1']
      expect(@bl.operators).to eq []
      expect(@bl.comps).to eq ['=']
      expect(@bl.blocks).to eq ['%%VAR0%% %%COMP0%% %%LIT0%%']

      test = <<~ENDSTR.strip
        [yesno(1)] = "1" and [test_var] <> "some value"
      ENDSTR

      exp = <<~ENDSTR.strip
        %%BLOCK0%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps
      @bl.tokenize_blocks

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'yesno___1']
      expect(@bl.literals).to eq ['1', 'some value']
      expect(@bl.operators).to eq ['and']
      expect(@bl.comps).to eq ['=', '<>']
      expect(@bl.blocks).to eq ['%%VAR1%% %%COMP0%% %%LIT0%% %%OP0%% %%VAR0%% %%COMP1%% %%LIT1%%']

      test = <<~ENDSTR.strip
        ([yesno(1)] = "1" and [test_var] <> "some (other) 'value'") or [ants] = 'many'
      ENDSTR

      exp = <<~ENDSTR.strip
        %%BLOCK1%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps
      @bl.tokenize_blocks

      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['test_var', 'ants', 'yesno___1']
      expect(@bl.literals).to eq ['1', "some (other) 'value'", 'many']
      expect(@bl.numbers).to eq []
      expect(@bl.operators).to eq ['and', 'or']
      expect(@bl.comps).to eq ['=', '<>', '=']
      expect(@bl.blocks).to eq [
        '%%VAR2%% %%COMP0%% %%LIT0%% %%OP0%% %%VAR0%% %%COMP1%% %%LIT1%%',
        '%%BLOCK0%% %%OP1%% %%VAR1%% %%COMP2%% %%LIT2%%'
      ]

      test = <<~ENDSTR.strip
        ([aaa] = 1 or [bbb] >= 3) and (([yesno(1)] = "1" and [test_var] <> "some (other) 'value'") or [ants] = 'many')
      ENDSTR

      exp = <<~ENDSTR.strip
        %%BLOCK3%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      @bl.tokenize_vars
      @bl.tokenize_literals
      @bl.tokenize_operators
      @bl.tokenize_comps
      @bl.tokenize_blocks
      # (%%VAR0%% %%COMP0%% %%NUM0%% %%OP0%% %%VAR1%% %%COMP1%% %%NUM1%%) %%OP1%% ((%%VAR4%% %%COMP2%% %%LIT0%% %%OP2%% %%VAR2%% %%COMP3%% %%LIT1%%) %%OP3%% %%VAR3%% %%COMP4%% %%LIT2%%)
      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['aaa', 'bbb', 'test_var', 'ants', 'yesno___1']
      expect(@bl.literals).to eq ['1', "some (other) 'value'", 'many']
      expect(@bl.numbers).to eq [1, 3]
      expect(@bl.operators).to eq ['or', 'and', 'and', 'or']
      expect(@bl.comps).to eq ['=', '>=', '=', '<>', '=']
      expect(@bl.blocks).to eq [
        '%%VAR0%% %%COMP0%% %%NUM0%% %%OP0%% %%VAR1%% %%COMP1%% %%NUM1%%',
        '%%VAR4%% %%COMP2%% %%LIT0%% %%OP2%% %%VAR2%% %%COMP3%% %%LIT1%%',
        '%%BLOCK1%% %%OP3%% %%VAR3%% %%COMP4%% %%LIT2%%',
        '%%BLOCK0%% %%OP1%% %%BLOCK2%%'
      ]
    end

    it 'generates a hash of blocks' do
      test = <<~ENDSTR.strip
        ([aaa] = 1 or [bbb] >= 3) and (([yesno(1)] = "1" and [test_var] <> "some (other) 'value'" and [test_var] <> "this value" or [other] = "other1") or [ants] = 'many')
      ENDSTR

      exp = <<~ENDSTR.strip
        %%BLOCK3%%
      ENDSTR

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)

      res = @bl.hash_of_blocks
      # (%%VAR0%% %%COMP0%% %%NUM0%% %%OP0%% %%VAR1%% %%COMP1%% %%NUM1%%)
      # %%OP1%% (
      #   (%%VAR5%% %%COMP2%% %%LIT0%% %%OP2%% %%VAR2%% %%COMP3%% %%LIT1%% %%OP3%% %%VAR3%% %%COMP4%% %%LIT2%%)
      #      %%OP3%%
      #        %%VAR3%% %%COMP4%% %%LIT2%%
      # )
      expect(@bl.condition_string).to eq exp
      expect(@bl.vars).to eq ['aaa', 'bbb', 'test_var', 'test_var', 'other', 'ants', 'yesno___1']
      expect(@bl.literals).to eq ['1', "some (other) 'value'", 'this value', 'other1', 'many']
      expect(@bl.numbers).to eq [1, 3]
      expect(@bl.operators).to eq ['or', 'and', 'and', 'and', 'or', 'or']
      expect(@bl.comps).to eq ['=', '>=', '=', '<>', '<>', '=', '=']

      expect(@bl.blocks).to eq [
        '%%VAR0%% %%COMP0%% %%NUM0%% %%OP0%% %%VAR1%% %%COMP1%% %%NUM1%%',
        '%%VAR6%% %%COMP2%% %%LIT0%% %%OP2%% %%VAR2%% %%COMP3%% %%LIT1%% %%OP3%% %%VAR3%% %%COMP4%% %%LIT2%% %%OP4%% %%VAR4%% %%COMP5%% %%LIT3%%',
        '%%BLOCK1%% %%OP5%% %%VAR5%% %%COMP6%% %%LIT4%%',
        '%%BLOCK0%% %%OP1%% %%BLOCK2%%'
      ]

      exp_hash = [
        [{ 'any_0' => ['%%VAR0%% %%COMP0%% %%NUM0%%', '%%VAR1%% %%COMP1%% %%NUM1%%'] }],
        [
          { 'all_1' => ['%%VAR6%% %%COMP2%% %%LIT0%%', '%%VAR2%% %%COMP3%% %%LIT1%%', '%%VAR3%% %%COMP4%% %%LIT2%%'] },
          { 'any_1' => ['%%VAR4%% %%COMP5%% %%LIT3%%'] }
        ],
        [{ 'any_2' => ['%%BLOCK1%%', '%%VAR5%% %%COMP6%% %%LIT4%%'] }],
        [{ 'all_3' => ['%%BLOCK0%%', '%%BLOCK2%%'] }]
      ]

      expect(res).to eq(exp_hash)

      #  ([aaa] = 1 or [bbb] >= 3)
      #  and
      #  (
      #   ([yesno(1)] = "1" and [test_var] <> "some (other) 'value'" and [test_var] <> "this value" or [other] = "other1")
      #   or
      #   [ants] = 'many'
      #  )

      final_exp = {
        all_3: {
          all_block_0: {
            any_0: {
              # Equality matches are handled with the simple form
              aaa: 1,
              # Non-equality matches use an explicit condition construction
              bbb: {
                condition: '>=',
                value: 3
              }
            }
          },
          all_block_2: {
            any_2: {
              # A block is marked with "all_..." for identification and to aid duplication of variable keys later
              all_sub_block_2: {
                any_2: {
                  all_1: {
                    yesno___1: '1',
                    test_var: {
                      condition: '<>',
                      value: "some (other) 'value'"
                    },
                    # Add each duplicated key value into its own block for evaluation
                    all_dupvar_0: {
                      test_var: {
                        condition: '<>',
                        value: 'this value'
                      }
                    }
                  },
                  any_1: {
                    other: 'other1'
                  }
                }
              },
              ants: 'many'
            }
          }
        }
      }

      final_res = @bl.final_hash
      expect(final_res).to eq final_exp
    end

    it 'generates show_if hash' do
      test = <<~ENDSTR.strip
        [val_instr]='2'
      ENDSTR

      final_exp = {
        all_no_op_0: {
          all_nonblock_0: {
            val_instr: '2'
          }
        }
      }

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)
      final_res = @bl.generate_show_if
      expect(final_res).to eq final_exp

      test = <<~ENDSTR.strip
        [smoketime(pnfl)] = '1'
      ENDSTR

      final_exp = {
        all_no_op_0: {
          all_nonblock_0: {
            smoketime___pnfl: '1'
          }
        }
      }

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)
      final_res = @bl.generate_show_if
      expect(final_res).to eq final_exp

      test = <<~ENDSTR.strip
        [test] <> "" and [test2] = "hello"
      ENDSTR

      final_exp = {
        all_0: {
          all_nonblock_0: {
            test: {
              condition: '<>',
              value: ''
            }
          },
          all_nonblock_1: {
            test2: 'hello'
          }
        }
      }

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)
      final_res = @bl.generate_show_if
      expect(final_res).to eq final_exp

      test = <<~ENDSTR.strip
        [test] <> "" and ([test2] = "hello" or [test] = 'force')
      ENDSTR

      final_exp = {
        all_1: {
          all_nonblock_0: {
            test: {
              condition: '<>',
              value: ''
            }
          },
          all_block_0: {
            any_0: {
              test2: 'hello',
              test: 'force'
            }
          }
        }
      }

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)
      final_res = @bl.generate_show_if
      expect(final_res).to eq final_exp

      test = <<~ENDSTR.strip
        ([aaa] = 1 or [bbb] >= 3) and (([yesno(1)] = "1" and [test_var] <> "some (other) 'value'" and [test_var] <> "this value" or [other] = "other1") or [ants] = 'many')
      ENDSTR

      final_exp = {
        all_3: {
          all_block_0: {
            any_0: {
              # Equality matches are handled with the simple form
              aaa: 1,
              # Non-equality matches use an explicit condition construction
              bbb: {
                condition: '>=',
                value: 3
              }
            }
          },
          all_block_2: {
            any_2: {
              # A block is marked with "all_..." for identification and to aid duplication of variable keys later
              all_sub_block_2: {
                any_2: {
                  all_1: {
                    yesno___1: '1',
                    test_var: {
                      condition: '<>',
                      value: "some (other) 'value'"
                    },
                    # Add each duplicated key value into its own block for evaluation
                    all_dupvar_0: {
                      test_var: {
                        condition: '<>',
                        value: 'this value'
                      }
                    }
                  },
                  any_1: {
                    other: 'other1'
                  }
                }
              },
              ants: 'many'
            }
          }
        }
      }

      @bl = Redcap::DataDictionaries::BranchingLogic.new(test)
      final_res = @bl.generate_show_if
      expect(final_res).to eq final_exp
    end
  end
end
