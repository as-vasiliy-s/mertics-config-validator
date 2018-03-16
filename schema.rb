require 'dry-validation'
require 'yaml'
require 'pp'

module Schema

  DURATION = /^\d+[smhdwy]$/

  ID_NAME = /[[:alpha:]][[:alnum:]]*(_[[:alnum:]]+)*/
  ID_PART = /\$?#{ID_NAME}/
  ID_SHORT = /^#{ID_PART}$/
  ID_FULL = /^#{ID_PART}(\.#{ID_PART})*$/
  ID_VAR = /^\$#{ID_NAME}$/

  Retention = Dry::Validation.Schema do
    required(:frequency).filled(:str?, format?: DURATION)
    required(:keep).filled(:str?, format?: DURATION)
  end

  Metric = Dry::Validation.Schema do
    # required(:name).filled(:str?, format?: ID_FULL)
    required(:type).filled(:str?, included_in?: %w[counter timer gauge set])

    optional(:description).filled(:str?, min_size?: 3)

    optional(:retention).each(Retention)

    optional(:histogram).each do
      int? & gteq?(0) | float? & gteq?(0) | str? & eql?('inf')
    end
  end

  Main = Dry::Validation.Schema do
    required(:flush_period).filled(:str?, format?: DURATION)
    required(:retention).each(Retention)
    required(:percentile).each { int? | float? }
    # required(:metrics_).each(Metric)
    required(:metrics).filled

    configure do
      def self.messages
        super.merge en: { errors: {
            metrics_names: 'some metrics names is not valid',
            metrics_schemas: 'some metrics is not valid'
        } }
      end
    end

    validate(metrics_names: :metrics) do |metrics|
      metrics.keys.all? { |name| name =~ ID_FULL }
    end

    validate(metrics_schemas: :metrics) do |metrics|
      metrics.all? do |name, metric|
        check_result = Metric.call(metric)
        puts "" "#{name}" " => #{check_result.messages.pretty_inspect}" if check_result.failure?
        check_result.success?
      end
    end
  end
end