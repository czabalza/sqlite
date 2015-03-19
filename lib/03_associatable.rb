require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {:foreign_key => "#{name}_id".to_sym,
                :primary_key => :id,
                :class_name => name.to_s.capitalize
                }
    instances = defaults.merge(options)
    @foreign_key = instances[:foreign_key]
    @primary_key = instances[:primary_key]
    @class_name = instances[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self_class_name = self.class if self_class_name.nil?
    defaults = {:foreign_key => "#{self_class_name.to_s.downcase}_id".to_sym,
                :primary_key => :id,
                :class_name => name.to_s.capitalize.singularize
                }
    instances = defaults.merge(options)
    @foreign_key = instances[:foreign_key]
    @primary_key = instances[:primary_key]
    @class_name = instances[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method("#{name}") do
      other_table = options.table_name
      my_table = self.class.table_name
      f_k_value = self.send(:id)
      f_k = options.foreign_key
      model_class = options.model_class
      p_k = options.primary_key
      answer = DBConnection.execute(<<-SQL, :f_k_v => f_k_value)
        SELECT
          "#{other_table}".*
        FROM
          "#{other_table}"
        -- JOIN
        --   "#{my_table}"
        -- ON
        --   "#{other_table}"."#{p_k}" = "#{my_table}"."#{f_k}"
        WHERE
          "#{other_table}"."#{p_k}" = :f_k_v
      SQL

      model_class.new(answer.first) unless answer.empty?
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self, options)
    define_method("#{name}") do
      f_k = options.foreign_key
      p_k = options.primary_key
      other_table = options.table_name
      my_table = self.class.table_name
      model_class = options.model_class
      p_k_value = self.send(:id)
      answer = DBConnection.execute(<<-SQL, p_k_v: p_k_value)
        SELECT
          "#{other_table}".*
        FROM
          "#{other_table}"
        -- JOIN
        --   "#{my_table}"
        -- ON
        --   "#{other_table}"."#{f_k}" = "#{my_table}"."#{p_k}"
        WHERE
          "#{other_table}"."#{f_k}" = :p_k_v
      SQL
      if answer.empty?
        []
      else
        answer.map do |thing|
          model_class.new(thing)
        end
      end
    end
  end

  def assoc_options
    # @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
