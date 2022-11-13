# frozen_string_literal: true

require 'strscan'

# This is whitespace interpreter
class Whitespace
  def initialize
    # プログラムファイルの読み込み
    begin
      @code = ARGF.readlines.join unless ARGV.empty?
    rescue StandardError
      puts "#{ARGF.filename}: No such file or directory"
    end

    @code.gsub!(/[^ \t\n]/, '') # 空白文字以外は排除

    # IMP表
    @imps = {
      's' => :stack_mnpl,
      'ts' => :arithmetic,
      'tt' => :heap_access,
      'n' => :flow_cntl,
      'tn' => :io
    }

    # スタック操作コマンド表
    @imp_s = {
      's' => :push,
      'ns' => :duplicate,
      'ts' => :n_duplicate,
      'nt' => :switch,
      'nn' => :discard,
      'tn' => :n_discard
    }

    # 算術演算コマンド表
    @imp_ts = {
      'ss' => :add,
      'st' => :sub,
      'sn' => :mul,
      'ts' => :div,
      'tt' => :rem
    }

    # ヒープアクセスコマンド表
    @imp_tt = {
      's' => :h_push,
      't' => :h_pop
    }

    # フロー制御コマンド表
    @imp_n = {
      'ss' => :mark,
      'st' => :sub_start,
      'sn' => :jump,
      'ts' => :jump_zero,
      'tt' => :jump_negative,
      'tn' => :sub_end,
      'nn' => :end
    }

    # 入出力コマンド表
    @imp_tn = {
      'ss' => :output_char,
      'st' => :output_num,
      'ts' => :input_char,
      'tt' => :input_num
    }

    # 字句解析
    begin
      @tokenized_list = tokenize
    rescue StandardError => e
      puts e.message.to_s
    end

    # 確認用
    # @tokenized_list.each_slice(3) { |t| p t.join(', ') }
    # p stn_replace(@code)
    p @tokenized_list
  end

  # 字句解析
  def tokenize
    result = []
    line = StringScanner.new(@code)

    loop do
      # IMP切り出し
      unless (imp_sp = line.scan(/\A( |\n|\t[ \n\t])/))
        raise StandardError, 'undefined imp'
      end

      repd_imp = stn_replace(imp_sp) # impを文字に変換
      imp = @imps[repd_imp] # impをシンボルに変換

      # コマンド切り出し
      cmd_sp = get_command(line, repd_imp) # コマンドを文字に変換

      command = instance_variable_get("@imp_#{repd_imp}")[stn_replace(cmd_sp)] # コマンドをシンボルに変換

      # パラメータ切り出し(必要なら)
      if parameter_check(imp, command)
        unless (param_sp = line.scan(/\A([ \t]+\n)/))
          raise StandardError, 'undefined parameter'
        end

        param_sp.chop! # 最後の改行を削除
        param = stn_replace(param_sp) # パラメータを文字に変換
      end

      result << imp << command << param
      break unless line.exist?(/ |\t|\n/)
    end
    result
  end

  # 空白文字を文字に変換
  def stn_replace(space)
    result = []
    space.chars.each do |sp|
      case sp
      when ' '
        result << 's'
      when /\t/
        result << 't'
      when /\n/
        result << 'n'
      end
    end
    result.join
  end

  # コマンドを抽出
  def get_command(line, imp)
    result = nil

    case imp
    when 's'
      result = line.scan(/\A( |\n[ \n\t]|\t[ \n])/)
    when 'ts'
      result = line.scan(/\A( [ \t\n]|\t[ \t])/)
    when 'tt'
      result = line.scan(/\A( |\t)/)
    when 'n'
      result = line.scan(/\A( [ \t\n]|\t[ \t\n]|\n\n)/)
    when 'tn'
      result = line.scan(/\A( [ \t]|\t[ \t])/)
    end
    raise StandardError, 'undefined command' unless result

    result
  end

  # パラメータの有無を確認
  def parameter_check(imp, cmd)
    return true if imp == :stack_mnpl && cmd == :push
    return true if imp == :stack_mnpl && cmd == :n_duplicate
    return true if imp == :stack_mnpl && cmd == :n_discard

    return true if imp == :flow_cntl && cmd != :sub_end && cmd != :end

    false
  end
end


Whitespace.new
