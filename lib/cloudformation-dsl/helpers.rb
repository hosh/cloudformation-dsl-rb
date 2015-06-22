module CloudFormationDSL
  module Helpers
    def load_from_file(filename)
      file = File.open(filename)
      # Figure out what the file extension is and process accordingly.
      case File.extname(filename)
      when ".rb"; eval(file.read, nil, filename)
      when ".json"; JSON.load(file)
      when ".yaml"; YAML::load(file)
      else
        raise("Do not recognize extension of #{filename}.")
      end
    ensure
      file.close
    end

    def find_in_map(map, key, name)
      # Eagerly evaluate mappings when all keys are known at template expansion time
      if map.is_a?(String) && key.is_a?(String) && name.is_a?(String)
        # We don't know whether the map was built with string keys or symbol keys.  Try both.
        def get(map, key) map[key] || map.fetch(key.to_sym) end
        get(get(@dict.fetch(:Mappings).fetch(map), key), name)
      else
        { :'Fn::FindInMap' => [ map, key, name ] }
      end
    end

    # Formation helpers

    def base64(value) { :'Fn::Base64' => value } end

    def find_in_map(map, key, name) { :'Fn::FindInMap' => [ map, key, name ] } end

    def get_att(resource, attribute) { :'Fn::GetAtt' => [ resource, attribute ] } end

    def get_azs(region = '') { :'Fn::GetAZs' => region } end

    def join(delim, *list)
      case list.length
      when 0 then ''
      when 1 then list[0]
      else join_list(delim,list)
      end
    end

    # Variant of join that matches the native CFN syntax.
    def join_list(delim, list) { :'Fn::Join' => [ delim, list ] } end

    def equal(one, two) { :'Fn::Equals' => [one, two] } end

    def fn_not(condition) { :'Fn::Not' => [condition] } end

    def fn_or(*condition_list)
      case condition_list.length
      when 0..1 then raise "fn_or needs at least 2 items."
      when 2..10 then  { :'Fn::Or' => condition_list }
      else raise "fn_or needs a list of 2-10 items that evaluate to true/false."
      end
    end

    def fn_and(*condition_list)
      case condition_list.length
      when 0..1 then raise "fn_and needs at least 2 items."
      when 2..10 then  { :'Fn::And' => condition_list }
      else raise "fn_and needs a list of 2-10 items that evaluate to true/false."
      end
    end

    def fn_if(cond, if_true, if_false) { :'Fn::If' => [cond, if_true, if_false] } end

    def not_equal(one, two) fn_not(equal(one,two)) end

    def select(index, list) { :'Fn::Select' => [ index, list ] } end

    def ref(name) { :Ref => name } end

    def aws_account_id() ref("AWS::AccountId") end

    def aws_notification_arns() ref("AWS::NotificationARNs") end

    def aws_no_value() ref("AWS::NoValue") end

    def aws_stack_id() ref("AWS::StackId") end

    def aws_stack_name() ref("AWS::StackName") end

    # deprecated, for backward compatibility
    def no_value()
      warn_deprecated('no_value()', 'aws_no_value()')
      aws_no_value()
    end

    # Read the specified file and return its value as a string literal
    def file(filename) File.read(File.absolute_path(filename, File.dirname($PROGRAM_NAME))) end

    # Interpolates a string like "NAME={{ref('Service')}}" and returns a CloudFormation "Fn::Join"
    # operation to collect the results.  Anything between {{ and }} is interpreted as a Ruby expression
    # and eval'd.  This is especially useful with Ruby "here" documents.
    # Local variables may also be exposed to the string via the `locals` hash.
    def interpolate(string, locals={})
      list = []
      while string.length > 0
        head, match, string = string.partition(/\{\{.*?\}\}/)
        list << head if head.length > 0
        list << eval(match[2..-3], nil, 'interpolated string') if match.length > 0
      end

      # Split out strings in an array by newline, for visibility
      list = list.flat_map {|value| value.is_a?(String) ? value.lines.to_a : value }
      join('', *list)
    end

    def join_interpolate(delim, string)
      $stderr.puts "join_interpolate(delim,string) has been deprecated; use interpolate(string) instead"
      interpolate(string)
    end
  end
end
