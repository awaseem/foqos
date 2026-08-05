#!/usr/bin/env ruby
# frozen_string_literal: true

IOS_RELEASE_TARGETS = [
  "foqos",
  "FoqosDeviceMonitor",
  "FoqosShieldConfig",
  "FoqosWidgetExtension",
  "FoqosShieldAction"
].freeze
MAIN_APP_TARGET = "foqos"
DEFAULT_PROJECT_FILE = File.expand_path("../foqos.xcodeproj/project.pbxproj", __dir__)
VERSION_PATTERN = /\A\d+\.\d+(?:\.\d+)?\z/.freeze

def fail(message)
  warn "error: #{message}"
  exit 1
end

def target_configuration_ids(project, target_name)
  pattern = %r{
    ^\t\t[0-9A-F]+\ /\*\ Build\ configuration\ list\ for\ PBXNativeTarget\
    \ "#{Regexp.escape(target_name)}"\ \*/\ =\ \{\n
    (.*?)
    ^\t\t\};$
  }mx
  match = project.match(pattern)
  fail "Unable to find build configurations for target '#{target_name}'." unless match

  ids = match[1].scan(/^\t\t\t\t([0-9A-F]+) \/\* .* \*\/,$/).flatten
  fail "No build configurations found for target '#{target_name}'." if ids.empty?

  ids
end

def build_configuration_section(project)
  start_marker = "/* Begin XCBuildConfiguration section */"
  end_marker = "/* End XCBuildConfiguration section */"
  start_index = project.index(start_marker)
  end_index = project.index(end_marker)
  fail "Unable to find the XCBuildConfiguration section." unless start_index && end_index

  end_index += end_marker.length
  [start_index, end_index, project[start_index...end_index]]
end

def configuration_values(section, selected_ids)
  values = {}
  pattern = /\t\t([0-9A-F]+) \/\* ([^*]+) \*\/ = \{\n(.*?)\t\t\};/m

  section.scan(pattern) do |id, name, body|
    next unless selected_ids.include?(id)

    marketing_versions = body.scan(/^[ \t]*MARKETING_VERSION = ([^;]+);$/).flatten
    build_numbers = body.scan(/^[ \t]*CURRENT_PROJECT_VERSION = ([^;]+);$/).flatten
    fail "Expected one MARKETING_VERSION in #{id} (#{name.strip})." unless marketing_versions.one?
    fail "Expected one CURRENT_PROJECT_VERSION in #{id} (#{name.strip})." unless build_numbers.one?

    values[id] = {
      name: name.strip,
      marketing_version: marketing_versions.first,
      build_number: build_numbers.first
    }
  end

  missing_ids = selected_ids - values.keys
  fail "Missing build configuration blocks: #{missing_ids.join(', ')}." unless missing_ids.empty?

  values
end

def write_project(path, contents)
  temporary_path = "#{path}.tmp.#{Process.pid}"
  File.write(temporary_path, contents)
  File.rename(temporary_path, path)
ensure
  File.delete(temporary_path) if temporary_path && File.exist?(temporary_path)
end

mode = :update
if ARGV.first == "--current"
  mode = :current
  ARGV.shift
elsif ARGV.first == "--check"
  mode = :check
  ARGV.shift
end

version = ARGV.shift unless mode == :current
project_file = File.expand_path(ARGV.shift || DEFAULT_PROJECT_FILE)
fail "Unexpected arguments." unless ARGV.empty?
fail "Version is required and must use x.y or x.y.z format." unless mode == :current || version&.match?(VERSION_PATTERN)
fail "Project file was not found at #{project_file}." unless File.file?(project_file)

project = File.read(project_file)
target_ids = IOS_RELEASE_TARGETS.to_h do |target|
  [target, target_configuration_ids(project, target)]
end
selected_ids = target_ids.values.flatten
section_start, section_end, section = build_configuration_section(project)
values = configuration_values(section, selected_ids)

main_versions = target_ids.fetch(MAIN_APP_TARGET).map { |id| values.fetch(id).fetch(:marketing_version) }.uniq
fail "The main app build configurations have different versions: #{main_versions.join(', ')}." unless main_versions.one?
current_version = main_versions.first

if mode == :current
  puts current_version
  exit 0
end

if mode == :check
  mismatches = values.each_with_object([]) do |(id, settings), result|
    unless settings.fetch(:marketing_version) == version && settings.fetch(:build_number) == "1"
      result << "#{id} (#{settings.fetch(:name)}): version #{settings.fetch(:marketing_version)}, " \
                "build #{settings.fetch(:build_number)}"
    end
  end
  fail "iOS release settings do not match version #{version}, build 1:\n#{mismatches.join("\n")}" unless mismatches.empty?

  puts "Verified iOS app and extension versions: #{version} (1)"
  exit 0
end

configuration_pattern = /(\t\t([0-9A-F]+) \/\* [^*]+ \*\/ = \{\n)(.*?)(\t\t\};)/m
updated_section = section.gsub(configuration_pattern) do
  opening = Regexp.last_match(1)
  id = Regexp.last_match(2)
  body = Regexp.last_match(3)
  closing = Regexp.last_match(4)

  if selected_ids.include?(id)
    body = body.gsub(/^([ \t]*MARKETING_VERSION = )[^;]+;$/) do
      "#{Regexp.last_match(1)}#{version};"
    end
    body = body.gsub(/^([ \t]*CURRENT_PROJECT_VERSION = )[^;]+;$/) do
      "#{Regexp.last_match(1)}1;"
    end
  end

  "#{opening}#{body}#{closing}"
end

updated_project = project[0...section_start] + updated_section + project[section_end..-1]
write_project(project_file, updated_project) unless updated_project == project

updated_values = configuration_values(updated_section, selected_ids)
mismatches = updated_values.reject do |_id, settings|
  settings.fetch(:marketing_version) == version && settings.fetch(:build_number) == "1"
end
fail "Unable to update every iOS release target." unless mismatches.empty?

puts "Updated iOS app and extension versions from #{current_version} to #{version} (build 1)."
