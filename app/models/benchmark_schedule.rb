require 'pathname'
require 'fileutils'
require 'erb'
class BenchmarkSchedule < ActiveRecord::Base
  belongs_to :benchmark_definition
  validates :benchmark_definition, presence: true
  # Very loose matching. Does no complete validation. Matches:
  # 1) MUST contain 4 whitespaces (separating the 5 columns which may contain arbitrary characters)
  # 2) MUST NOT start with '*' to avoid the mistake that a benchmark is run every minute!
  VALID_CRON_EXPRESSION_REGEX = /[^\*].*\s.+\s.+\s.+\s.+/
  # TODO: enable after testing
  # validates :cron_expression, format: { with: VALID_CRON_EXPRESSION_REGEX,
  #                                       message: "Cron expression MUST NOT start with '*' and
  #                                                 ~MUST contain 4 whitespaces separating the 5 columns." }
  after_create   :update_system_crontab_if_active
  before_destroy :update_system_crontab_if_active
  after_update :check_and_update_system_crontab_after_update

  def cron_expression_in_english
    Cron2English.parse(self.cron_expression).join(' ')
  end

  def self.actives
    BenchmarkSchedule.where("active = ?", true)
  end

  def self.update_system_crontab
    # TODO: Fetch from app config (=> string is safer than Pathname)
    template_path = "#{Rails.root}/lib/templates/erb/whenever_schedule.rb.erb"
    schedule_path = "#{Rails.root}/storage/development/benchmark_schedules/whenever_schedule.rb"

    schedule = generate_schedule_from_template(template_path)
    write_content_to_file(schedule, schedule_path)
    apply_schedule_to_system_crontab(schedule_path)
  end

  def self.generate_schedule_from_template(template_path)
    template = ERB.new File.read(template_path)
    template.result(binding)
  end

  def self.apply_schedule_to_system_crontab(schedule_path)
    %x(whenever --update-crontab -f "#{schedule_path}")
  end

  def self.clear_system_crontab(schedule_path)
    %x(whenever --clear-crontab -f "#{schedule_path}")
  end

  private

    def update_system_crontab_if_active
      BenchmarkSchedule.update_system_crontab if active?
    end

    def check_and_update_system_crontab_after_update
      if active_changed? || active && cron_expression_changed?
        BenchmarkSchedule.update_system_crontab
      end
    end

    def self.write_content_to_file(schedule, schedule_path)
      parent_dir = Pathname.new(schedule_path).parent
      FileUtils::mkdir_p(parent_dir)
      File.open(schedule_path, 'w') do |f|
        f.write(schedule)
      end
    end

end
