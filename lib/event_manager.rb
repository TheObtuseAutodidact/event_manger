require "csv"
require 'sunlight/congress'
require 'erb'

# meaning_of_life = 42
#
# question = "The answere to the Ultimate Question of Life the Universe, and Everything is <%= meaning_of_life %>"
# template = ERB.new question
#
# result = template.result(binding)
# puts result


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

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)

end
