require 'dry-validation'
require 'yaml'

module Schema

  DURATION = /^\d+[smhdwy]$/
  DURATION_OR_DEFAULT = /^(default|\d+[smhdwy])$/

  ID_NAME = /[[:alpha:]][[:alnum:]]*(_[[:alnum:]]+)*/
  ID_PART = /\$?#{ID_NAME}/
  ID_SHORT = /^#{ID_PART}$/
  ID_FULL = /^#{ID_PART}(\.#{ID_PART})*$/
  ID_VAR = /^\$#{ID_NAME}$/

  Retention = Dry::Validation.Schema do
    required(:frequency).filled(:str?, format?: DURATION_OR_DEFAULT)
    required(:keep).filled(:str?, format?: DURATION)
  end

  RetentionRule = Dry::Validation.Schema do
    required(:title).filled(:str?, min_size?: 3)
    optional(:description).filled(:str?, min_size?: 3)
    required(:pattern).filled(:str?)
    required(:retention).each(Retention)
  end

  AggregationRule = Dry::Validation.Schema do
    required(:name).filled(:str?, format?: /^#{ID_NAME}$/)
    optional(:description).filled(:str?, min_size?: 3)
    required(:pattern).filled(:str?)
    required(:factor).filled(:float?, included_in?: 0.0..1.0)
    required(:method).filled(:str?, included_in?: %w[average sum min max and last])
  end

  IdVar = Dry::Validation.Schema do
    required(:name).filled(:str?, format?: ID_VAR)
    optional(:enum).each(:str?)
    optional(:regexp).filled(:str?)
  end

  Metric = Dry::Validation.Schema do
    required(:name) do
      each(:str?, format?: ID_SHORT) | filled? & str? & format?(ID_FULL)
    end
    required(:type).filled(:str?, included_in?: %w[counter timer gauge set])

    optional(:title).filled(:str?, min_size?: 3)
    optional(:description).filled(:str?, min_size?: 3)

    optional(:retention).each(Retention)

    optional(:id_vars).each(IdVar)
    optional(:histogram).each do
      int? & gteq?(0) | float? & gteq?(0) | str? & eql?('inf')
    end
  end

  Main = Dry::Validation.Schema do
    required(:frame).filled(:int?, gt?: 0)
    required(:flush_period).filled(:str?, format?: DURATION)
    required(:retentions).each(RetentionRule)
    required(:aggregations).each(AggregationRule)
    required(:metrics).each(Metric)
  end
end