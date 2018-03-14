module DistllAppGenerator
  def self.update_podfile(directory, target)
    value = "\ntarget '#{target}' do\n" \
	         "\tall_pods\n"\
        "end\n"

    filename = File.join(directory, 'Podfile')

    File.open(filename, 'r+') { |file|
      unless file.grep(/#{target}/).any?
        file.write(value)
      end

    }
  end

  def self.install_pods
    `pod install`
  end
end