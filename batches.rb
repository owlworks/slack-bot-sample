require 'bundler'
Bundler.require

class SlackBatch
  attr_reader :logger
  ROOT_PATH = File.expand_path(File.dirname(__FILE__))
  CONFIG = Hashie::Mash.new YAML.load_file File.join(ROOT_PATH, '/config.yml')

  def initialize
    init_logger
  end

  def self.execute
    batch = new
    batch.logger.info "=== #{batch.name} Start"
    begin
      batch.execute
    rescue => e
      batch.logger.error [e.class, e.message, e.backtrace].join("\n")
    end
    batch.logger.info "=== #{batch.name} End"
  end

  def post_message(channel: nil, text: nil)
    @logger.info HTTP.post(CONFIG.slack.api_url.post_message, params: {
                             token: CONFIG.slack.token,
                             channel: channel,
                             text: text,
                             as_user: true
                           })
  end

  def name
    self.class.name
  end

  private

  def init_logger
    log_path = File.join(ROOT_PATH, '/log/')
    log_name = File.join(log_path, "#{name}.log")
    FileUtils.mkdir_p(log_path) unless FileTest.exist?(log_path)
    @logger = Logger.new(log_name, 3)
  end
end

class CatBatch < SlackBatch
  CATAPI_URL = "http://thecatapi.com/api/images/get?format=xml"

  def execute
    doc = Nokogiri::XML(open(CATAPI_URL).read)
    @logger.info doc
    img_url = doc.xpath("//url").text
    post_message(channel: CONFIG.catbatch.channel, text: img_url)
  end
end
