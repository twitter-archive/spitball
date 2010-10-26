class Spitball::BundlerUI
  def initialize
    STDOUT.sync = true
  end

  def warn(message)
    puts "WARN: #{message}"
  end

  def error(message)
    puts "ERROR: #{message}"
  end

  def info(message)
    puts message
  end

  def confirm(message)
    puts "CONFIRM: #{message}"
  end
end