Dir[File.join(__dir__, "seeds", "*.rb")].sort.each { |f| load f }
