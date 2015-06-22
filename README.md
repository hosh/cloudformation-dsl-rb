# cloudformation-ruby-dsl

A Ruby DSL and helper utilities for building CloudFormation templates dynamically.

This is a fork of bazzarvoice/cloudformation-ruby-dsl. However, that gem does more than simply being a DSL. This fork cuts out the non-DSL
feature. It provides:

  - Ruby DSL to generate a CloudFormation template described in JSON
  - A conversion tool

To upload the template, you use other tools such as the AWS Ruby SDK or Fog/AWS.

Original credits: Written by [Bazaarvoice](http://www.bazaarvoice.com): see [the contributors page](https://github.com/bazaarvoice/cloudformation-ruby-dsl/graphs/contributors) and [the initial contributions](https://github.com/bazaarvoice/cloudformation-ruby-dsl/blob/master/initial_contributions.md) for more details.

## Motivation

CloudFormation templates often contain repeated stanzas, information which must be loaded from external sources, and other functionality that would be easier handled as code, instead of configuration.

Consider when a userdata script needs to be added to a CloudFormation template. Traditionally, you would re-write the script by hand in a valid JSON format. Using the DSL, you can specify the file containing the script and generate the correct information at runtime.

    :UserData => base64(interpolate(file('userdata.sh')))

Additionally, CloudFormation templates are just massive JSON documents, making general readability and reusability an issue. The DSL allows not only a cleaner format (and comments!), but will also allow the same DSL template to be reused as needed.

## Installation

Run `gem install cloudformation-dsl` to install system-wide.

To use in a specific project, add `gem 'cloudformation-dsl'` to your Gemfile, and then run `bundle`.

## Releasing

See [Releasing](docs/Releasing.md).

## Contributing

See [Contributing](docs/Contributing.md).

## Usage

To convert existing JSON templates to use the DSL, run

    cfntemplate-to-ruby [EXISTING_CFN] > [NEW_NAME.rb]

You may need to preface this with `bundle exec` if you installed via Bundler.

Below are the various functions currently available in the DSL. See [the example script](examples/cloudformation-ruby-script.rb) for more usage information.

### DSL Statements

Everything should be wrapped in the following:

```
template = CloudFormationDSL.describe do
  # ... statements ...
end
```

Once there, you can get the JSON by calling `template.to_json`.

Add the named object to the appropriate collection.
- `parameter(name, options)` (may be marked :Immutable, which will raise error on a later change)
- `mapping(name, options)`
- `condition(name, conditions)`
- `resource(name, options)`
- `output(name, options)`

### CloudFormation Function Calls

Invoke an intrinsic CloudFormation function.
- `base64(value)`
- `find_in_map(map, key, name)`
- `get_att(resource, attribute)`
- `get_azs(region)`
- `join(delim, *list)`
- `select(index, list)`
- `ref(name)`

Intrinsic conditionals are also supported, with some syntactic sugar.
- `fn_not(condition)`
- `fn_or(*condition_list)`
- `fn_and(*condition_list)`
- `fn_if(condition, value_if_true, value_if_false)`
- `equal(lhsOperand, rhsOperand)`
- `not_equal(lhsOperand, rhsOperand)`

Reference a CloudFormation pseudo parameter.
- `aws_account_id()`
- `aws_notification_arns()`
- `aws_no_value()`
- `aws_region()`
- `aws_stack_id()`
- `aws_stack_name()`

### Utility Functions

Additional capabilities for file inclusion, etc.
- `tag(tag)`: add tags to the stack, which are inherited by all resources in that stack; can only be used at launch
- `file(name)`: return the named file as a string, for further use
- `load_from_file(filename)`: load the named file by a given type; currently handles YAML, JSON, and Ruby
- `interpolate(string)`: embed CFN references into a string (`{{ref('Service')}}`) for later interpretation by the CFN engine
- `Table.load(filename)`: load a table from the listed file, which can then be turned into mappings (via `get_map`)
