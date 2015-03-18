require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map do |key|
      "#{key} = ?"
    end.join(" AND ")
    p where_line
    p params.values
    answers = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    answers.map do |answer|
      self.new(answer)
    end
  #  p answers
  end
end

class SQLObject
  extend Searchable
end
