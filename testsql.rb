require 'sqlite3'

db = SQLite3::Database.new "beergrapher.db"

db.execute( "select * from item" ) do |row|
    print row[0];
end

