require 'sneakers'
require 'sneakers/runner'

task :environment

namespace :sneakers do
  class SneakersPidFileExists < StandardError
  end

  class SneakersWorkerError < StandardError
  end

  def sneakers_logger
    @sneakers_logger ||= Logger.new(STDOUT)
  end

  def sneakers_info(message)
    sneakers_logger.info("[Sneakers Rake] #{message}")
  end

  def pid_file
    Rails.root.join('tmp/pids/sneakers.pid')
  end

  def pid_file_exists?
    File.exists?(pid_file)
  end

  def sneakers_pid
    if pid_file_exists?
      pid_value = File.read(pid_file).strip
      if pid_value.present?
        pid_value.to_i
      end
    end
  end

  def process_running?(pid)
    begin
      if pid
        # Send a null signal to get the process status
        Process.kill(0, pid)
        true
      else
        false
      end
    rescue Errno::ESRCH
      false
    end
  end

  # Start and stop a worker to make sure it is functional
  def test_worker(worker_class)
    worker = worker_class.new
    begin
      Timeout::timeout(60) do
        worker.run
      end
      true
    rescue Timeout::Error
      raise SneakersWorkerError, "Timed out while testing #{worker_class}"
      false
    ensure
      worker.stop
    end
  end

  desc "Ensures that sneakers is running"
  task :ensure_running do
    sneakers_info "Ensuring sneakers is running"
    running = false
    if pid_file_exists?
      pid = sneakers_pid
      if process_running?(pid)
        running = true
      else
        timestamp = Time.now.strftime("%Y%m%d%H%M%S")
        broken_name = "#{pid_file}.#{timestamp}"
        File.rename(pid_file, broken_name)
        sneakers_info "PID file exists, but sneakers is not running. Moving broken PID file: #{broken_name}"
      end
    end
    if !running
      Rake::Task["sneakers:start"].invoke
    else
      sneakers_info "Sneakers already running"
    end
  end

  desc "Start sneakers workers as a background process"
  task :start do |t, args|
    sneakers_info "Starting sneakers in background"
    Process.fork do
      Rake::Task["sneakers:run"].invoke
    end
    sneakers_info "Started sneakers"
  end

  desc "Start the sneakers workers"
  task :run  => :environment do
    begin
      if pid_file_exists?
        raise SneakersPidFileExists, "Sneakers pid file already exists: #{pid_file}"
      end
      File.open(pid_file, 'w'){|f| f.puts Process.pid}
      begin
        workers = []
        worker_classes = [
          ApiWorker,
          ItemMetadataWorker,
        ]
        worker_classes.each do |worker_class|
          test_worker(worker_class)
          worker_class.number_of_workers.times do
            workers << worker_class
          end
        end

        runner = Sneakers::Runner.new(workers)

        runner.run
      ensure
        File.delete pid_file
      end
    rescue SystemExit
      # Ignore SystemExit errors
    rescue Interrupt
      # Ignore Interrupt errors
    rescue Exception => e
      NotifyError.call(exception: e)
      raise e
    end
  end

  desc "Stop the sneakers background process"
  task :stop do
    if pid = sneakers_pid
      stopped = false
      sneakers_info "Stopping sneakers..."
      if process_running?(pid)
        Process.kill("INT", pid)
        60.times do
          if process_running?(pid)
            sleep(1)
          else
            stopped = true
            break
          end
        end
      else
        stopped = true
      end
      if stopped
        sneakers_info "Stopped sneakers"
      else
        sneakers_info "INT sent to pid #{pid}, sneakers not stopped"
      end
    else
      sneakers_info "Sneakers not running"
    end
  end

  desc "Restart the sneakers background process"
  task :restart do
    sneakers_info "Restarting sneakers"
    Rake::Task["sneakers:stop"].invoke
    Rake::Task["sneakers:start"].invoke
  end
end
