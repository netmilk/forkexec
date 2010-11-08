require "rubygems"
require "yaml"
require "timeout"

module ForkExec
  def self.timeout timeout
    raise "Tmpfs in /dev/shm does not exist! Create it..." if not File.exist?("/dev/shm")

    shm = "/dev/shm/forkexec" 

    Dir.mkdir(shm) if not File.exist?(shm)

    pid = fork do
      output = yield
      File.open(File.join("/dev/shm/forkexec",Process.pid.to_s),"w"){|f| f.write(output.to_yaml)}
      exit! 0
    end

    result = nil

    begin
      Timeout::timeout(timeout) do
        Process.waitpid pid
        result = YAML::load_file(File.join(shm,pid.to_s))
      end
    rescue Timeout::Error
      Process.kill(9, pid)
      Process.waitpid pid
      raise Timeout::Error, "PID #{pid} timeouted"
    end
    
    shm_file = File.join("/dev/shm/forkexec/",pid.to_s)
    File.delete(shm_file) if File.exist?(shm_file)
    
    return result
  end
end
