# Ajoute au projet Xcode la Live Activity du minuteur de biberon :
# fichiers Swift du canal dans Runner, target `BottleTimerWidget` (Widget
# Extension) et son intégration dans l'app. Idempotent.
#
# Usage (depuis la racine du dépôt) : ruby ios/scripts/add_bottle_timer_widget.rb
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
WIDGET = 'BottleTimerWidget'.freeze
TEAM = 'D2K5A7DBDQ'.freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
abort 'Target Runner introuvable' unless runner
if project.targets.any? { |t| t.name == WIDGET }
  puts "#{WIDGET} existe déjà : rien à faire."
  exit
end

# --- Runner : canal Swift et textes des notifications ---
runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
bottle_group = runner_group.new_group('BottleTimer', 'BottleTimer')
attributes_ref = bottle_group.new_reference('BottleTimerAttributes.swift')
channel_ref = bottle_group.new_reference('BottleTimerChannel.swift')
runner_strings_ref = bottle_group.new_reference('Localizable.strings')
runner.add_file_references([attributes_ref, channel_ref])
runner.add_resources([runner_strings_ref])

# --- Target de l'extension ---
widget = project.new_target(:app_extension, WIDGET, :ios, '16.2')
widget_group = project.main_group.new_group(WIDGET, WIDGET)
sources = %w[BottleTimerWidgetBundle.swift BottleTimerLiveActivity.swift BottleTimerViews.swift]
          .map { |f| widget_group.new_reference(f) }
widget_group.new_reference('Info.plist')
assets_ref = widget_group.new_reference('Assets.xcassets')
widget_strings_ref = widget_group.new_reference('Localizable.strings')
widget.add_file_references(sources + [attributes_ref])
widget.add_resources([assets_ref, widget_strings_ref])
widget.add_system_frameworks(%w[WidgetKit SwiftUI])

generated_xcconfig = project.files.find { |f| f.path == 'Flutter/Generated.xcconfig' }
widget.build_configurations.each do |config|
  # Versions de l'app (FLUTTER_BUILD_NAME / NUMBER) sans les Pods de Runner.
  config.base_configuration_reference = generated_xcconfig
  config.build_settings.merge!(
    'PRODUCT_BUNDLE_IDENTIFIER' => 'fr.montet.colette.BottleTimerWidget',
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'INFOPLIST_FILE' => "#{WIDGET}/Info.plist",
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'DEVELOPMENT_TEAM' => TEAM,
    'CODE_SIGN_STYLE' => 'Automatic',
    'IPHONEOS_DEPLOYMENT_TARGET' => '16.2',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'SWIFT_VERSION' => '5.0',
    'SKIP_INSTALL' => 'YES',
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => '',
    'LD_RUNPATH_SEARCH_PATHS' => [
      '$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'
    ]
  )
end

# --- Intégration dans Runner ---
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference).settings =
  { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# Avant « Thin Binary », sinon Xcode signale un cycle de build.
runner.build_phases.delete(embed)
thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
runner.build_phases.insert(thin || runner.build_phases.size, embed)

project.save
puts "#{WIDGET} ajoutée."
