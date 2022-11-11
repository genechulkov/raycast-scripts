#!/usr/bin/env ruby
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title video:convert
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 📹

# Documentation:
# @raycast.author Eugene Chulkov
# @raycast.authorURL https://github.com/dev99problems

INPUT = './input'
OUTPUT = './output'

module Utils # :nodoc:
  def created_today?(date)
    today = Time.now
    date.day == today.day && date.month == today.month
  end

  def get_path(filename)
    input_filepath = "#{INPUT}/#{filename}",
    output_filepath = "#{OUTPUT}/#{filename}"
  end
end

module FS # :nodoc:
  def safe_children(dirname)
    !Dir.exist?(dirname) && Dir.mkdir(dirname)
    Dir.children(dirname)
  end
end

include Utils
include FS

def convert(filename)
  input, output = Utils.get_path(filename)
  command = "ffmpeg -i #{input.inspect} -hide_banner -loglevel error -vf scale=1920:1024 -preset slow -crf 18 #{output.inspect} -y"
  # async
  fork { exec(command) }
end

input_files = FS.safe_children(INPUT)
output_files = FS.safe_children(OUTPUT)

def get_files_in_scope(input_files, output_files)
  input_files.select do |filename|
    input, = Utils.get_path(filename)

    creation_date = File.birthtime(input)
    already_converted = output_files.include?(filename)
    is_directory = File.directory?(input)

    is_in_scope = created_today?(creation_date) && !already_converted && !is_directory
    filename if is_in_scope
  end
end

scope = get_files_in_scope(input_files, output_files)

if scope.empty?
  puts 'Nothing to convert!'
else
  puts 'Files to be converted:'
end

scope.each do |filename|
  p filename
  convert filename
end
