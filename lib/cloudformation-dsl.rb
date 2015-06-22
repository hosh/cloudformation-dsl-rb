require "cloudformation-dsl/version"

module CloudFormationDSL
  autoload :Template, 'cloudformation-dsl/template'
  autoload :Helpers,  'cloudformation-dsl/helpers'

  def self.describe(&block)
    CloudFormationDSL::Template.new(&block)
  end

  def self.load_from(filename)
    CloudFormationDSL::Template.new(filename)
  end
end
