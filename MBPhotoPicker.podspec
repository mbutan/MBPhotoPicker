
Pod::Spec.new do |s|
s.name             = "MBPhotoPicker"
s.version          = "0.1.0"
s.summary          = "Easy and quick in implementation Photo Picker, based on Slack's picker."

s.description      = <<-DESC
MBPhotoPicker is a simple Photo Picker based on used by Slack.
DESC

s.homepage         = "https://github.com/mbutan/MBPhotoPicker"
s.license          = 'MIT'
s.author           = { "Marcin Butanowicz" => "m.butan@gmail.com" }
s.source           = { :git => "https://github.com/mbutan/MBPhotoPicker.git", :tag => s.version.to_s }

s.platform     = :ios, '8.0'
s.requires_arc = true

s.source_files = 'Pod/Classes/**/*'

s.resource_bundles = {
'MBPhotoPicker' => ['Pod/Localizations/*']
}
end
