require "csv"
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
  digits = phone_number.gsub(/[^0-9]/, '')
  if digits.length > 11 || (digits.length == 11 && digits[0] != 1) || digits.length < 10
    return digits = "no valid number on file for mobile alerts"
  elsif digits.length == 11
    digits = digits[1..-1]
  else
    digits
  end
  digits = "#{digits[0..2]}-#{digits[3..5]}-#{digits[6..9]}"
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def time_targeting(registration_date_time)
  t = DateTime.strptime(registration_date_time, '%m/%d/%y %H:%M')

  if @registration_hour_by_traffic.keys.include?(t.hour)
    @registration_hour_by_traffic[t.hour] += 1
  else
    @registration_hour_by_traffic[t.hour] = 1
  end
end

def registration_by_day_of_week(registration_date_time)
  t = DateTime.strptime(registration_date_time, '%m/%d/%y %H:%M')
  if @registrations_by_day_of_week[t.wday]
    @registrations_by_day_of_week[t.wday] += 1
  else
    @registrations_by_day_of_week[t.wday] = 1
  end
end


@registration_hour_by_traffic = {}
@registrations_by_day_of_week = Hash.new(0)

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol


template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  registration_date_time = row[:regdate]
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
  time_targeting(registration_date_time)
  registration_by_day_of_week(registration_date_time)
end
puts "\nNumber of registrations at hour: "
puts @registration_hour_by_traffic.sort_by{ |hour, num_of_registrations| num_of_registrations }.reverse.to_h.inspect
puts "\nNumber of registrations on:"
puts "Sunday #{@registrations_by_day_of_week[0]}"
puts "Monday #{@registrations_by_day_of_week[1]}"
puts "Tuesday #{@registrations_by_day_of_week[2]}"
puts "Wednesday #{@registrations_by_day_of_week[3]}"
puts "Thursday #{@registrations_by_day_of_week[4]}"
puts "Friday #{@registrations_by_day_of_week[5]}"
puts "Saturday #{@registrations_by_day_of_week[6]}"
# puts "@registrations_by_day_of_week.inspect
