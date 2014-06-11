# encoding: utf-8

require 'sinatra'
require 'json'
require 'fileutils'
require 'sqlite3'

class InventoryItem

	def initialize()
	end

	def initialize(id,itemType, itemAmount, itemUnit, itemDescription)
		@id = id
		@type = itemType
		@amount = itemAmount
		@unit = itemUnit
		@description = itemDescription
	end

	def to_json
		return '{"type":'+@type.to_s+','+"\n"+'
				"id":'+@id.to_s+','+"\n"+'
	    		 "amount":'+@amount.to_s+','+"\n"+'
	    		 "unit":"'+@unit+'",'+"\n"+'
	    		 "description":"'+@description+'"}';
	end

	def to_jsonlist(itemlist)
		json = "["

		for item in itemlist
			if json.length > 2
				json += ","
			end
		    json += item.to_json
		end

		json += "]"

		return json
	end

	def saveToDatabase(db)
		sql = "";
		if @id.to_i < 1 
			sql = "insert into item(type,amount,unit,description) values(%s,%s,'%s','%s')" % [@type.to_s,@amount.to_s,@unit.to_s,@description.to_s]
		else
			sql = "update item set type=%s, amount=%s, unit='%s', description='%s' where id=%s" % [@type.to_s,@amount.to_s,@unit.to_s,@description.to_s,@id.to_s]
		end
		db.execute(sql)
	end

	def delete(db)
		sql = "delete from item where id=%s" % [@id]
		db.execute(sql);		
	end


end


helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'glittertind']
  end
end

get '/' do
	erb :index 
end

get '/inventorylist' do
	erb :inventory
end

get '/inventory' do
	db = SQLite3::Database.new "beergrapher.db"
	items = Array.new
	db.execute( "select * from item" ) do |row|
		items[items.length] = InventoryItem.new(row[0],row[1],row[2],row[3].to_s,row[4].to_s)
	end
	db.close
	return items[0].to_jsonlist(items)
end

post '/inventory' do
	protected!
	data = JSON.parse(request.body.read)

	$stdout.print("This is ", 100, " percent.\n")
	id = data['id']
	type = data['type']
	amount = data['amount']
	description = data['description']
	unit = data['unit']

	InventoryItem.new(id,type,amount,unit,description).saveToDatabase(SQLite3::Database.new "beergrapher.db")
end

delete '/inventory' do
	protected!
	data = JSON.parse(request.body.read)

	$stdout.print("This is ", 100, " percent.\n")
	id = data['id']
	type = data['type']
	amount = data['amount']
	description = data['description']
	unit = data['unit']

	InventoryItem.new(id,type,amount,unit,description).delete(SQLite3::Database.new "beergrapher.db")
end



get '/brews' do
	json = '[';
	Dir.glob('brews/**/index.json') do |file|
	  	if json != '['
			json = json +','
		end
	  	f = File.open(file);
		contents = f.read;
		json = json + contents;
	end
	json = json + ']';
	return json;
end


get '/brews/:id' do
	id =  params['id'];
	file = 'brews/'+id+'/index.json'
	f = File.open(file);
end

get '/temps/:id' do
	id =  params['id'];
	file = 'brews/'+id+'/temp.json'
	f = File.open(file);
end


post '/newbrew/' do
	protected!
	data = JSON.parse(request.body.read);
	name = data['t'];
	type = data['beertype'];
	
	print type

	id = Dir.glob('brews/**/index.json').count + 1;

	foldername = id.to_s;
	path = 'brews/'+foldername.to_s
	FileUtils::mkdir_p path;
	d = DateTime.now()

	File.open(path+'/index.json', 'w') do |f2|  
  		# use "\n" for two lines of text  
  		f2.puts '{'
  		f2.puts '"id":"'+id.to_s+'",'
  		f2.puts '"beername":"'+name+'",'
  		f2.puts '"beertype":"'+type+'",'
  		f2.puts '"date":"'+d.strftime("%d.%m.%Y-%I:%M")+'"'
  		f2.puts "}"
	end  
end

