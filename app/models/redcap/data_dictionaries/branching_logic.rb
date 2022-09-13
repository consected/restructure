# frozen_string_literal: true

module Redcap
  module DataDictionaries
    #
    # Categorical selection choices for a field
    class BranchingLogic
      attr_accessor :condition_string, :orig_condition_string, :vars, :literals, :blocks, :operators, :comps, :numbers,
                    :block_hashes, :final_hash_list, :result, :field

      def self.clean_string(str)
        str.gsub("[\n\s]+", ' ').strip
      end

      def self.get_token_num(tok, str)
        res = str.match(/%%#{tok}([0-9]+)%%/)
        return unless res

        res[1].to_i
      end

      #
      # Initialize a new branching logic condition, with optional *field_or_condition_string*
      # @param [<Type>] condition_string <description>
      def initialize(field_or_condition_string = nil)
        if field_or_condition_string.is_a? Field
          self.field = field_or_condition_string
          condition_string = field_branching_logic
        else
          condition_string = field_or_condition_string
        end

        reset_scan

        self.condition_string = condition_string.dup
        self.orig_condition_string = condition_string.dup
      end

      #
      # Return the branching logic from a Field, to use as a condition string
      # @return [String]
      def field_branching_logic
        field_metadata = field.def_metadata
        field_metadata[:branching_logic]
      end

      #
      # Generating conditions to pass to a regular _fpa_show_if.js calculation with
      #   bl = Redcap::DataDictionaries::BranchingLogic.new(condition_string)
      #   bl.generate_show_if
      # Returns a show_if hash and sets @result to the return value
      # NOTE: There are likely to be situations where this fails, if we have
      # multiple and / or conditions in a line without parentheses to make the precedence clear
      # @return [Hash]
      def generate_show_if
        hash_of_blocks
        final_hash
      end

      def reset_scan
        self.vars = []
        self.literals = []
        self.numbers = []
        self.blocks = []
        self.operators = []
        self.comps = []
        self.block_hashes = []
        self.final_hash_list = []
        self.result = {}
      end

      def clean_condition_string
        self.class.clean_string condition_string
      end

      def tokenize_vars
        pos = 0

        re = /\[([a-zA-Z0-9_]+)\]/
        condition_string.scan(re).each do |match|
          vars << match[0]
          condition_string.sub!(re, "%%VAR#{pos}%%")
          pos += 1
        end

        re = /\[([a-zA-Z0-9_]+)\(([a-zA-Z0-9]+)\)\]/
        # checkbox choice varname abc(1) -> abc___1 or smoketime(pnfl) smoketime___pnfl
        condition_string.scan(re).each do |match|
          vars << match.join('___')
          condition_string.sub!(re, "%%VAR#{pos}%%")
          pos += 1
        end

        self.condition_string = condition_string
      end

      def tokenize_literals
        pos = 0

        re = /"([^"]*?)"|'([^']*?)'/
        condition_string.scan(re).each do |match|
          literals << match.compact[0]
          condition_string.sub!(re, "%%LIT#{pos}%%")
          pos += 1
        end

        pos = 0
        re = /([^A-Z])(-?[0-9]+)/
        condition_string.scan(re).each do |match|
          str = match[1]
          num = if str.include?('.')
                  str.to_f
                else
                  str.to_i
                end
          numbers << num
          condition_string.sub!(re, "#{match[0]}%%NUM#{pos}%%")
          pos += 1
        end
      end

      def tokenize_operators
        pos = 0

        re = /\s(or|and|OR|AND)\s/
        condition_string.scan(re).each do |match|
          operators << match[0]
          condition_string.sub!(re, " %%OP#{pos}%% ")
          pos += 1
        end
      end

      def tokenize_comps
        pos = 0

        re = /\s?(<=|>=|<>|<|>|=)\s?/
        condition_string.scan(re).each do |match|
          comps << match[0]
          condition_string.sub!(re, " %%COMP#{pos}%% ")
          pos += 1
        end
      end

      def tokenize_blocks
        pos ||= 0
        got = -1
        self.condition_string = "(#{clean_condition_string})".dup

        until got == 0
          got = 0
          re = /\(([^()]+)\)/
          condition_string.scan(re).each do |match|
            blocks << match[0]
            condition_string.sub!(re, "%%BLOCK#{pos}%%")
            pos += 1
            got += 1
          end
        end
      end

      def hash_of_blocks
        tokenize_vars
        tokenize_literals
        tokenize_operators
        tokenize_comps
        tokenize_blocks

        block_num = -1

        blocks.each do |block|
          block = block.dup
          new_block = handle_block_ops(block, block_num)
          block_hashes << new_block
          block_num += 1
        end
        block_hashes
      end

      def handle_block_ops(block, block_num)
        re = /%%OP[0-9]+%%/
        prev_op = nil
        all_any = 'all'
        sub_list = []
        key = ''
        op_changed = false

        oplist = block.scan(re)
        blocksplit = block.split(re)
        matchnum = 0

        blocksplit.each do |left|
          left.strip!

          opstr = oplist[matchnum]
          op = nil
          if opstr
            num = self.class.get_token_num('OP', opstr)
            op = operators[num]

            block_num += 1 if prev_op.nil? || op_changed
            all_any = if op.downcase == 'or'
                        'any'
                      else
                        'all'
                      end
            key = "#{all_any}_#{block_num}"
          end

          if prev_op.nil? || op_changed
            key = 'all_no_op_0' if key.blank?
            sub_list << { key => [left] }
          else
            sub_list.last.first.last << left
          end
          op_changed = (prev_op && prev_op != op)

          matchnum += 1
          prev_op = op
        end

        sub_list
      end

      def final_hash
        block_re = /%%BLOCK[0-9]+%%/

        hashnum = 0
        dupvarnum = 0
        nonblocknum = 0
        final_item = nil
        num_block_hashes = block_hashes.length

        block_hashes.each do |block_hash|
          block_hash.each do |bah|
            bah.each do |key, conds|
              conds.each do |cond|
                final_hash_list[hashnum] ||= {}
                final_hash_list[hashnum][key] ||= {}
                if cond.index(block_re)
                  # is a previous block
                  num = self.class.get_token_num('BLOCK', cond)
                  sub_block = final_hash_list[num]
                  final_cond = { "all_sub_block_#{hashnum}" => { key => sub_block } }
                end

                if sub_block
                  result["final_block_#{hashnum}"] ||= {}
                  result["final_block_#{hashnum}"][key] ||= {}
                  result["final_block_#{hashnum}"][key].merge! "all_block_#{num}" => sub_block
                else
                  # not a block
                  final_cond = final_condition(cond)
                  if final_hash_list[hashnum][key].key?(final_cond.keys.first)
                    # The key already exists in the final hash. Put it inside an 'all'
                    # condition to allow duplication
                    final_cond = {
                      "all_dupvar_#{dupvarnum}" => final_cond
                    }
                    dupvarnum += 1
                  end
                end

                if num_block_hashes == hashnum + 1 && !sub_block
                  result["final_block_#{hashnum}"] ||= {}
                  result["final_block_#{hashnum}"][key] ||= {}
                  result["final_block_#{hashnum}"][key].merge! "all_nonblock_#{nonblocknum}" => final_cond
                  nonblocknum += 1
                end

                final_hash_list[hashnum][key].merge!(final_cond)
              end
            end
          end
          hashnum += 1
        end
        final_key = "final_block_#{hashnum - 1}"
        self.result = result[final_key]&.deep_symbolize_keys!
      end

      def final_condition(condition)
        tokens = condition.split(' ')
        raise FphsException, "Incorrect number of tokens #{tokens} for: #{condition_string}" if tokens.length != 3

        num = self.class.get_token_num('VAR', tokens[0])
        var = vars[num]
        num = self.class.get_token_num('COMP', tokens[1])
        comp = comps[num]
        num = self.class.get_token_num('LIT', tokens[2])
        if num
          comp_val = literals[num]
        else
          num = self.class.get_token_num('NUM', tokens[2])
          comp_val = numbers[num] if num
        end

        if comp == '='
          {
            var => comp_val
          }
        else
          {
            var => {
              'condition' => comp,
              'value' => comp_val
            }
          }
        end
      end
    end
  end
end
