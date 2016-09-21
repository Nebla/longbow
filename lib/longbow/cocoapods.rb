module Longbow
  def self.update_podfile(directory, target)
    value = "\ntarget '#{target}’ do\n" \
	         "\tall_pods\n"\
        "end\n"

    filename = File.join(directory, 'Podfile')

    File.open(filename, 'r+') { |file|
      puts file.grep(/#{target}/)
      file.write(value) if file.grep(/#{target}/) == nil
    }
  end

  def self.install_pods
    `pod install`
  end
end