require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(number)
  number = number.to_s.gsub("()", "")
  number.to_s.gsub!("-","")
  #number = number.to_s.delete("-")
  if (number.length == 11)
    unless number[0] != 1
      number.to_s[1..10]
    else
      number = 'Bad Number'  
    end

  elsif (number.length < 10 || number.length > 11)
    number = 'Bad Number'  
  end
  number
end

def write_date_and_time(name, date, time)
  filename = "output/d_reg.txt" #unless File.exist?('lib/d_reg.txt')
  File.open(filename, 'a') do |file| 
    file.puts "#{name} registered on #{date} at #{time}\n"
  end
end

def day_regestered(hash, k, date)
  h = k[date.wday]
  hash = hash.each {|k,v| hash[k] +=1 if h == k}
  hash
end

def write_most_reg_day(hash)
  day = hash.sort_by{|k,v| v}
  kday = day[6][0]
  filename = "output/d_reg.txt" #unless File.exist?('lib/d_reg.txt')
  File.open(filename, 'a') do |file| 
    file.puts "The day most people registered on is #{kday.capitalize}."
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

if File.exist?('output/d_reg.txt') then File.delete('output/d_reg.txt') end

days = {sunday: 0, monday: 0, tuesday: 0,
      wednesday: 0, thursday:0, friday: 0, saturday: 0}
k = days.keys

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = clean_phone_numbers(row[:homephone])
  dt = (row[:regdate]).split(" ")
  d = dt[0].split("/")
  d[2] = (d[2].to_i + 2000).to_s
  d = d.join("-")
  d = Date.strptime(d, '%m-%d-%Y')
  t = (Time.parse(dt[1])).strftime("%k:%M")

  days = day_regestered(days, k, d)

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
  write_date_and_time(name,d,t)
end

write_most_reg_day(days)
