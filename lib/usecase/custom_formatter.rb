class CustomFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, time, progname, msg)
    "[Level] #{severity} \n" +
    "[Time] #{time} \n" +
    "[Message] #{msg} \n\n"
  end
end