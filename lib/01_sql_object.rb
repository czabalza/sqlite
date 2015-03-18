require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    t_name = self.table_name
    table_info = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{t_name}
    SQL
    column_names = table_info.first
    column_names.map! do |c_name|
      c_name.to_sym
    end


  end

  def self.finalize!
    self.columns.each do |c_name|
      define_method("#{c_name}") do
        attributes[c_name]
      end
      define_method("#{c_name}=") do |value|
        attributes[c_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      @table_name = self.to_s.tableize
    end
    @table_name
  end

  def self.all
#    :table = self.table_name
    answer = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL

    parse_all(answer)
  end

  def self.parse_all(results)
    things = []
    results.each do |result|
      things << self.new(result)
    end
    things
  end

  def self.find(id)
    answer = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = #{id}
    SQL
  #  p answer
    self.new(answer.first) unless answer.empty?
  end

  def initialize(params = {})
    params.each do |attr_name, value|
  #    p value
      attr_name = attr_name.to_sym unless attr_name.is_a?(Symbol)
      unless self.class.columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    if @attributes.nil?
      @attributes = {}
    end
    @attributes
  end

  def attribute_values
    # p self
    # p self.class
    # p self.class.columns
    # self.class.columns.map do |col|
    #   self.send(col)
    # end
    attributes.values
  end

  def insert
    n = self.class.columns.length - 1
    new_columns = self.class.columns.dup
    new_columns.delete(:id)
    col_names = new_columns.join(", ")
    question_marks = (["?"] * n).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name}
        (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    # p self
    # p self.name
    # p self.owner_id
    self.id = DBConnection.last_insert_row_id
    # p self.id
    # p Cat.find(self.id)
  end

  def update
    set_line = self.class.columns.map do |col|
      "#{col} = ?"
    end.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
