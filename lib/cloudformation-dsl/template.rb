require 'json'
module CloudFormationDSL
  class Template
    include CloudFormationDSL::Helpers

    # You can supply:
    #   - filename
    #   - block
    # The file located at the filename is evaluated
    # The block will also be evaluated
    #
    # If both filename and block are passed, then the filename
    # is evaluated first before the block is evaluated.
    def initialize(filename = nil, &block)
      @template_file = filename
      @template_block = block
      @dict = {}
    end

    def aws_region
      ENV['EC2_REGION'] || ENV['AWS_DEFAULT_REGION'] || 'us-east-1'
    end

    def evaluated_data
      # Once evaluated, treat this as immutable. This allows us to lazy eval the template.
      return @dict unless @dict.empty?

      # See: http://stackoverflow.com/questions/4667158/ruby-instance-eval-a-file-while-maintaining-fileline-in-stacktrace
      instance_eval(File.read(@template_file), @template_file) if @template_file
      instance_eval(@template_block)                           if @template_block
      return @dict
    end

    def value(values)
      @dict.update(values)
    end

    def default(key, value)
      @dict[key] ||= value
    end

    def to_json(*args)
      evaluated_data.to_json(*args)
    end

    def print()
      puts JSON.pretty_generate(self)
    end


    # DSL for major sections
    def parameter(name, options)
      default(:Parameters, {})[name] = options
    end

    def condition(name, options) default(:Conditions, {})[name] = options end

    def resource(name, options) default(:Resources, {})[name] = options end

    def output(name, options) default(:Outputs, {})[name] = options end

    def mapping(name, options)
      # if options is a string and a valid file then the script will process the external file.
      default(:Mappings, {})[name] = if options.is_a?(Hash)
                                       options
                                     elsif options.is_a?(String)
                                       load_from_file(options)['Mappings'][name]
                                     else
                                       raise("Options for mapping #{name} is neither a string or a hash.  Error!")
                                     end
    end

    def tag(tag)
      tag.each do | name, value |
        default(:Tags, {})[name] = value
      end
    end

    # Cleanup

    # Find parameters where the specified attribute is true then remove the attribute from the cfn template.
    def excise_parameter_attribute!(attribute)
      marked_parameters = []
      @dict.fetch(:Parameters, {}).each do |param, options|
        if options.delete(attribute.to_sym) or options.delete(attribute.to_s)
          marked_parameters << param
        end
      end
      marked_parameters
    end

    def excise_tags!
      tags = @dict.fetch(:Tags, {})
      @dict.delete(:Tags)
      tags
    end
  end

end

