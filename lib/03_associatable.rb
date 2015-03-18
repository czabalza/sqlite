require_relative '02_searchable'
require 'active_support/inflector'

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
    defaults = {:foreign_key => "#{self_class_name.downcase}_id".to_sym,
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
    options = BelongsToOptions.new(name, options = {})
    p options
    other_class = options.model_class
    p other_class
    other_table = options.table_name
    p other_table
    my_table = self.to_s.tableize
    p my_table

    define_method("#{name}") do
      f_k = options.foreign_key
      p_k = options.primary_key
    #  f_k_value = self.send(id)
    p self.send(id)
      answer = DBConnection.execute.(<<-SQL, p_k, f_k, self.send(id))
        SELECT
          #{other_table}.*
        FROM
          #{other_table}
        JOIN
          #{my_table}
        ON
          #{other_table}.? = #{my_table}.?
        WHERE
          #{options.primary_key} = ?
      SQL

      answer.first
    end
  end

  def has_many(name, options = {})
    # ...
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
