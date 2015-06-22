require "cloudformation-dsl/version"

module CloudFormationDSL
  autoload :Template, 'cloudformation-dsl/template'
  autoload :Helpers,  'cloudformation_dsl/helpers'

  def describe(&block)
    CloudFormationDSL.new(block)
  end
end
