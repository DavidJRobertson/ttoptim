#! /usr/bin/env ruby

### RUN AS:
### ruby paste-convert.rb inputfile.txt > outputfile.json

### HOW TO OBTAIN DATA:
### /Using Google Chrome/ log into UofG mycampus, navigate to
### enrollment > enroll by search. Then perform as broad a search as it will
### let you. Hit ctrl-a ctrl-c to copy all the page text, paste into a text file,
### then use this script to convert to json.


require 'json'

state = :prestart
classes         = []
current_class   = {}
current_section = {}
current_dates   = {}

ARGF.read.each_line do |line|
  line.strip!

  if line == "select"
    next
  end

  case state
  when :prestart
    # Skip any lines up to this point
    state = :start_class if line.end_with? 'class section(s) found'

  when :start_class
    if line.start_with? 'Collapse section '
      line = line[17..-1] # Strip off 'Collapse section '

      current_class = {}
      current_class[:code]  = line.split(' - ').first
      current_class[:title] = line.split(current_class[:code]+' - ').last
      current_class[:sections] = []

      state = :start_section
    end

  when :start_section
    if line == "Class\tSection\tStatus"
      state = :section_id
      current_section = {}
    end


  when :section_id
    current_section[:id] = line
    state = :section_title

  when :section_title
    a = line.split(' ')
    current_section[:type] = a.first
    current_section[:name] = a[1].split('-').first
    state = :section_status

  when :section_status
    current_section[:status] = line
    state = :section_start_dates

  when :section_start_dates
    if line == "Dates\tDays & Times\tRoom\tInstructor"
      state = :section_dates_period
      current_section[:dates] = []
      current_dates           = {}
    end

  when :section_dates_period
    current_dates[:period] = line
    state = :section_dates_times

  when :section_dates_times
    current_dates[:times] = line
    state = :section_dates_room

  when :section_dates_room
    current_dates[:room] = line
    state = :section_dates_instructor

  when :section_dates_instructor
    current_dates[:instructor] = line
    current_section[:dates] << current_dates
    state = :section_next

  when :section_next
    if line == "Class\tSection\tStatus"
      current_class[:sections] << current_section

      state = :section_id
      current_section = {}
    elsif line.start_with? 'Collapse section '
      current_class[:sections] << current_section
      classes << current_class

      line = line[17..-1] # Strip off 'Collapse section '

      current_class = {}
      current_class[:code]  = line.split(' - ').first
      current_class[:title] = line.split(current_class[:code]+' - ').last
      current_class[:sections] = []

      state = :start_section
    elsif line == "New Search"
      state = :prestart

    elsif line != ""
      state = :section_dates_times
      current_dates           = {period: line}
    end
  end
end

current_class[:sections] << current_section
classes << current_class

puts JSON.pretty_generate(classes)
